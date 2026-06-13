// 批量精确化全球子地区坐标 - Open-Meteo API
// 运行: node scripts/geocode_regions.js
const fs = require('fs');
const https = require('https');

const regions = JSON.parse(fs.readFileSync('assets/regions.json', 'utf8'));
const currentCoords = JSON.parse(fs.readFileSync('assets/region_coords.json', 'utf8'));

// 国家名 → ISO代码映射（用于验证）
const countryToCode = {};
const idMap = {};
const toGeocode = [];

for (const c of regions.countries) {
  for (const r of c.regions) {
    idMap[r.id] = { name: r.name, country: c.country };
    if (r.name !== c.country) { // 只精确化子地区
      toGeocode.push({ id: r.id, name: r.name, country: c.country });
    }
  }
}

// 已完成的（中美精确坐标跳过）
const skipNames = new Set(Object.keys(require('./fix_coords_v2.js').chinaProvinces || {}));
// 简化：只跳过中国和美国的（已有精确坐标）
const chinaUsRegions = new Set();
for (const c of regions.countries) {
  if (c.country === 'China' || c.country === 'United States') {
    for (const r of c.regions) chinaUsRegions.add(r.id);
  }
}

const filtered = toGeocode.filter(r => !chinaUsRegions.has(r.id));
console.log(`待处理: ${filtered.length} 个子地区 (已跳过中美 ${toGeocode.length - filtered.length} 个)`);

function geocode(query) {
  return new Promise((resolve) => {
    const url = 'https://geocoding-api.open-meteo.com/v1/search?name='
      + encodeURIComponent(query) + '&count=1&language=en';
    https.get(url, { headers: { 'User-Agent': 'InfiltrationApp/1.0' }, timeout: 8000 }, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const r = JSON.parse(data);
          if (r.results && r.results.length > 0) {
            resolve({ lat: r.results[0].latitude, lon: r.results[0].longitude,
              cc: r.results[0].country_code, name: r.results[0].name });
          } else resolve(null);
        } catch(e) { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

// 国家名→ISO粗略验证（只检查大洲级别是否合理）
const countryLatRanges = {
  'Russia': [41,82], 'Canada': [42,83], 'Australia': [-44,-10], 'Brazil': [-34,5],
  'India': [6,36], 'Argentina': [-56,-21], 'Mexico': [14,33], 'Indonesia': [-11,6],
  'Japan': [26,46], 'Germany': [47,55], 'France': [41,51], 'UK': [50,60],
  'Italy': [35,48], 'Spain': [35,44], 'Thailand': [5,21], 'Vietnam': [8,23],
  'Philippines': [5,19], 'Turkey': [35,42], 'Iran': [25,40], 'Egypt': [22,32],
  'Nigeria': [4,14], 'South Africa': [-35,-22], 'Kenya': [-5,6], 'Colombia': [-5,13],
  'Peru': [-19,0], 'Chile': [-56,-17], 'Venezuela': [0,13], 'Malaysia': [0,8],
  'South Korea': [33,39], 'North Korea': [37,43], 'Poland': [49,55], 'Ukraine': [44,53],
  'Romania': [43,49], 'Sweden': [55,69], 'Norway': [57,72], 'Finland': [59,71],
};

function validateCountry(lat, country) {
  const range = countryLatRanges[country];
  if (!range) return true; // 无法验证，信任API
  return lat >= range[0] - 5 && lat <= range[1] + 5;
}

// 加载已有进度
let progressFile = 'scripts/geocode_progress.json';
let successes = {};
if (fs.existsSync(progressFile)) {
  successes = JSON.parse(fs.readFileSync(progressFile, 'utf8'));
  console.log(`已加载 ${Object.keys(successes).length} 条进度`);
}

let done = Object.keys(successes).length;
let ok = 0, fail = 0;

async function run() {
  for (let i = 0; i < filtered.length; i++) {
    const r = filtered[i];
    if (successes[r.id]) { done++; continue; }

    const query = r.name + ', ' + r.country;
    const result = await geocode(query);

    if (result && validateCountry(result.lat, r.country)) {
      successes[r.id] = { lat: result.lat, lon: result.lon };
      ok++;
    } else {
      fail++;
    }

    done++;
    if (done % 50 === 0) {
      process.stdout.write(`\r进度: ${done}/${filtered.length}  OK:${ok}  FAIL:${fail}`);
      // 每50条存一次
      fs.writeFileSync(progressFile, JSON.stringify(successes, null, 2));
    }
    await new Promise(r => setTimeout(r, 150)); // ~6 req/s
  }

  fs.writeFileSync(progressFile, JSON.stringify(successes, null, 2));
  console.log(`\n\n完成! OK:${ok} FAIL:${fail}`);
  console.log(`进度已保存到 ${progressFile}`);

  // 应用结果到 region_coords.json
  let applied = 0;
  for (const [idStr, coord] of Object.entries(successes)) {
    currentCoords[idStr] = coord;
    applied++;
  }
  fs.writeFileSync('assets/region_coords.json', JSON.stringify(currentCoords, null, 2));
  console.log(`已应用 ${applied} 条到 region_coords.json`);
}
run();
