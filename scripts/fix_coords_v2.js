// fix_coords_v2.js - 精确坐标修复
// 策略：中美用真实省/州坐标，其余国家用质心 + 微抖动 (±0.08°)
const fs = require('fs');

const coordsOrig = JSON.parse(fs.readFileSync('assets/region_coords_backup.json', 'utf8'));
const regions = JSON.parse(fs.readFileSync('assets/regions.json', 'utf8'));

// 中国 31 省市区真实坐标
const chinaProvinces = {
  'Anhui': [31.86, 117.28], 'Beijing': [39.90, 116.40], 'Chongqing': [29.56, 106.55],
  'Fujian': [26.08, 119.30], 'Gansu': [36.06, 103.83], 'Guangdong': [23.13, 113.27],
  'Guangxi': [22.82, 108.37], 'Guizhou': [26.60, 106.71], 'Hainan': [20.02, 110.35],
  'Hebei': [38.04, 114.47], 'Heilongjiang': [47.86, 127.76], 'Henan': [33.88, 113.61],
  'Hubei': [30.59, 114.30], 'Hunan': [28.11, 112.98], 'Inner Mongolia': [44.09, 113.87],
  'Jiangsu': [32.06, 118.80], 'Jiangxi': [28.68, 115.91], 'Jilin': [43.90, 125.32],
  'Liaoning': [41.80, 123.43], 'Ningxia': [38.47, 106.27], 'Qinghai': [36.62, 101.78],
  'Shaanxi': [34.26, 108.94], 'Shandong': [36.67, 116.98], 'Shanghai': [31.23, 121.47],
  'Shanxi': [37.87, 112.55], 'Sichuan': [30.65, 104.08], 'Tianjin': [39.12, 117.19],
  'Tibet': [31.69, 88.88], 'Xinjiang': [41.78, 86.13], 'Yunnan': [25.04, 102.71],
  'Zhejiang': [29.18, 120.09],
};

// 美国 50 州 + DC 真实坐标
const usStates = {
  'Alabama': [32.78, -86.83], 'Alaska': [64.07, -152.28], 'Arizona': [34.27, -111.66],
  'Arkansas': [34.89, -92.44], 'California': [36.12, -119.68], 'Colorado': [39.00, -105.55],
  'Connecticut': [41.60, -72.70], 'Delaware': [39.15, -75.50], 'District of Columbia': [38.91, -77.02],
  'Florida': [28.63, -82.45], 'Georgia': [32.64, -83.44], 'Hawaii': [20.29, -156.37],
  'Idaho': [44.35, -114.61], 'Illinois': [40.04, -89.20], 'Indiana': [39.89, -86.28],
  'Iowa': [42.07, -93.50], 'Kansas': [38.49, -98.38], 'Kentucky': [37.53, -85.30],
  'Louisiana': [31.07, -91.99], 'Maine': [45.37, -69.24], 'Maryland': [39.06, -76.79],
  'Massachusetts': [42.26, -71.80], 'Michigan': [44.35, -85.41], 'Minnesota': [46.28, -94.30],
  'Mississippi': [32.74, -89.68], 'Missouri': [38.46, -92.37], 'Montana': [47.05, -109.63],
  'Nebraska': [41.54, -99.79], 'Nevada': [39.33, -116.63], 'New Hampshire': [43.68, -71.58],
  'New Jersey': [40.19, -74.67], 'New Mexico': [34.41, -106.11], 'New York': [42.95, -75.53],
  'North Carolina': [35.56, -79.39], 'North Dakota': [47.45, -100.47], 'Ohio': [40.39, -82.76],
  'Oklahoma': [35.59, -97.49], 'Oregon': [43.93, -120.56], 'Pennsylvania': [40.88, -77.73],
  'Rhode Island': [41.68, -71.56], 'South Carolina': [33.92, -80.90], 'South Dakota': [44.44, -100.23],
  'Tennessee': [35.86, -86.35], 'Texas': [31.05, -97.56], 'Utah': [39.31, -111.67],
  'Vermont': [44.07, -72.67], 'Virginia': [37.52, -78.85], 'Washington': [47.40, -120.53],
  'West Virginia': [38.64, -80.62], 'Wisconsin': [44.62, -89.99], 'Wyoming': [42.99, -107.55],
};

// Build id -> {name, country} and country -> [ids]
const idMap = {};
const countryIds = {};
for (const c of regions.countries) {
  if (!countryIds[c.country]) countryIds[c.country] = [];
  for (const r of c.regions) {
    idMap[r.id] = { name: r.name, country: c.country };
    countryIds[c.country].push(r.id);
  }
}

// Get original country centroids from backup
const countryCentroids = {};
for (const [idStr, coord] of Object.entries(coordsOrig)) {
  const info = idMap[parseInt(idStr)];
  if (!info) continue;
  if (!countryCentroids[info.country]) {
    countryCentroids[info.country] = { lat: coord.lat, lon: coord.lon };
  }
}

const newCoords = {};
const seededRandom = (seed) => {
  let s = seed;
  return () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; };
};

let exactCount = 0, jitterCount = 0;

for (const c of regions.countries) {
  const country = c.country;
  const centroid = countryCentroids[country] || { lat: 0, lon: 0 };
  let seed = 0;
  for (let i = 0; i < country.length; i++) seed += country.charCodeAt(i);
  const rand = seededRandom(seed);

  for (const r of c.regions) {
    // Check for exact match in China or US
    const cnCoord = chinaProvinces[r.name];
    const usCoord = usStates[r.name];

    if (cnCoord) {
      newCoords[r.id] = { lat: cnCoord[0], lon: cnCoord[1] };
      exactCount++;
    } else if (usCoord) {
      newCoords[r.id] = { lat: usCoord[0], lon: usCoord[1] };
      exactCount++;
    } else if (r.name === country) {
      // Country-level: use centroid
      newCoords[r.id] = { lat: +(centroid.lat).toFixed(4), lon: +(centroid.lon).toFixed(4) };
    } else {
      // Sub-region: centroid + tiny jitter
      const jLat = (rand() - 0.5) * 0.16;
      const jLon = (rand() - 0.5) * 0.16;
      newCoords[r.id] = {
        lat: +(centroid.lat + jLat).toFixed(4),
        lon: +(centroid.lon + jLon).toFixed(4),
      };
      jitterCount++;
    }
  }
}

// Verify no zero coords
for (const [id, coord] of Object.entries(newCoords)) {
  if (coord.lat === 0 && coord.lon === 0) {
    const info = idMap[parseInt(id)];
    console.log('WARNING: ' + info.name + ' / ' + info.country + ' still at (0,0)');
  }
}

fs.writeFileSync('assets/region_coords.json', JSON.stringify(newCoords, null, 2));

// Stats
const unique = new Set(Object.values(newCoords).map(v => v.lat.toFixed(4)+','+v.lon.toFixed(4)));
console.log('总地区:', Object.keys(newCoords).length);
console.log('精确坐标 (中美):', exactCount);
console.log('抖动坐标:', jitterCount);
console.log('唯一坐标:', unique.size);

// Verify China
console.log('\n中国省市验证:');
const chinaIds = countryIds['China'] || [];
['Fujian', 'Beijing', 'Guangdong', 'Shanghai'].forEach(name => {
  const id = chinaIds.find(id => idMap[id]?.name === name);
  if (id) console.log('  ' + name + ': ' + newCoords[id].lat + ', ' + newCoords[id].lon);
});
