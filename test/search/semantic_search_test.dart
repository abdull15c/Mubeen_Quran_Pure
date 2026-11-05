import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/search/semantic_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipped semantic index retrieves representative situations', () async {
    final SemanticSearch search = AssetSemanticSearch(
      assetBundle: _FileSemanticBundle(),
    );
    final Map<String, Set<int>> cases = <String, Set<int>>{
      'мне грустно и тяжело': <int>{6095, 6096, 1735},
      'что делать если нарушил обещание': <int>{758, 2063, 1992},
      'отношения мужа и жены любовь в семье': <int>{3430, 512, 194},
      'деньги в долг': <int>{289, 287, 282},
      'уважение к родителям': <int>{2052, 2053, 3483},
    };

    for (final MapEntry<String, Set<int>> testCase in cases.entries) {
      final List<SemanticHit> hits = await search.search(
        testCase.key,
        limit: 10,
      );
      expect(
        hits.any((SemanticHit hit) => testCase.value.contains(hit.ayahId)),
        isTrue,
        reason: testCase.key,
      );
    }
    await search.close();
  });

  test(
    'semantic search rejects a corrupt index and can close safely',
    () async {
      final SemanticSearch search = AssetSemanticSearch(
        assetBundle: _CorruptSemanticBundle(),
      );

      await expectLater(search.search('тяжело на душе'), throwsFormatException);
      await search.close();
      expect(await search.search('тяжело на душе'), isEmpty);
    },
  );
}

final class _FileSemanticBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

final class _CorruptSemanticBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.json')) {
      return ByteData.sublistView(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, Object>{
              'format_version': 1,
              'dimension': 100,
              'vocabulary_size': 10000,
              'ayah_count': 6236,
              'cosine_threshold': 0.36,
              'topic_cosine_threshold': 0.48,
              'model_sha256': '',
              'token_embeddings_sha256': '',
              'index_sha256': '',
              'topic_index_sha256': '',
            }),
          ),
        ),
      );
    }
    return ByteData.sublistView(Uint8List(8));
  }
}
