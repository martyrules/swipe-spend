// Headless rooktest + screenshots van de web-build (390x844).
// Gebruik: node tool/screenshots.mjs [url]  (playwright-core + system Chrome)
import { createRequire } from 'module';
import fs from 'fs';
const require = createRequire('/home/box/.pwtools/');
const { chromium } = require('playwright-core');

const url = process.argv[2] ?? 'http://localhost:8765/';
const out = '/workspace/swipe_spend/screenshots';
fs.mkdirSync(out, { recursive: true });

// Volgorde = CSV-volgorde (uitgaven, gesorteerd op datum, stabiel).
const csv = fs.readFileSync('/workspace/swipe_spend/assets/voorbeelddata_oktober_2026.csv', 'utf8')
  .trim().split('\n').slice(1).map(l => l.split(';')).filter(c => c[3].startsWith('-'));
const regretSet = new Set(['Uber Eats', 'Takeaway', 'Starbucks', 'Zalando', 'Steam', 'Primark', 'Disney Plus']);

const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--no-sandbox'] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: false });
const errors = [];
page.on('pageerror', e => errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });

const shot = async (name, keepMouse = false) => { if (!keepMouse) await page.mouse.move(380, 836); await page.waitForTimeout(700); await page.screenshot({ path: `${out}/${name}.png` }); console.log('shot', name); };
const btn = (name) => page.getByRole('button', { name, exact: false }).first();

await page.goto(url);
await page.waitForSelector('flt-semantics', { timeout: 30000, state: 'attached' });
await page.waitForTimeout(1500);
await shot('01_onboarding_1');
await btn('Volgende').click(); await shot('02_onboarding_2');
await btn('Volgende').click(); await shot('03_onboarding_3');
await btn('Aan de slag').click(); await shot('04_import');
await btn('Laad voorbeelddata').click(); await page.waitForTimeout(800);
await page.mouse.wheel(0, 600); await shot('05_import_geladen');
await btn('Start met swipen').click(); await shot('06_swipe_kaart');

const cx = 195, cy = 420;
async function drag(dx, hold) {
  await page.mouse.move(cx, cy);
  await page.mouse.down();
  await page.mouse.move(cx + dx, cy + 10, { steps: 12 });
  if (hold) { await shot(hold, true); }
  await page.mouse.up();
  await page.waitForTimeout(500);
}
// Kaart 1 (Spotify): sleep rechts, toon groene overlay, laat los = opnieuw.
await drag(130, '07_swipe_drag_rechts_opnieuw');
// Kaart 2 (Delhaize): sleep een beetje links (rode overlay) en laat terugveren, dan rechts.
await page.mouse.move(cx, cy); await page.mouse.down();
await page.mouse.move(cx - 120, cy + 10, { steps: 12 });
await shot('08_swipe_drag_links_spijt', true);
await page.mouse.move(cx - 20, cy, { steps: 4 }); await page.mouse.up(); await page.waitForTimeout(500);
await drag(160);
// Rest via knoppen.
for (let i = 2; i < csv.length; i++) {
  const regret = regretSet.has(csv[i][2]);
  await btn(regret ? 'Spijt (links)' : 'Opnieuw (rechts)').click();
  await page.waitForTimeout(380);
  if (i === 11) {
    await shot('09_swipe_voortgang');
    await btn('Ongedaan maken').click(); await page.waitForTimeout(400);
    await shot('10_swipe_na_undo');
    await btn(regret ? 'Spijt (links)' : 'Opnieuw (rechts)').click(); await page.waitForTimeout(380);
  }
}
await page.waitForTimeout(1200);
await shot('11_overzicht_top');
for (let k = 0; k < 5; k++) { await page.mouse.move(195, 500); await page.mouse.wheel(0, 700); await shot(`${12 + k}_overzicht_scroll_${k + 1}`); }

const txt = await page.evaluate(() => document.querySelector('flt-semantics-host')?.innerText ?? '');
fs.writeFileSync(`${out}/overzicht_semantics.txt`, txt);
console.log('errors:', JSON.stringify(errors));
await browser.close();
