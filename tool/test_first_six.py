import sys
import re
import sqlite3
from test_semantic_situations import EXTENDED_SEMANTIC_SITUATIONS, normalize_text

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

conn = sqlite3.connect(":memory:")
c = conn.cursor()
c.executescript("""
    CREATE VIRTUAL TABLE quran_semantic_fts USING fts4(
        topic_id, surah_id, ayah_number, title, note, keywords, tokenize=unicode61
    );
""")

rows = []
for idx, item in enumerate(EXTENDED_SEMANTIC_SITUATIONS, 1):
    for surah_id, ayah_num, note in item["ayahs"]:
        rows.append((str(idx), str(surah_id), str(ayah_num), item["topic"], note, normalize_text(item["keywords"])))
        
c.executemany("INSERT INTO quran_semantic_fts VALUES (?, ?, ?, ?, ?, ?)", rows)

first_queries = [
    "мне грустно и тяжело",
    "что делать если нарушил обещание",
    "отношения мужа и жены, любовь в семье",
    "деньги в долг",
    "уважение к родителям",
    "как покаяться если согрешил"
]
STOP_WORDS = {"мне", "и", "в", "что", "делать", "если", "как", "к", "на", "с", "почему", "нельзя"}

for q in first_queries:
    clean_q = normalize_text(q)
    words = [w for w in re.findall(r"[\w]+", clean_q) if w not in STOP_WORDS and len(w) >= 3]
    terms = [f"{w[:5]}*" if len(w) > 5 else f"{w}*" for w in words]
    match_query = " OR ".join(terms)
    
    all_matches = c.execute("SELECT surah_id, ayah_number, title, note, keywords FROM quran_semantic_fts WHERE quran_semantic_fts MATCH ?", (match_query,)).fetchall()
    scored = []
    for surah_id, ayah_number, title, note, keywords in all_matches:
        target_text = normalize_text(f"{title} {keywords} {note}")
        score = 0
        for w in words:
            stem = w[:4] if len(w) >= 4 else w
            if stem in target_text:
                score += 2 if w in target_text else 1
        scored.append((score, surah_id, ayah_number, title, note))
    scored.sort(key=lambda x: x[0], reverse=True)
    
    print(f"\n🔍 ЗАПРОС: «{q}»")
    for score, s, a, t, note in scored[:3]:
        print(f"  ✅ [{score}★] {s}:{a} ({t}) -> «{note}»")
