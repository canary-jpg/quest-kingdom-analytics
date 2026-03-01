import duckdb

conn = duckdb.connect('quest_kingdom_dbt/quest_kingdom.db')
conn.execute("DROP TABLE IF EXISTS sessions")
conn.execute("DROP TABLE IF EXISTS events")
conn.execute("CREATE TABLE sessions AS SELECT * FROM read_csv_auto('data/sessions_fixed.csv')")
conn.execute("CREATE TABLE events AS SELECT * FROM read_csv_auto('data/events_fixed.csv')")
conn.close()