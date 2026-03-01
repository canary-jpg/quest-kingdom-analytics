import duckdb

#connect to duckdb
conn = duckdb.connect('quest_kingdom_dbt/quest_kingdom.db')
print("Loading CSV data into DuckDB...")

#load all CSV files as tables
tables = {
    'players': 'data/players.csv',
    'sessions': 'data/sessions_fixed.csv',
    'events': 'data/events_fixed.csv',
    'iap_transactions': 'data/iap_transactions.csv',
    'ad_impressions': 'data/ad_impressions.csv'
}

for table_name, csv_file in tables.items():
    print(f"Loading {table_name}...")
    conn.execute(f"""
        CREATE TABLE {table_name} AS 
        SELECT * FROM read_csv_auto('{csv_file}')
     """)

     #check row count
    result = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()
    print(f"{table_name}: {result[0]:,} rows")
    
print("\nAll data loaded!")
conn.close()