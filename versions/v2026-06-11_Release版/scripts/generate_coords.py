import json, sqlite3, os, sys

# Country centroids (major countries)
COUNTRY_CENTROIDS = {
    'China': (35.86, 104.19), 'United States': (37.09, -95.71), 'India': (20.59, 78.96),
    'Brazil': (-14.24, -51.93), 'Russia': (61.52, 105.32), 'Japan': (36.20, 138.25),
    'Germany': (51.17, 10.45), 'United Kingdom': (55.38, -3.44), 'France': (46.23, 2.21),
    'Italy': (41.87, 12.57), 'Canada': (56.13, -106.35), 'Australia': (-25.27, 133.78),
    'South Korea': (35.91, 127.77), 'Spain': (40.46, -3.75), 'Mexico': (23.63, -102.55),
    'Indonesia': (-0.79, 113.92), 'Netherlands': (52.13, 5.29), 'Saudi Arabia': (23.89, 45.08),
    'Turkey': (38.96, 35.24), 'Switzerland': (46.82, 8.23), 'Poland': (51.92, 19.15),
    'Thailand': (15.87, 100.99), 'Sweden': (60.13, 18.64), 'Belgium': (50.50, 4.47),
    'Nigeria': (9.08, 8.68), 'Austria': (47.52, 14.55), 'Iran': (32.43, 53.69),
    'Norway': (60.47, 8.47), 'UAE': (23.42, 53.85), 'Israel': (31.05, 34.85),
    'South Africa': (-30.56, 22.94), 'Denmark': (56.26, 9.50), 'Singapore': (1.35, 103.82),
    'Malaysia': (4.21, 101.98), 'Vietnam': (14.06, 108.28), 'Egypt': (26.82, 30.80),
    'Greece': (39.07, 21.82), 'Portugal': (39.40, -8.22), 'Ireland': (53.14, -8.24),
    'Argentina': (-38.42, -63.62), 'Chile': (-35.68, -71.54), 'Colombia': (4.57, -74.30),
    'New Zealand': (-40.90, 174.89), 'Philippines': (12.88, 121.77), 'Pakistan': (30.38, 69.35),
    'Bangladesh': (23.68, 90.36), 'Finland': (61.92, 25.75), 'Czech Republic': (49.82, 15.47),
    'Romania': (45.94, 24.97), 'Hungary': (47.16, 19.50), 'Ukraine': (48.38, 31.17),
    'Kazakhstan': (48.02, 66.92), 'Algeria': (28.03, 1.66), 'Morocco': (31.79, -7.09),
    'Kenya': (-0.02, 37.91), 'Ghana': (7.95, -1.02), 'Ethiopia': (9.15, 40.49),
    'Tanzania': (-6.37, 34.89), 'Peru': (-9.19, -75.02), 'Venezuela': (6.42, -66.59),
    'Cuba': (21.52, -77.78), 'Taiwan': (23.70, 120.96),
    'Qatar': (25.35, 51.18), 'Kuwait': (29.31, 47.48), 'Oman': (21.51, 55.92),
    'Iraq': (33.22, 43.68), 'Syria': (34.80, 39.00), 'Jordan': (30.59, 36.24),
    'Lebanon': (33.85, 35.86), 'Cyprus': (35.13, 33.43), 'Bahrain': (26.07, 50.56),
    'Mongolia': (46.86, 103.85), 'Myanmar': (21.92, 95.96), 'Cambodia': (12.57, 104.99),
    'Laos': (19.86, 102.50), 'Brunei': (4.54, 114.73), 'Sri Lanka': (7.87, 80.77),
    'Nepal': (28.39, 84.12), 'Bhutan': (27.51, 90.43),
    'Kyrgyzstan': (41.20, 74.77), 'Tajikistan': (38.86, 71.28), 'Uzbekistan': (41.38, 64.59),
    'Turkmenistan': (38.97, 59.56), 'Azerbaijan': (40.14, 47.58), 'Georgia': (42.32, 43.36),
    'Armenia': (40.07, 45.04), 'Belarus': (53.71, 27.95), 'Moldova': (47.41, 28.37),
    'Lithuania': (55.17, 23.88), 'Latvia': (56.88, 24.60), 'Estonia': (58.60, 25.01),
    'Croatia': (45.10, 15.20), 'Slovenia': (46.15, 14.99),
    'Serbia': (44.02, 21.01), 'Montenegro': (42.71, 19.37),
    'Albania': (41.15, 20.17), 'Bulgaria': (42.73, 25.49), 'Slovakia': (48.67, 19.70),
    'Luxembourg': (49.82, 6.13), 'Malta': (35.94, 14.38), 'Iceland': (64.96, -19.02),
    'Tunisia': (33.89, 9.54), 'Libya': (26.34, 17.27), 'Sudan': (12.86, 30.22),
    'Chad': (15.45, 18.73), 'Niger': (17.61, 8.08),
    'Mali': (17.57, -4.00), 'Mauritania': (21.01, -10.94), 'Senegal': (14.50, -14.45),
    'Guinea': (9.95, -9.70), 'Cameroon': (7.37, 12.35), 'Gabon': (-0.80, 11.61),
    'Congo': (-0.23, 15.83), 'Angola': (-11.20, 17.87),
    'Zambia': (-13.13, 27.85), 'Zimbabwe': (-19.02, 29.15),
    'Mozambique': (-18.67, 35.53), 'Madagascar': (-18.77, 46.87),
    'Namibia': (-22.96, 18.49), 'Uganda': (1.37, 32.29),
    'Somalia': (5.15, 46.20), 'Eritrea': (15.18, 39.78),
    'Fiji': (-17.71, 178.07), 'Papua New Guinea': (-6.31, 143.96),
    'Suriname': (3.92, -56.03), 'Guyana': (4.86, -58.93),
    'Paraguay': (-23.44, -58.44), 'Uruguay': (-32.52, -55.77),
    'Ecuador': (-1.83, -78.18), 'Bolivia': (-16.29, -63.59),
    'Costa Rica': (9.75, -83.75), 'Panama': (8.54, -80.78),
    'Nicaragua': (12.87, -85.21), 'Honduras': (15.20, -86.24),
    'Guatemala': (15.78, -90.23),
    'Dominican Republic': (18.74, -70.16), 'Jamaica': (18.11, -77.30),
    'Afghanistan': (33.94, 67.71), 'Yemen': (15.55, 48.52),
    'North Korea': (40.34, 127.51),
    # China provinces
    'Beijing': (39.90, 116.41), 'Shanghai': (31.23, 121.47),
    'Guangdong': (23.13, 113.26), 'Zhejiang': (30.27, 120.15),
    'Jiangsu': (32.06, 118.80), 'Sichuan': (30.57, 104.07),
    'Hubei': (30.59, 114.31), 'Shandong': (36.33, 118.18),
    'Fujian': (26.08, 119.30), 'Hunan': (28.11, 112.98),
    'Hebei': (38.04, 114.47), 'Liaoning': (41.81, 123.43),
    'Yunnan': (25.04, 102.71), 'Guizhou': (26.84, 106.91),
    'Shanxi': (37.57, 112.29), 'Jilin': (43.84, 126.55),
    'Heilongjiang': (47.36, 125.33), 'Hainan': (19.20, 109.73),
    'Xinjiang': (41.75, 86.10), 'Tibet': (31.70, 89.10),
    'Guangxi': (23.64, 108.32), 'Chongqing': (29.43, 106.91),
    'Tianjin': (39.14, 117.18), 'Hong Kong': (22.32, 114.17),
}

DB_PATH = sys.argv[1] if len(sys.argv) > 1 else r'D:\VitoのC盘避难计划\06 科研科创\SRT\infiltration_app\assets\infiltration.db'
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute('SELECT region_id, country, region_name FROM regions ORDER BY country, region_name')
rows = cur.fetchall()

centroids = {}
matched_country = 0
matched_province = 0
for rid, country, region in rows:
    if region in COUNTRY_CENTROIDS:
        lat, lon = COUNTRY_CENTROIDS[region]
        matched_province += 1
    elif country in COUNTRY_CENTROIDS:
        lat, lon = COUNTRY_CENTROIDS[country]
        matched_country += 1
    else:
        lat, lon = 0.0, 0.0

    centroids[str(rid)] = {'lat': lat, 'lon': lon, 'country': country, 'region': region}

out_path = os.path.join(ASSETS_DIR, 'region_coords.json')
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(centroids, f, ensure_ascii=False)

print(f'Generated coords for {len(centroids)} regions')
print(f'  Province exact matches: {matched_province}')
print(f'  Country fallback matches: {matched_country}')
print(f'  No match (0,0): {len(centroids) - matched_province - matched_country}')
print(f'File: {out_path} ({os.path.getsize(out_path)/1024:.1f} KB)')
conn.close()
