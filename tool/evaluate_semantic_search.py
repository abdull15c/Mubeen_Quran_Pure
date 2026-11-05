#!/usr/bin/env python3
"""Evaluate shipped FTS, vector, and hybrid search on held-out Russian queries."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import math
import re
import sqlite3
import struct
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

import numpy as np
import sentencepiece as spm

sys.path.insert(0, str(Path(__file__).resolve().parent))
from semantic_benchmark import NEGATIVE_CASES, POSITIVE_CASES  # noqa: E402
from build_quran_db import THEMATIC_TOPICS_DATA  # noqa: E402
from test_semantic_situations import EXTENDED_SEMANTIC_SITUATIONS  # noqa: E402


STOPWORDS = {"в", "и", "к", "с", "у", "о", "а", "на", "по", "за", "из", "от", "до"}
ARABIC_MARKS = re.compile(r"[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed\u08d3-\u08ff]")
REPLACEMENTS = str.maketrans({
    "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ى": "ي", "ؤ": "و",
    "ئ": "ي", "ـ": "", "ё": "е", "Ё": "е",
})


def normalize_lexical(value: str) -> str:
    value = ARABIC_MARKS.sub("", value.replace("\u0670", "ا")).translate(REPLACEMENTS)
    return " ".join(value.strip().split())


def fts_query(value: str) -> str | None:
    tokens: list[str] = []
    current: list[str] = []
    for character in value:
        if unicodedata.category(character)[0] in {"L", "M", "N"}:
            current.append(character)
        elif current:
            tokens.append("".join(current))
            current = []
    if current:
        tokens.append("".join(current))
    if len(tokens) > 1:
        filtered = [token for token in tokens if token.lower() not in STOPWORDS]
        if filtered:
            tokens = filtered
    return " OR ".join(f"{token}*" for token in tokens) if tokens else None


def load_assets(root: Path):
    search = root / "assets/search"
    manifest = json.loads((search / "semantic_manifest.json").read_text("utf-8"))
    files = {
        "model_sha256": search / "bpemb_ru_10000.model",
        "token_embeddings_sha256": search / "bpemb_ru_10000_d100.i8",
        "index_sha256": search / "ayah_embeddings.i8",
        "topic_index_sha256": search / "topic_embeddings.i8",
    }
    for key, path in files.items():
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != manifest[key]:
            raise RuntimeError(f"SHA-256 mismatch for {path}")

    vocabulary_size = manifest["vocabulary_size"]
    dimension = manifest["dimension"]
    token_data = files["token_embeddings_sha256"].read_bytes()
    scale_bytes = vocabulary_size * 4
    if len(token_data) != scale_bytes + vocabulary_size * dimension:
        raise RuntimeError("Unexpected token embedding size")
    token_scales = np.frombuffer(token_data, dtype="<f4", count=vocabulary_size).copy()
    token_vectors = np.frombuffer(token_data, dtype=np.int8, offset=scale_bytes).reshape(
        vocabulary_size, dimension
    ).copy()

    index_data = files["index_sha256"].read_bytes()
    magic, version, header_size, count, index_dimension, row_size = struct.unpack_from(
        "<8sHHIHH", index_data, 0
    )
    if (magic, version, header_size, count, index_dimension, row_size) != (
        b"MQSEM001", 1, 64, 6236, dimension, dimension + 8
    ):
        raise RuntimeError("Unexpected semantic index header")
    ayah_ids = np.empty(count, dtype=np.int32)
    inverse_norms = np.empty(count, dtype=np.float32)
    ayah_vectors = np.empty((count, dimension), dtype=np.int8)
    offset = header_size
    for row in range(count):
        ayah_ids[row], inverse_norms[row] = struct.unpack_from("<If", index_data, offset)
        ayah_vectors[row] = np.frombuffer(
            index_data, dtype=np.int8, count=dimension, offset=offset + 8
        )
        offset += row_size

    tokenizer = spm.SentencePieceProcessor(model_file=str(files["model_sha256"]))
    return manifest, tokenizer, token_scales, token_vectors, ayah_ids, inverse_norms, ayah_vectors


def embed_query(tokenizer, token_scales, token_vectors, query: str) -> np.ndarray | None:
    normalized = " ".join(re.sub(r"\d", "0", query.lower().replace("ё", "е")).split())
    token_ids = tokenizer.encode(normalized, out_type=int)
    if not token_ids:
        return None
    dimension = token_vectors.shape[1]
    result = np.zeros(dimension, dtype=np.float32)
    for token_id in token_ids:
        for component in range(dimension):
            result[component] = np.float32(
                float(result[component])
                + int(token_vectors[token_id, component]) * float(token_scales[token_id])
            )
    squared_norm = 0.0
    for component in range(dimension):
        result[component] = np.float32(float(result[component]) / len(token_ids))
        squared_norm += float(result[component]) * float(result[component])
    if squared_norm <= 0 or not math.isfinite(squared_norm):
        return None
    inverse_norm = 1 / math.sqrt(squared_norm)
    for component in range(dimension):
        result[component] = np.float32(float(result[component]) * inverse_norm)
    return result


def vector_search(assets, query: str, *, limit: int = 120):
    manifest, tokenizer, token_scales, token_vectors, ayah_ids, inverse_norms, vectors = assets
    if not re.search(r"[А-Яа-яЁё]", query):
        return []
    query_vector = embed_query(tokenizer, token_scales, token_vectors, query)
    if query_vector is None:
        return []
    scores = (vectors.astype(np.float32) @ query_vector) * inverse_norms
    matches = [
        (int(ayah_ids[index]), float(scores[index]))
        for index in range(len(ayah_ids))
        if float(scores[index]) >= manifest["cosine_threshold"]
    ]
    matches.sort(key=lambda item: (-item[1], item[0]))
    return matches[:limit]


def build_topic_prototypes(assets, references: dict[str, int]):
    prototypes = []
    for topic in THEMATIC_TOPICS_DATA:
        text = f"{topic['title']}. {topic['description']}. {topic['keywords']}"
        ayah_ids = [
            references[f"{surah}:{ayah}"]
            for surah, ayah, _ in topic["ayahs"]
            if f"{surah}:{ayah}" in references
        ]
        prototypes.append((topic["id"], embed_query(assets[1], assets[2], assets[3], text), ayah_ids))
    for index, topic in enumerate(EXTENDED_SEMANTIC_SITUATIONS):
        text = f"{topic['topic']}. {topic['keywords']}"
        ayah_ids = [
            references[f"{surah}:{ayah}"]
            for surah, ayah, _ in topic["ayahs"]
            if f"{surah}:{ayah}" in references
        ]
        prototypes.append((f"situation_{index}", embed_query(assets[1], assets[2], assets[3], text), ayah_ids))
    return prototypes


def topic_search(assets, prototypes, query: str, *, limit: int = 80):
    query_vector = embed_query(assets[1], assets[2], assets[3], query)
    if query_vector is None:
        return [], []
    ranked_topics = sorted(
        (
            (float(prototype @ query_vector), topic_id, ayah_ids)
            for topic_id, prototype, ayah_ids in prototypes
            if prototype is not None
        ),
        key=lambda item: (-item[0], item[1]),
    )
    results = []
    seen = set()
    for score, _, ayah_ids in ranked_topics[:5]:
        for index, ayah_id in enumerate(ayah_ids):
            if ayah_id not in seen:
                seen.add(ayah_id)
                results.append((ayah_id, score, index))
                if len(results) == limit:
                    return results, ranked_topics
    return results, ranked_topics


def improved_vector_search(assets, prototypes, query: str, *, limit: int = 120):
    dense = vector_search(assets, query, limit=limit)
    topics, _ = topic_search(assets, prototypes, query, limit=limit)
    scores = {ayah_id: score for ayah_id, score in dense}
    threshold = assets[0]["topic_cosine_threshold"]
    for ayah_id, topic_score, topic_rank in topics:
        if topic_score < threshold:
            continue
        boosted = topic_score + 0.08 / (topic_rank + 1)
        scores[ayah_id] = max(scores.get(ayah_id, float("-inf")), boosted)
    return [
        item for item in sorted(scores.items(), key=lambda item: (-item[1], item[0]))[:limit]
    ]


def lexical_search(database: sqlite3.Connection, query: str, *, limit: int = 160):
    match = fts_query(normalize_lexical(query))
    if match is None or not any(unicodedata.category(c).startswith("L") for c in query):
        return []
    rows = database.execute(
        """
        SELECT a.id
        FROM quran_search_fts
        INNER JOIN surahs AS s
          ON s.id = CAST(quran_search_fts.surah_id AS INTEGER)
        INNER JOIN ayahs AS a
          ON a.surah_id = s.id
         AND a.number_in_surah = CASE
           WHEN quran_search_fts.ayah_number IS NULL
             OR CAST(quran_search_fts.ayah_number AS INTEGER) < 1 THEN 1
           ELSE CAST(quran_search_fts.ayah_number AS INTEGER)
         END
        WHERE quran_search_fts MATCH ?
          AND (quran_search_fts.kind <> 'translation' OR quran_search_fts.source_key = 'kuliev')
        ORDER BY quran_search_fts.rowid ASC
        """,
        (match,),
    )
    results: list[int] = []
    seen: set[int] = set()
    for ayah_id, in rows:
        if ayah_id not in seen:
            seen.add(ayah_id)
            results.append(ayah_id)
            if len(results) == limit:
                break
    return results


def hybrid_search(database, assets, query: str, *, limit: int = 80, prototypes=None):
    lexical = lexical_search(database, query)
    semantic_hits = (
        improved_vector_search(assets, prototypes, query)
        if prototypes is not None
        else vector_search(assets, query)
    )
    semantic = [ayah_id for ayah_id, _ in semantic_hits]
    if not semantic:
        return lexical[:limit]
    scores: dict[int, float] = {}
    for index, ayah_id in enumerate(lexical):
        scores[ayah_id] = scores.get(ayah_id, 0) + 1 / (61 + index)
    for index, ayah_id in enumerate(semantic):
        scores[ayah_id] = scores.get(ayah_id, 0) + 0.85 / (61 + index)
    return [item[0] for item in sorted(scores.items(), key=lambda item: (-item[1], item[0]))[:limit]]


def topic_first_search(database, assets, prototypes, query: str, *, limit: int = 80):
    topics, _ = topic_search(assets, prototypes, query, limit=limit)
    topic_threshold = assets[0]["topic_cosine_threshold"]
    topic_ids = [ayah_id for ayah_id, score, _ in topics if score >= topic_threshold]
    dense_ids = [ayah_id for ayah_id, _ in vector_search(assets, query)]
    lexical_ids = lexical_search(database, query)
    results = []
    seen = set()
    for source in (topic_ids, dense_ids, lexical_ids):
        for ayah_id in source:
            if ayah_id not in seen:
                seen.add(ayah_id)
                results.append(ayah_id)
                if len(results) == limit:
                    return results
    return results


def rank_of(results: list[int], expected: set[int]) -> int | None:
    return next((index for index, ayah_id in enumerate(results, 1) if ayah_id in expected), None)


def summarize(ranks: list[int | None]) -> dict[str, float]:
    total = len(ranks)
    return {
        "R@1": sum(rank is not None and rank <= 1 for rank in ranks) / total,
        "R@3": sum(rank is not None and rank <= 3 for rank in ranks) / total,
        "R@5": sum(rank is not None and rank <= 5 for rank in ranks) / total,
        "R@10": sum(rank is not None and rank <= 10 for rank in ranks) / total,
        "MRR": sum(0 if rank is None else 1 / rank for rank in ranks) / total,
        "NoResult": sum(rank is None for rank in ranks) / total,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--failures", type=Path, default=Path("build/semantic_benchmark_failures.json"))
    args = parser.parse_args()
    root = args.root.resolve()
    assets = load_assets(root)
    database = sqlite3.connect(":memory:")
    database.deserialize(gzip.decompress((root / "assets/db/quran.db.gz").read_bytes()))
    references = {
        f"{surah}:{ayah}": ayah_id
        for ayah_id, surah, ayah in database.execute(
            "SELECT id, surah_id, number_in_surah FROM ayahs"
        )
    }
    prototypes = build_topic_prototypes(assets, references)

    ranks = {"fts": [], "vector": [], "topic": [], "hybrid": [], "improved": [], "topic_first": []}
    category_ranks: dict[str, list[int | None]] = defaultdict(list)
    failures = []
    for case in POSITIVE_CASES:
        expected = {references[reference] for reference in case["expected"] if reference in references}
        fts = lexical_search(database, case["query"])
        vector = [ayah_id for ayah_id, _ in vector_search(assets, case["query"])]
        topic = [ayah_id for ayah_id, _, _ in topic_search(assets, prototypes, case["query"])[0]]
        hybrid = hybrid_search(database, assets, case["query"])
        improved = hybrid_search(database, assets, case["query"], prototypes=prototypes)
        topic_first = topic_first_search(database, assets, prototypes, case["query"])
        case_ranks = {
            "fts": rank_of(fts, expected),
            "vector": rank_of(vector, expected),
            "topic": rank_of(topic, expected),
            "hybrid": rank_of(hybrid, expected),
            "improved": rank_of(improved, expected),
            "topic_first": rank_of(topic_first, expected),
        }
        for name, rank in case_ranks.items():
            ranks[name].append(rank)
        category_ranks[case["category"]].append(case_ranks["topic_first"])
        if case_ranks["topic_first"] is None or case_ranks["topic_first"] > 10:
            failures.append({
                **case,
                "ranks": case_ranks,
                "hybrid_top10": topic_first[:10],
            })

    negative_hits = []
    negative_topic_scores = []
    for query in NEGATIVE_CASES:
        semantic = vector_search(assets, query)
        _, ranked_topics = topic_search(assets, prototypes, query)
        negative_topic_scores.append(ranked_topics[0][0])
        hybrid = hybrid_search(database, assets, query, prototypes=prototypes)
        if hybrid:
            negative_hits.append({
                "query": query,
                "hybrid_count": len(hybrid),
                "top_cosine": semantic[0][1] if semantic else None,
                "top_ids": hybrid[:5],
            })

    print(f"Held-out positives: {len(POSITIVE_CASES)}; negatives: {len(NEGATIVE_CASES)}")
    for name in ("fts", "vector", "topic", "hybrid", "improved", "topic_first"):
        metrics = summarize(ranks[name])
        print(name.upper(), " ".join(f"{key}={value:.3f}" for key, value in metrics.items()))
    print(f"NEGATIVE_FPR={len(negative_hits) / len(NEGATIVE_CASES):.3f} ({len(negative_hits)}/{len(NEGATIVE_CASES)})")
    print(
        "NEGATIVE_TOPIC_SCORE "
        f"min={min(negative_topic_scores):.3f} "
        f"mean={sum(negative_topic_scores) / len(negative_topic_scores):.3f} "
        f"max={max(negative_topic_scores):.3f}"
    )
    print("HYBRID R@10 by category:")
    for category, values in sorted(category_ranks.items()):
        print(f"  {category:12s} {summarize(values)['R@10']:.2f}")

    args.failures.parent.mkdir(parents=True, exist_ok=True)
    args.failures.write_text(
        json.dumps({"positive_failures": failures, "negative_hits": negative_hits}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Detailed failures: {args.failures}")
    database.close()


if __name__ == "__main__":
    main()
