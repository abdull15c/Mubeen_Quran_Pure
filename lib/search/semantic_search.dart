import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

const String _manifestAsset = 'assets/search/semantic_manifest.json';
const String _tokenizerAsset = 'assets/search/bpemb_ru_10000.model';
const String _tokenEmbeddingsAsset = 'assets/search/bpemb_ru_10000_d100.i8';
const String _ayahEmbeddingsAsset = 'assets/search/ayah_embeddings.i8';
const String _topicEmbeddingsAsset = 'assets/search/topic_embeddings.i8';

final class SemanticHit {
  const SemanticHit({required this.ayahId, required this.cosine});

  final int ayahId;
  final double cosine;
}

abstract interface class SemanticSearch {
  Future<List<SemanticHit>> search(String query, {int limit = 120});

  Future<void> close();
}

final class AssetSemanticSearch implements SemanticSearch {
  AssetSemanticSearch({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  Future<_SemanticIndex>? _loading;
  _SemanticIndex? _index;
  bool _closed = false;

  @override
  Future<List<SemanticHit>> search(String query, {int limit = 120}) async {
    if (_closed || query.trim().isEmpty || limit <= 0) {
      return const <SemanticHit>[];
    }
    final _SemanticIndex index = _index ?? await _loadOnce();
    if (_closed) return const <SemanticHit>[];
    return index.search(query, limit: limit);
  }

  Future<_SemanticIndex> _loadOnce() async {
    try {
      final _SemanticIndex index = await (_loading ??= _load());
      _index = index;
      return index;
    } on Object {
      _loading = null;
      rethrow;
    }
  }

  Future<_SemanticIndex> _load() async {
    final List<Object> assets = await Future.wait<Object>(<Future<Object>>[
      _assetBundle.loadString(_manifestAsset),
      _assetBundle.load(_tokenizerAsset),
      _assetBundle.load(_tokenEmbeddingsAsset),
      _assetBundle.load(_ayahEmbeddingsAsset),
      _assetBundle.load(_topicEmbeddingsAsset),
    ]);

    return Isolate.run(() {
      return _SemanticIndex.fromAssets(
        manifestJson: assets[0] as String,
        tokenizerBytes: _bytes(assets[1] as ByteData),
        tokenEmbeddingBytes: _bytes(assets[2] as ByteData),
        ayahEmbeddingBytes: _bytes(assets[3] as ByteData),
        topicEmbeddingBytes: _bytes(assets[4] as ByteData),
      );
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    _loading = null;
    _index = null;
  }
}

final class _SemanticIndex {
  _SemanticIndex({
    required this.tokenizer,
    required this.dimension,
    required this.vocabularySize,
    required this.threshold,
    required this.tokenScales,
    required this.tokenVectors,
    required this.ayahIds,
    required this.ayahInverseNorms,
    required this.ayahVectors,
    required this.topicVectors,
    required this.topicInverseNorms,
    required this.topicAyahIds,
    required this.topicThreshold,
  });

  factory _SemanticIndex.fromAssets({
    required String manifestJson,
    required Uint8List tokenizerBytes,
    required Uint8List tokenEmbeddingBytes,
    required Uint8List ayahEmbeddingBytes,
    required Uint8List topicEmbeddingBytes,
  }) {
    final Map<String, Object?> manifest =
        jsonDecode(manifestJson) as Map<String, Object?>;
    final int dimension = manifest['dimension']! as int;
    final int vocabularySize = manifest['vocabulary_size']! as int;
    final int expectedAyahCount = manifest['ayah_count']! as int;
    final double threshold = (manifest['cosine_threshold']! as num).toDouble();
    final double topicThreshold = (manifest['topic_cosine_threshold']! as num)
        .toDouble();
    if (manifest['format_version'] != 1 ||
        dimension <= 0 ||
        vocabularySize <= 0 ||
        expectedAyahCount != 6236 ||
        !threshold.isFinite) {
      throw const FormatException('Invalid semantic-search manifest.');
    }
    _verifySha256(
      tokenizerBytes,
      manifest['model_sha256'],
      'semantic tokenizer',
    );
    _verifySha256(
      tokenEmbeddingBytes,
      manifest['token_embeddings_sha256'],
      'token embeddings',
    );
    _verifySha256(
      ayahEmbeddingBytes,
      manifest['index_sha256'],
      'ayah embeddings',
    );
    _verifySha256(
      topicEmbeddingBytes,
      manifest['topic_index_sha256'],
      'topic embeddings',
    );

    final int scaleBytes = vocabularySize * Float32List.bytesPerElement;
    final int vectorBytes = vocabularySize * dimension;
    if (tokenEmbeddingBytes.lengthInBytes != scaleBytes + vectorBytes) {
      throw const FormatException('Invalid token embedding asset.');
    }
    final ByteData tokenData = ByteData.sublistView(tokenEmbeddingBytes);
    final Float32List tokenScales = Float32List(vocabularySize);
    for (var index = 0; index < vocabularySize; index++) {
      final double scale = tokenData.getFloat32(
        index * Float32List.bytesPerElement,
        Endian.little,
      );
      if (!scale.isFinite || scale <= 0) {
        throw const FormatException('Invalid token embedding scale.');
      }
      tokenScales[index] = scale;
    }
    final Int8List tokenVectors = Int8List.sublistView(
      tokenEmbeddingBytes,
      scaleBytes,
    );

    if (ayahEmbeddingBytes.lengthInBytes < 64) {
      throw const FormatException('Semantic index is truncated.');
    }
    final ByteData ayahData = ByteData.sublistView(ayahEmbeddingBytes);
    const List<int> magic = <int>[77, 81, 83, 69, 77, 48, 48, 49];
    for (var index = 0; index < magic.length; index++) {
      if (ayahEmbeddingBytes[index] != magic[index]) {
        throw const FormatException('Invalid semantic index magic.');
      }
    }
    final int version = ayahData.getUint16(8, Endian.little);
    final int headerSize = ayahData.getUint16(10, Endian.little);
    final int count = ayahData.getUint32(12, Endian.little);
    final int indexDimension = ayahData.getUint16(16, Endian.little);
    final int rowSize = ayahData.getUint16(18, Endian.little);
    if (version != 1 ||
        headerSize != 64 ||
        count != expectedAyahCount ||
        indexDimension != dimension ||
        rowSize != dimension + 8 ||
        ayahEmbeddingBytes.lengthInBytes != headerSize + count * rowSize) {
      throw const FormatException('Invalid semantic index header.');
    }

    final Uint32List ayahIds = Uint32List(count);
    final Float32List inverseNorms = Float32List(count);
    final Int8List ayahVectors = Int8List(count * dimension);
    final Set<int> seenIds = <int>{};
    var offset = headerSize;
    for (var index = 0; index < count; index++) {
      final int ayahId = ayahData.getUint32(offset, Endian.little);
      final double inverseNorm = ayahData.getFloat32(offset + 4, Endian.little);
      if (ayahId <= 0 || !seenIds.add(ayahId) || !inverseNorm.isFinite) {
        throw const FormatException('Invalid semantic index row.');
      }
      ayahIds[index] = ayahId;
      inverseNorms[index] = inverseNorm;
      ayahVectors.setRange(
        index * dimension,
        (index + 1) * dimension,
        Int8List.sublistView(ayahEmbeddingBytes, offset + 8, offset + rowSize),
      );
      offset += rowSize;
    }

    final ByteData topicData = ByteData.sublistView(topicEmbeddingBytes);
    const List<int> topicMagic = <int>[77, 81, 84, 79, 80, 48, 48, 49];
    if (topicEmbeddingBytes.lengthInBytes < 64) {
      throw const FormatException('Topic index is truncated.');
    }
    for (var index = 0; index < topicMagic.length; index++) {
      if (topicEmbeddingBytes[index] != topicMagic[index]) {
        throw const FormatException('Invalid topic index magic.');
      }
    }
    final int topicVersion = topicData.getUint16(8, Endian.little);
    final int topicHeaderSize = topicData.getUint16(10, Endian.little);
    final int topicCount = topicData.getUint32(12, Endian.little);
    final int topicDimension = topicData.getUint16(16, Endian.little);
    if (topicVersion != 1 ||
        topicHeaderSize != 64 ||
        topicCount <= 0 ||
        topicDimension != dimension ||
        !topicThreshold.isFinite) {
      throw const FormatException('Invalid topic index header.');
    }
    final Float32List topicInverseNorms = Float32List(topicCount);
    final Int8List topicVectors = Int8List(topicCount * dimension);
    final List<Uint32List> topicAyahIds = <Uint32List>[];
    offset = topicHeaderSize;
    for (var index = 0; index < topicCount; index++) {
      if (offset + 6 + dimension > topicEmbeddingBytes.lengthInBytes) {
        throw const FormatException('Topic index row is truncated.');
      }
      topicInverseNorms[index] = topicData.getFloat32(offset, Endian.little);
      final int ayahCount = topicData.getUint16(offset + 4, Endian.little);
      topicVectors.setRange(
        index * dimension,
        (index + 1) * dimension,
        Int8List.sublistView(
          topicEmbeddingBytes,
          offset + 6,
          offset + 6 + dimension,
        ),
      );
      offset += 6 + dimension;
      final Uint32List ids = Uint32List(ayahCount);
      for (var ayahIndex = 0; ayahIndex < ayahCount; ayahIndex++) {
        if (offset + 4 > topicEmbeddingBytes.lengthInBytes) {
          throw const FormatException('Topic ayah list is truncated.');
        }
        ids[ayahIndex] = topicData.getUint32(offset, Endian.little);
        offset += 4;
      }
      topicAyahIds.add(ids);
    }
    if (offset != topicEmbeddingBytes.lengthInBytes) {
      throw const FormatException('Topic index has trailing data.');
    }

    return _SemanticIndex(
      tokenizer: SentencePieceTokenizer.fromBytes(
        tokenizerBytes,
        config: const SentencePieceConfig(),
      ),
      dimension: dimension,
      vocabularySize: vocabularySize,
      threshold: threshold,
      tokenScales: tokenScales,
      tokenVectors: tokenVectors,
      ayahIds: ayahIds,
      ayahInverseNorms: inverseNorms,
      ayahVectors: ayahVectors,
      topicVectors: topicVectors,
      topicInverseNorms: topicInverseNorms,
      topicAyahIds: topicAyahIds,
      topicThreshold: topicThreshold,
    );
  }

  final SentencePieceTokenizer tokenizer;
  final int dimension;
  final int vocabularySize;
  final double threshold;
  final Float32List tokenScales;
  final Int8List tokenVectors;
  final Uint32List ayahIds;
  final Float32List ayahInverseNorms;
  final Int8List ayahVectors;
  final Int8List topicVectors;
  final Float32List topicInverseNorms;
  final List<Uint32List> topicAyahIds;
  final double topicThreshold;

  Future<List<SemanticHit>> search(String query, {required int limit}) async {
    final List<int> tokenIds = tokenizer
        .encode(_normalize(query), addSpecialTokens: false)
        .ids
        .where((int id) => id >= 0 && id < vocabularySize)
        .toList(growable: false);
    if (tokenIds.isEmpty) return const <SemanticHit>[];
    final Float32List queryVector = Float32List(dimension);
    for (final int tokenId in tokenIds) {
      final double scale = tokenScales[tokenId];
      final int vectorOffset = tokenId * dimension;
      for (var component = 0; component < dimension; component++) {
        queryVector[component] +=
            tokenVectors[vectorOffset + component] * scale;
      }
    }
    var squaredNorm = 0.0;
    for (var component = 0; component < dimension; component++) {
      queryVector[component] /= tokenIds.length;
      squaredNorm += queryVector[component] * queryVector[component];
    }
    if (squaredNorm <= 0 || !squaredNorm.isFinite) {
      return const <SemanticHit>[];
    }
    final double inverseQueryNorm = 1 / math.sqrt(squaredNorm);
    for (var component = 0; component < dimension; component++) {
      queryVector[component] *= inverseQueryNorm;
    }

    final List<List<double>> scored = await Isolate.run(
      () => _scanVectors(<Object>[
        queryVector,
        ayahIds,
        ayahInverseNorms,
        ayahVectors,
        dimension,
        threshold,
        limit,
      ]),
      debugName: 'quran-semantic-cosine',
    );
    final List<List<double>> topicScores = _scanVectors(<Object>[
      queryVector,
      Uint32List.fromList(
        List<int>.generate(topicAyahIds.length, (int index) => index + 1),
      ),
      topicInverseNorms,
      topicVectors,
      dimension,
      topicThreshold,
      3,
    ]);
    final List<SemanticHit> topicHits = <SemanticHit>[];
    final Set<int> topicAyahs = <int>{};
    for (final List<double> topic in topicScores) {
      final int topicIndex = topic[0].toInt() - 1;
      for (var rank = 0; rank < topicAyahIds[topicIndex].length; rank++) {
        final int ayahId = topicAyahIds[topicIndex][rank];
        if (topicAyahs.add(ayahId)) {
          topicHits.add(SemanticHit(ayahId: ayahId, cosine: topic[1]));
        }
      }
    }
    final List<SemanticHit> results = <SemanticHit>[...topicHits];
    for (final List<double> hit in scored) {
      final int ayahId = hit[0].toInt();
      if (topicAyahs.add(ayahId)) {
        results.add(SemanticHit(ayahId: ayahId, cosine: hit[1]));
      }
      if (results.length == limit) break;
    }
    return List<SemanticHit>.unmodifiable(results.take(limit));
  }
}

List<List<double>> _scanVectors(List<Object> input) {
  final Float32List queryVector = input[0] as Float32List;
  final Uint32List ayahIds = input[1] as Uint32List;
  final Float32List inverseNorms = input[2] as Float32List;
  final Int8List vectors = input[3] as Int8List;
  final int dimension = input[4] as int;
  final double threshold = input[5] as double;
  final int limit = input[6] as int;
  final List<List<double>> scored = <List<double>>[];
  for (var row = 0; row < ayahIds.length; row++) {
    var dotProduct = 0.0;
    final int rowOffset = row * dimension;
    for (var component = 0; component < dimension; component++) {
      dotProduct += queryVector[component] * vectors[rowOffset + component];
    }
    final double cosine = dotProduct * inverseNorms[row];
    if (cosine >= threshold) {
      scored.add(<double>[ayahIds[row].toDouble(), cosine]);
    }
  }
  scored.sort((List<double> left, List<double> right) {
    final int scoreOrder = right[1].compareTo(left[1]);
    return scoreOrder != 0 ? scoreOrder : left[0].compareTo(right[0]);
  });
  return scored.length <= limit ? scored : scored.sublist(0, limit);
}

Uint8List _bytes(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\d'), '0')
      .trim()
      .split(RegExp(r'\s+'))
      .join(' ');
}

void _verifySha256(Uint8List bytes, Object? expected, String name) {
  if (expected is! String || sha256.convert(bytes).toString() != expected) {
    throw FormatException('Invalid $name SHA-256.');
  }
}
