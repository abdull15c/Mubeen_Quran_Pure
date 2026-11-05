import sqlite3
import sys

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

conn = sqlite3.connect(":memory:")
c = conn.cursor()
c.execute("CREATE VIRTUAL TABLE test_fts USING fts4(text, tokenize=unicode61)")
c.execute("INSERT INTO test_fts(text) VALUES ('грустно грусть печаль тяжело на душе')")

print("1. 'грустно*':", c.execute("SELECT * FROM test_fts WHERE test_fts MATCH 'грустно*'").fetchall())
print("2. '\"грустно\"*':", c.execute("SELECT * FROM test_fts WHERE test_fts MATCH '\"грустно\"*'").fetchall())
print("3. 'груст*':", c.execute("SELECT * FROM test_fts WHERE test_fts MATCH 'груст*'").fetchall())
print("4. '\"груст\"*':", c.execute("SELECT * FROM test_fts WHERE test_fts MATCH '\"груст\"*'").fetchall())
