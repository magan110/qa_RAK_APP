// Quick parser that mirrors the Dart _parseAadhaarFields logic for testing
const sample = `&S Government of India .
s T g
H Magan Dhaniya g
5 S fafel/DOB: 07/02/2003 3
2 L Ces | 9oW/ MALE g
-1 s
e 1 n
N 3
2 8
‘ g §
| 8 -
8325 2709 6374 b
VID : 9149 4449 3304 2200 |
AT 3TENTY, ALY 98T`;

function parseAadhaarFields(text) {
  const lines = text.split(/\r?\n/).map(l => l.trim()).filter(l => l.length > 0);

  // Candidate lines: filter out single-character/noise lines
  const candidateLines = lines.filter(l => {
    const alnum = l.replace(/[^A-Za-z0-9\s]/g, '');
    if (alnum.replace(/\s+/g, '').length <= 1) return false;
    if (!/[A-Za-z0-9]/.test(alnum)) return false;
    return true;
  });

  let government = '';
  let name = '';
  let dob = '';
  let aadhaar = '';
  let vid = '';

  for (const l of candidateLines) {
    const low = l.toLowerCase();
    if (low.includes('government') || low.includes('भारत') || low.includes('india') || low.includes('भारतीय')) {
      government = l; break;
    }
  }

  for (const l of candidateLines) {
    const m = /(\d{4}\s?\d{4}\s?\d{4})/.exec(l);
    if (m) { aadhaar = m[1].replace(/\s+/g, ''); break; }
  }
  if (!aadhaar) {
    for (const l of lines) {
      const m = /(\d{12})/.exec(l.replace(/[^0-9]/g, ''));
      if (m) { aadhaar = m[1]; break; }
    }
  }

  for (const l of candidateLines) {
    const m = /(\d{4}\s?\d{4}\s?\d{4}\s?\d{4})/.exec(l);
    if (m) { vid = m[1].replace(/\s+/g, ''); break; }
  }

  const dobRegex = /(\d{2}[\/\-]\d{2}[\/\-]\d{4})/;
  const mDob = dobRegex.exec(text);
  if (mDob) dob = mDob[1]; else {
    const mDob2 = /(\d{4}[\/\-]\d{2}[\/\-]\d{2})/.exec(text);
    if (mDob2) dob = mDob2[1];
  }

  if (aadhaar) {
    const idx = lines.findIndex(l => l.replace(/\s+/g, '').includes(aadhaar));
    if (idx > 0) {
      for (let j = idx - 1; j >= 0; j--) {
        const cand = lines[j];
        if (/[A-Za-z].*[A-Za-z]/.test(cand)) {
          const alphaOnly = cand.replace(/[^A-Za-z]/g, '');
          const alphaRatio = alphaOnly.length / (cand.replace(/\s+/g, '').length + 1);
          const words = cand.split(/\s+/).filter(Boolean);
          const goodWords = words.filter(w => w.replace(/[^A-Za-z]/g, '').length >= 2).length;
          if (cand.toLowerCase().includes('male') || cand.toLowerCase().includes('female')) continue;
          const wordsClean = words.filter(w => {
            const wc = w.replace(/[^A-Za-z]/g, '');
            if (wc.length < 2) return false;
            if (/\d/.test(w)) return false;
            if (wc.length <= 3 && wc.toUpperCase() === wc) return false;
            return true;
          });
          if (alphaOnly.length >= 4 && (alphaRatio > 0.45 || goodWords >= 2) && wordsClean.length >= 1) { name = cand; break; }
        }
      }
    }
  }
  if (!name && dob) {
    const idx = lines.findIndex(l => l.includes(dob));
    if (idx > 0) {
      for (let j = idx - 1; j >= 0; j--) {
        const cand = lines[j];
        if (/[A-Za-z].*[A-Za-z]/.test(cand)) { name = cand; break; }
      }
    }
  }
  if (!name) {
    for (const l of candidateLines) {
      if (l.length > 3 && /[A-Za-z]/.test(l) && !/\d/.test(l)) {
        const low = l.toLowerCase();
        if (!low.includes('dob') && !low.includes('year') && !low.includes('age') && !low.includes('male') && !low.includes('female') && !low.includes('government')) {
          name = l; break; }
      }
    }
  }

  function cleanName(s) {
    return (s || '').replace(/[^A-Za-z\s\.-]/g, '').replace(/\s+/g, ' ').trim();
  }

  government = cleanName(government);
  name = cleanName(name);
  if (name) {
    let parts = name.split(/\s+/).filter(Boolean);
    if (parts.length > 1 && parts[0].length === 1) parts.shift();
    if (parts.length > 1 && parts[parts.length - 1].length === 1) parts.pop();
    parts = parts.filter(p => {
      const low = p.toLowerCase();
      if (low === 'male' || low === 'female') return false;
      const onlyAlpha = p.replace(/[^A-Za-z]/g, '');
      if (onlyAlpha.length <= 2) return false;
      if (/\d/.test(p)) return false;
      if (onlyAlpha.length <= 3 && onlyAlpha.toUpperCase() === onlyAlpha) return false;
      return true;
    });
    name = parts.map(p => p.length ? (p[0].toUpperCase() + p.slice(1).toLowerCase()) : p).join(' ');
  }
  aadhaar = (aadhaar || '').replace(/[^0-9]/g, '');
  vid = (vid || '').replace(/[^0-9]/g, '');
  dob = (dob || '').trim();

  return { government, name, dob, aadhaar, vid };
}

console.log(JSON.stringify(parseAadhaarFields(sample), null, 2));
