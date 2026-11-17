// Client-side PDF-tekstextractie met pdf.js (gebundeld in ./pdfjs, Apache-2.0).
// Het bestand verlaat de browser nooit: alles gebeurt lokaal.
let pdfjsPromise;

function loadPdfJs() {
  if (!pdfjsPromise) {
    pdfjsPromise = import('./pdfjs/pdf.min.mjs').then((lib) => {
      lib.GlobalWorkerOptions.workerSrc = new URL('./pdfjs/pdf.worker.min.mjs', import.meta.url).toString();
      return lib;
    });
  }
  return pdfjsPromise;
}

// Zet tekstitems om naar regels (op y-positie), met extra spaties bij grote
// horizontale gaten, zodat kolommen gescheiden blijven (zoals pdftotext -layout).
function itemsToLines(items) {
  const rows = [];
  for (const it of items) {
    if (!it.str || !it.str.trim()) continue;
    const x = it.transform[4];
    const y = it.transform[5];
    let row = rows.find((r) => Math.abs(r.y - y) < 2.5);
    if (!row) { row = { y, items: [] }; rows.push(row); }
    row.items.push({ x, w: it.width, s: it.str });
  }
  rows.sort((a, b) => b.y - a.y);
  return rows.map((r) => {
    r.items.sort((a, b) => a.x - b.x);
    let line = '';
    let end = null;
    for (const it of r.items) {
      if (end !== null) {
        const gap = it.x - end;
        if (gap > 12) line += '   ';
        else if (gap > 1.2 && !line.endsWith(' ') && !it.s.startsWith(' ')) line += ' ';
      }
      line += it.s;
      end = it.x + it.w;
    }
    return line.replace(/\s+$/, '');
  });
}

async function swipeSpendPdfToText(bytes) {
  const lib = await loadPdfJs();
  const task = lib.getDocument({ data: bytes, isEvalSupported: false });
  const doc = await task.promise;
  const pages = [];
  for (let p = 1; p <= doc.numPages; p++) {
    const page = await doc.getPage(p);
    const content = await page.getTextContent();
    pages.push(itemsToLines(content.items).join('\n'));
  }
  await task.destroy();
  return pages.join('\n');
}

window.swipeSpendPdfToText = swipeSpendPdfToText;
