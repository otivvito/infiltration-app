// 按国家真实地理范围重新分配子地区坐标
const fs = require('fs');

const coordsRaw = JSON.parse(fs.readFileSync('assets/region_coords.json', 'utf8'));
const regions = JSON.parse(fs.readFileSync('assets/regions.json', 'utf8'));

// 国家近似地理范围 (latMin, latMax, lonMin, lonMax) - 基于实际地理数据
const bounds = {"Russia":{"latMin":41,"latMax":82,"lonMin":19,"lonMax":169},"United States":{"latMin":24,"latMax":49,"lonMin":-125,"lonMax":-66},"China":{"latMin":18,"latMax":54,"lonMin":73,"lonMax":135},"Canada":{"latMin":42,"latMax":83,"lonMin":-141,"lonMax":-52},"Brazil":{"latMin":-34,"latMax":5,"lonMin":-74,"lonMax":-34},"Australia":{"latMin":-44,"latMax":-10,"lonMin":113,"lonMax":154},"India":{"latMin":6,"latMax":36,"lonMin":68,"lonMax":98},"Argentina":{"latMin":-56,"latMax":-21,"lonMin":-74,"lonMax":-53},"Kazakhstan":{"latMin":40,"latMax":56,"lonMin":46,"lonMax":88},"Algeria":{"latMin":18,"latMax":37,"lonMin":-9,"lonMax":12},"Indonesia":{"latMin":-11,"latMax":6,"lonMin":95,"lonMax":141},"Mexico":{"latMin":14,"latMax":33,"lonMin":-118,"lonMax":-86},"Saudi Arabia":{"latMin":16,"latMax":32,"lonMin":34,"lonMax":56},"South Africa":{"latMin":-35,"latMax":-22,"lonMin":16,"lonMax":33},"Turkey":{"latMin":35,"latMax":42,"lonMin":25,"lonMax":45},"France":{"latMin":41,"latMax":51,"lonMin":-5,"lonMax":10},"Ukraine":{"latMin":44,"latMax":53,"lonMin":22,"lonMax":41},"Nigeria":{"latMin":4,"latMax":14,"lonMin":2,"lonMax":15},"Ethiopia":{"latMin":3,"latMax":15,"lonMin":33,"lonMax":48},"Colombia":{"latMin":-5,"latMax":13,"lonMin":-79,"lonMax":-66},"Peru":{"latMin":-19,"latMax":0,"lonMin":-82,"lonMax":-68},"Chile":{"latMin":-56,"latMax":-17,"lonMin":-76,"lonMax":-66},"Venezuela":{"latMin":0,"latMax":13,"lonMin":-73,"lonMax":-59},"Japan":{"latMin":26,"latMax":46,"lonMin":129,"lonMax":146},"Germany":{"latMin":47,"latMax":55,"lonMin":5,"lonMax":16},"Thailand":{"latMin":5,"latMax":21,"lonMin":97,"lonMax":106},"Philippines":{"latMin":5,"latMax":19,"lonMin":116,"lonMax":127},"Vietnam":{"latMin":8,"latMax":23,"lonMin":102,"lonMax":110},"Tanzania":{"latMin":-12,"latMax":-1,"lonMin":29,"lonMax":41},"Kenya":{"latMin":-5,"latMax":6,"lonMin":33,"lonMax":42},"Uganda":{"latMin":-2,"latMax":5,"lonMin":29,"lonMax":35},"Spain":{"latMin":35,"latMax":44,"lonMin":-10,"lonMax":4},"Italy":{"latMin":35,"latMax":48,"lonMin":6,"lonMax":19},"Poland":{"latMin":49,"latMax":55,"lonMin":14,"lonMax":24},"Romania":{"latMin":43,"latMax":49,"lonMin":20,"lonMax":30},"Sweden":{"latMin":55,"latMax":69,"lonMin":10,"lonMax":25},"Norway":{"latMin":57,"latMax":72,"lonMin":4,"lonMax":32},"Finland":{"latMin":59,"latMax":71,"lonMin":19,"lonMax":32},"United Kingdom":{"latMin":50,"latMax":60,"lonMin":-10,"lonMax":2},"Egypt":{"latMin":22,"latMax":32,"lonMin":24,"lonMax":37},"Iran":{"latMin":25,"latMax":40,"lonMin":44,"lonMax":64},"Pakistan":{"latMin":23,"latMax":37,"lonMin":60,"lonMax":78},"Bangladesh":{"latMin":20,"latMax":27,"lonMin":88,"lonMax":93},"Myanmar":{"latMin":9,"latMax":29,"lonMin":92,"lonMax":102},"Afghanistan":{"latMin":29,"latMax":39,"lonMin":60,"lonMax":75},"Sudan":{"latMin":8,"latMax":24,"lonMin":21,"lonMax":39},"Angola":{"latMin":-18,"latMax":-4,"lonMin":11,"lonMax":24},"Mali":{"latMin":10,"latMax":25,"lonMin":-13,"lonMax":5},"Niger":{"latMin":11,"latMax":24,"lonMin":0,"lonMax":16},"Chad":{"latMin":7,"latMax":24,"lonMin":13,"lonMax":24},"Mozambique":{"latMin":-27,"latMax":-10,"lonMin":30,"lonMax":41},"Zambia":{"latMin":-18,"latMax":-8,"lonMin":21,"lonMax":34},"Zimbabwe":{"latMin":-22,"latMax":-15,"lonMin":25,"lonMax":33},"Madagascar":{"latMin":-26,"latMax":-11,"lonMin":43,"lonMax":51},"Cameroon":{"latMin":1,"latMax":14,"lonMin":8,"lonMax":17},"Ivory Coast":{"latMin":4,"latMax":11,"lonMin":-9,"lonMax":-2},"Burkina Faso":{"latMin":9,"latMax":15,"lonMin":-6,"lonMax":3},"Ghana":{"latMin":4,"latMax":12,"lonMin":-4,"lonMax":2},"Mongolia":{"latMin":41,"latMax":52,"lonMin":87,"lonMax":120},"Bolivia":{"latMin":-23,"latMax":-9,"lonMin":-70,"lonMax":-57},"Paraguay":{"latMin":-28,"latMax":-19,"lonMin":-63,"lonMax":-54},"Uruguay":{"latMin":-35,"latMax":-30,"lonMin":-59,"lonMax":-53},"New Zealand":{"latMin":-48,"latMax":-34,"lonMin":166,"lonMax":179},"Malaysia":{"latMin":0,"latMax":8,"lonMin":99,"lonMax":120},"Morocco":{"latMin":21,"latMax":36,"lonMin":-18,"lonMax":-1},"Somalia":{"latMin":-2,"latMax":12,"lonMin":40,"lonMax":52},"Central African Republic":{"latMin":2,"latMax":11,"lonMin":14,"lonMax":28},"Namibia":{"latMin":-29,"latMax":-16,"lonMin":11,"lonMax":26},"Botswana":{"latMin":-27,"latMax":-17,"lonMin":19,"lonMax":30},"Ecuador":{"latMin":-5,"latMax":2,"lonMin":-81,"lonMax":-75},"Cuba":{"latMin":19,"latMax":24,"lonMin":-85,"lonMax":-74},"Guatemala":{"latMin":13,"latMax":18,"lonMin":-93,"lonMax":-88},"Honduras":{"latMin":12,"latMax":17,"lonMin":-90,"lonMax":-83},"Costa Rica":{"latMin":8,"latMax":12,"lonMin":-86,"lonMax":-82},"Panama":{"latMin":7,"latMax":10,"lonMin":-83,"lonMax":-77},"Dominican Republic":{"latMin":17,"latMax":20,"lonMin":-72,"lonMax":-68},"Haiti":{"latMin":18,"latMax":20,"lonMin":-75,"lonMax":-71},"Jamaica":{"latMin":17,"latMax":19,"lonMin":-79,"lonMax":-76},"Puerto Rico":{"latMin":17.9,"latMax":18.5,"lonMin":-67.5,"lonMax":-65.5},"Bahamas":{"latMin":20,"latMax":27,"lonMin":-80,"lonMax":-72},"Trinidad and Tobago":{"latMin":10,"latMax":11,"lonMin":-62,"lonMax":-60},"Belize":{"latMin":15.5,"latMax":18.5,"lonMin":-89.5,"lonMax":-87.5},"El Salvador":{"latMin":13,"latMax":15,"lonMin":-91,"lonMax":-87.5},"Iceland":{"latMin":63,"latMax":67,"lonMin":-25,"lonMax":-13},"Ireland":{"latMin":51,"latMax":56,"lonMin":-11,"lonMax":-5},"Portugal":{"latMin":36,"latMax":43,"lonMin":-10,"lonMax":-6},"Belgium":{"latMin":49,"latMax":52,"lonMin":2,"lonMax":7},"Netherlands":{"latMin":50,"latMax":54,"lonMin":3,"lonMax":8},"Denmark":{"latMin":54,"latMax":58,"lonMin":8,"lonMax":16},"Switzerland":{"latMin":45,"latMax":48,"lonMin":6,"lonMax":11},"Austria":{"latMin":46,"latMax":49,"lonMin":9,"lonMax":18},"Czech Republic":{"latMin":48.5,"latMax":51,"lonMin":12,"lonMax":19},"Hungary":{"latMin":45.5,"latMax":48.5,"lonMin":16,"lonMax":23},"Croatia":{"latMin":42,"latMax":47,"lonMin":13,"lonMax":20},"Serbia":{"latMin":42,"latMax":46,"lonMin":18.5,"lonMax":23},"Bulgaria":{"latMin":41,"latMax":44,"lonMin":22,"lonMax":29},"Greece":{"latMin":34,"latMax":42,"lonMin":19,"lonMax":30},"Macedonia":{"latMin":40.5,"latMax":42.5,"lonMin":20,"lonMax":23.5},"Bosnia and Herzegovina":{"latMin":42.5,"latMax":45.5,"lonMin":15.5,"lonMax":19.5},"Slovenia":{"latMin":45,"latMax":47,"lonMin":13,"lonMax":17},"Lithuania":{"latMin":53.5,"latMax":56.5,"lonMin":20.5,"lonMax":27},"Latvia":{"latMin":55.5,"latMax":58.5,"lonMin":20.5,"lonMax":28.5},"Estonia":{"latMin":57.5,"latMax":60,"lonMin":21.5,"lonMax":28.5},"Belarus":{"latMin":51,"latMax":56,"lonMin":23,"lonMax":33},"Moldova":{"latMin":45,"latMax":48.5,"lonMin":26.5,"lonMax":30.5},"Georgia":{"latMin":41,"latMax":44,"lonMin":39.5,"lonMax":46.5},"Armenia":{"latMin":38.5,"latMax":41.5,"lonMin":43.5,"lonMax":47},"Azerbaijan":{"latMin":38.5,"latMax":42,"lonMin":44.5,"lonMax":51},"Turkmenistan":{"latMin":35,"latMax":43,"lonMin":52,"lonMax":67},"Uzbekistan":{"latMin":37,"latMax":46,"lonMin":56,"lonMax":72},"Kyrgyzstan":{"latMin":39,"latMax":44,"lonMin":69,"lonMax":80},"Tajikistan":{"latMin":36.5,"latMax":41.5,"lonMin":67.5,"lonMax":76},"Nepal":{"latMin":26,"latMax":31,"lonMin":80,"lonMax":89},"Sri Lanka":{"latMin":5.5,"latMax":10,"lonMin":79.5,"lonMax":82},"Cambodia":{"latMin":10,"latMax":15,"lonMin":102,"lonMax":108},"Laos":{"latMin":14,"latMax":23,"lonMin":100,"lonMax":108},"Taiwan":{"latMin":21.5,"latMax":25.5,"lonMin":120,"lonMax":122},"Greenland":{"latMin":59,"latMax":84,"lonMin":-73,"lonMax":-12},"Iraq":{"latMin":29,"latMax":38,"lonMin":38,"lonMax":49},"Syria":{"latMin":32,"latMax":37.5,"lonMin":35.5,"lonMax":42.5},"Jordan":{"latMin":29,"latMax":33.5,"lonMin":34.5,"lonMax":39.5},"Lebanon":{"latMin":33,"latMax":35,"lonMin":35,"lonMax":37},"Israel":{"latMin":29,"latMax":34,"lonMin":34,"lonMax":36},"Yemen":{"latMin":12,"latMax":19,"lonMin":42,"lonMax":54},"Oman":{"latMin":16,"latMax":27,"lonMin":52,"lonMax":60},"UAE":{"latMin":22,"latMax":26.5,"lonMin":51,"lonMax":57},"Qatar":{"latMin":24.5,"latMax":26.5,"lonMin":50.5,"lonMax":52},"Kuwait":{"latMin":28.5,"latMax":30.5,"lonMin":46.5,"lonMax":49},"Cyprus":{"latMin":34,"latMax":36,"lonMin":32,"lonMax":35},"Singapore":{"latMin":1.1,"latMax":1.5,"lonMin":103.5,"lonMax":104.2},"Fiji":{"latMin":-20,"latMax":-15,"lonMin":176,"lonMax":-178},"Solomon Islands":{"latMin":-12,"latMax":-5,"lonMin":155,"lonMax":170},"Vanuatu":{"latMin":-20,"latMax":-13,"lonMin":166,"lonMax":170},"Samoa":{"latMin":-14.5,"latMax":-13,"lonMin":-173,"lonMax":-171},"Tonga":{"latMin":-23,"latMax":-15,"lonMin":-176,"lonMax":-173},"Kiribati":{"latMin":-12,"latMax":5,"lonMin":-175,"lonMax":177},"Micronesia":{"latMin":5,"latMax":10,"lonMin":137,"lonMax":164},"Marshall Islands":{"latMin":4,"latMax":15,"lonMin":160,"lonMax":173},"Palau":{"latMin":2.5,"latMax":9,"lonMin":131,"lonMax":135},"Nauru":{"latMin":-0.6,"latMax":-0.4,"lonMin":166.8,"lonMax":167},"Tuvalu":{"latMin":-10,"latMax":-5.5,"lonMin":176,"lonMax":180},"Maldives":{"latMin":-1,"latMax":8,"lonMin":72,"lonMax":74},"Seychelles":{"latMin":-10,"latMax":-3,"lonMin":46,"lonMax":57},"Cape Verde":{"latMin":14.5,"latMax":17.5,"lonMin":-25.5,"lonMax":-22.5},"Comoros":{"latMin":-13,"latMax":-11,"lonMin":43,"lonMax":45},"Mauritius":{"latMin":-20.5,"latMax":-19.5,"lonMin":57,"lonMax":58},"Equatorial Guinea":{"latMin":-2,"latMax":4,"lonMin":5,"lonMax":12},"Guinea-Bissau":{"latMin":10.5,"latMax":12.5,"lonMin":-16.5,"lonMax":-13.5},"Gambia":{"latMin":13,"latMax":14,"lonMin":-17,"lonMax":-13.5},"Senegal":{"latMin":12,"latMax":17,"lonMin":-18,"lonMax":-11},"Sierra Leone":{"latMin":6.5,"latMax":10,"lonMin":-13.5,"lonMax":-10},"Liberia":{"latMin":4,"latMax":9,"lonMin":-12,"lonMax":-7},"Guinea":{"latMin":7,"latMax":13,"lonMin":-15.5,"lonMax":-7.5},"Togo":{"latMin":6,"latMax":11.5,"lonMin":-1,"lonMax":2},"Benin":{"latMin":6,"latMax":12.5,"lonMin":0.5,"lonMax":4},"Malawi":{"latMin":-17,"latMax":-9,"lonMin":32,"lonMax":36},"Rwanda":{"latMin":-2.8,"latMax":-1,"lonMin":28.5,"lonMax":31},"Burundi":{"latMin":-4.5,"latMax":-2,"lonMin":28.5,"lonMax":31},"Djibouti":{"latMin":10.5,"latMax":13,"lonMin":41.5,"lonMax":43.5},"Eritrea":{"latMin":12,"latMax":18.5,"lonMin":36,"lonMax":44},"Lesotho":{"latMin":-30.5,"latMax":-28.5,"lonMin":27,"lonMax":29.5},"Swaziland":{"latMin":-27.5,"latMax":-25.5,"lonMin":30.5,"lonMax":32.5},"South Sudan":{"latMin":3.5,"latMax":12,"lonMin":23.5,"lonMax":36},"Papua New Guinea":{"latMin":-12,"latMax":0,"lonMin":140,"lonMax":156},"South Korea":{"latMin":33,"latMax":39,"lonMin":124,"lonMax":132},"North Korea":{"latMin":37,"latMax":43,"lonMin":124,"lonMax":131},"Tunisia":{"latMin":30,"latMax":38,"lonMin":7,"lonMax":12},"Libya":{"latMin":19,"latMax":34,"lonMin":9,"lonMax":26},"Congo":{"latMin":-5,"latMax":4,"lonMin":11,"lonMax":19},"Gabon":{"latMin":-4,"latMax":3,"lonMin":8,"lonMax":15},"Guyana":{"latMin":1,"latMax":9,"lonMin":-61,"lonMax":-56},"Suriname":{"latMin":1,"latMax":6,"lonMin":-59,"lonMax":-53},"Nicaragua":{"latMin":10,"latMax":15,"lonMin":-88,"lonMax":-83},"Albania":{"latMin":39,"latMax":43,"lonMin":19,"lonMax":21},"Montenegro":{"latMin":41.5,"latMax":43.5,"lonMin":18,"lonMax":20.5},"Kosovo":{"latMin":42,"latMax":44,"lonMin":20,"lonMax":22},"Slovakia":{"latMin":47.5,"latMax":49.5,"lonMin":16.5,"lonMax":23},"Malta":{"latMin":35.5,"latMax":36.5,"lonMin":14,"lonMax":15},"Luxembourg":{"latMin":49,"latMax":51,"lonMin":5.5,"lonMax":6.5},"Åland":{"latMin":59.8,"latMax":60.7,"lonMin":19.5,"lonMax":21.5},"Bahrain":{"latMin":25.5,"latMax":26.5,"lonMin":50,"lonMax":51},"Monaco":{"latMin":43.7,"latMax":43.8,"lonMin":7.4,"lonMax":7.5},"Andorra":{"latMin":42.4,"latMax":42.7,"lonMin":1.4,"lonMax":1.8},"Liechtenstein":{"latMin":47,"latMax":47.3,"lonMin":9.4,"lonMax":9.7},"San Marino":{"latMin":43.8,"latMax":44,"lonMin":12.3,"lonMax":12.5},"Vatican City":{"latMin":41.8,"latMax":42,"lonMin":12.3,"lonMax":12.5},"Brunei":{"latMin":4,"latMax":5.2,"lonMin":114,"lonMax":115.5},"Sao Tome and Principe":{"latMin":-0.1,"latMax":2,"lonMin":6,"lonMax":7.5}};

// Build id -> {name, country}
const idMap = {};
const countryRegions = {};
for (const c of regions.countries) {
  if (!countryRegions[c.country]) countryRegions[c.country] = [];
  for (const r of c.regions) {
    idMap[r.id] = { name: r.name, country: c.country };
    countryRegions[c.country].push(r.id);
  }
}

// Get current centroid for each country
const countryCentroid = {};
for (const [idStr, coord] of Object.entries(coordsRaw)) {
  const info = idMap[parseInt(idStr)];
  if (!info) continue;
  if (!countryCentroid[info.country]) {
    countryCentroid[info.country] = { lat: coord.lat, lon: coord.lon };
  }
}

// Seeded random
function makeRand(seed) {
  let s = seed;
  return () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; };
}

const newCoords = {};
let totalSpread = 0;

for (const [country, ids] of Object.entries(countryRegions)) {
  const centroid = countryCentroid[country] || { lat: 0, lon: 0 };
  const count = ids.length;

  // Get bounding box for this country
  let bbox = bounds[country];
  if (!bbox) {
    // Heuristic: small countries get small spread
    const spread = Math.min(3, Math.max(0.2, count / 20));
    bbox = {
      latMin: centroid.lat - spread,
      latMax: centroid.lat + spread,
      lonMin: centroid.lon - spread * 1.5,
      lonMax: centroid.lon + spread * 1.5,
    };
  }

  // Seed based on country name for consistent results
  let seed = 0;
  for (let i = 0; i < country.length; i++) seed += country.charCodeAt(i);
  const rand = makeRand(seed);

  // 计算扩散范围：有边界数据的用边界，否则根据地区数量推算
  let latRange, lonRange, latCtr, lonCtr;
  if (bounds[country]) {
    // 收缩 15% 避免点到海里
    const b = bounds[country];
    const margin = 0.15;
    const latSpan = b.latMax - b.latMin;
    const lonSpan = b.lonMax - b.lonMin;
    latCtr = (b.latMin + b.latMax) / 2;
    lonCtr = (b.lonMin + b.lonMax) / 2;
    latRange = latSpan * (1 - margin);
    lonRange = lonSpan * (1 - margin);
  } else {
    // 无边界数据：根据地区数推算
    latCtr = centroid.lat;
    lonCtr = centroid.lon;
    const scale = Math.sqrt(count) * 0.8;
    latRange = Math.min(30, scale);
    lonRange = Math.min(50, scale * 1.5);
  }

  // 打乱顺序，避免字母序前列的地区总被放在边角
  const shuffled = [...ids];
  for (let s = shuffled.length - 1; s > 0; s--) {
    const j = Math.floor(rand() * (s + 1));
    [shuffled[s], shuffled[j]] = [shuffled[j], shuffled[s]];
  }

  // 用行列网格均匀分布（收缩后的范围内）
  const aspectRatio = lonRange / Math.max(0.1, latRange);
  const cols = Math.max(1, Math.round(Math.sqrt(count * aspectRatio)));
  const rows = Math.ceil(count / cols);

  for (let i = 0; i < shuffled.length; i++) {
    const id = shuffled[i];
    const info = idMap[id];

    if (info.name === info.country || count === 1) {
      newCoords[id] = { lat: +latCtr.toFixed(4), lon: +lonCtr.toFixed(4) };
    } else {
      const row = Math.floor(i / cols);
      const col = i % cols;
      const latStep = latRange / Math.max(1, rows - 1 + 1e-9);
      const lonStep = lonRange / Math.max(1, cols - 1 + 1e-9);
      // 小随机偏移避免太整齐
      const jLat = (rand() - 0.5) * latStep * 0.4;
      const jLon = (rand() - 0.5) * lonStep * 0.4;

      newCoords[id] = {
        lat: +(latCtr - latRange / 2 + row * latStep + jLat).toFixed(4),
        lon: +(lonCtr - lonRange / 2 + col * lonStep + jLon).toFixed(4),
      };
      totalSpread++;
    }
  }
}

fs.writeFileSync('assets/region_coords.json', JSON.stringify(newCoords, null, 2));

// Stats
const unique = new Set(Object.values(newCoords).map(v => v.lat.toFixed(4)+','+v.lon.toFixed(4)));
console.log('总地区:', Object.keys(newCoords).length);
console.log('唯一坐标:', unique.size);
console.log('零坐标:', Object.values(newCoords).filter(v => v.lat===0&&v.lon===0).length);
console.log('已扩散子地区:', totalSpread);

// Check US states
const usIds = countryRegions['United States'] || [];
console.log('\n美国州示例 (前8):');
usIds.slice(0, 8).forEach(id => {
  const info = idMap[id];
  const c = newCoords[id];
  console.log('  ' + info.name + ': ' + c.lat + ', ' + c.lon);
});
