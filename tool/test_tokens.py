import gzip
import sqlite3
import tempfile
import os
import re
from pathlib import Path

RUSSIAN_STOPWORDS = {
    'в', 'во', 'и', 'к', 'ко', 'с', 'со', 'у', 'о', 'об', 'а', 'на', 'по', 'за', 'из', 'от', 'до',
    'мне', 'меня', 'мой', 'моя', 'мое', 'мои', 'нам', 'нас', 'наш', 'наша',
    'что', 'как', 'если', 'делать', 'почему', 'нельзя', 'для', 'же', 'бы', 'ли',
    'это', 'этот', 'эта', 'эти', 'то', 'тот', 'все', 'весь', 'вся', 'всё',
    'вы', 'вам', 'вас', 'ваш', 'мы', 'он', 'она', 'они', 'их', 'ему', 'ей', 'им',
    'себе', 'себя', 'свой', 'своя', 'где', 'куда', 'когда', 'кто', 'чем'
}

def normalize_for_search(text: str) -> str:
    # Normalize Arabic & Russian
    t = text.lower().replace('ё', 'е')
    t = re.sub(r'[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed\u08d3-\u08ff]', '', t)
    t = t.translate(str.maketrans({
        'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي', 'ـ': ''
    }))
    return t

def build_search_tokens(query: str) -> list[str]:
    normalized = normalize_for_search(query)
    raw_tokens = re.findall(r'[\w]+', normalized)
    filtered = [t for t in raw_tokens if t not in RUSSIAN_STOPWORDS and len(t) >= 2]
    if not filtered and raw_tokens:
        filtered = raw_tokens
    
    stems = []
    for t in filtered:
        # If Russian word length > 4, stem to first 5 chars for suffix flexibility
        # e.g. "грустно" -> "груст", "обещание" -> "обещан", "родителям" -> "родител"
        if re.match(r'^[а-я]+$', t):
            if len(t) >= 6:
                stems.append(f"{t[:5]}*")
            elif len(t) >= 4:
                stems.append(f"{t[:4]}*")
            else:
                stems.append(f"{t}*")
        else:
            stems.append(f"{t}*")
    return stems

def build_fts_query(query: str) -> str:
    tokens = build_search_tokens(query)
    if not tokens:
        return ""
    # Use OR to find all relevant candidate ayahs across situations and translations
    return " OR ".join(tokens)

print("Tokens for 'мне грустно и тяжело':", build_search_tokens("мне грустно и тяжело"))
print("FTS query:", build_fts_query("мне грустно и тяжело"))
print("Tokens for 'что делать если нарушил обещание':", build_search_tokens("что делать если нарушил обещание"))
print("FTS query:", build_fts_query("что делать если нарушил обещание"))
