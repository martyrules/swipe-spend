// Headless rooktest + screenshots (390x844) van de web-build, ENKEL voorbeelddata.
// Gebruik: node tool/screenshots_v2.mjs [url] [outdir]
import { createRequire } from 'module';
import fs from 'fs';
const require = createRequire('/home/box/.pwtools/');
const { chromium } = require('playwright-core');

const url = process.argv[2] ?? 'http://127.0.0.1:47124/swipe-spend/';
const out = process.argv[3] ?? '/workspace/swipe_spend/screenshots_v2';
const root = '/workspace/swipe_spend';
fs.mkdirSync(out, { recursive: true });

const csv = fs.readFileSync(`${root}/assets/voorbeelddata_oktober_2026.csv`, 'utf8')
  .trim().split('\n').slice(1).map((l) => l.split(';')).filter((c) => c[3].startsWith('-'));
const regretRe = /Uber Eats|Takeaway|Starbucks|Zalando|STEAM|Primark|Disney|AMAZON|F1\.COM|KOSTEN/;

const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--no-sandbox'] });
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(String(e)));
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });

const shot = async (name, keepMouse = false) => {
  if (!keepMouse) await page.mouse.move(388, 2);
  await page.waitForTimeout(800);
  await page.screenshot({ path: `${out}/${name}.png` });
  console.log('shot', name);
};
const btn = (name) => page.getByRole('button', { name, exact: false }).first();
const semText = () => page.evaluate(() => document.querySelector('flt-semantics-host')?.innerText ?? '');
const ready = async () => { await page.waitForSelector('flt-semantics', { timeout: 30000, state: 'attached' }); await page.waitForTimeout(1500); };

await page.goto(url);
await ready();
await shot('01_onboarding_1');
await btn('Volgende').click(); await page.waitForTimeout(500); await shot('02_onboarding_2');
await btn('Volgende').click(); await page.waitForTimeout(500); await shot('03_onboarding_3');
await btn('Aan de slag').click(); await shot('04_import');
await btn('Laad voorbeelddata').click(); await page.waitForTimeout(900);
await shot('05_import_geladen');
await btn('Start met swipen').click(); await page.waitForTimeout(600);
await shot('06_swipe_kaart');

const cx = 195, cy = 430;
async function dragHold(dx, name) {
  await page.mouse.move(cx, cy); await page.mouse.down();
  await page.mouse.move(cx + dx, cy + 12, { steps: 14 });
  await shot(name, true);
}
await dragHold(120, '07_swipe_sleep_rechts_opnieuw');
await page.mouse.move(cx + 20, cy, { steps: 3 }); await page.mouse.up(); await page.waitForTimeout(900); // veert terug
await dragHold(-120, '08_swipe_sleep_links_spijt');
await page.mouse.move(cx - 220, cy + 20, { steps: 6 }); await page.mouse.up(); await page.waitForTimeout(700); // Spotify = spijt? nee: zie hieronder
// Kaart 1 werd zo links geswiped; maak ongedaan om het patroon te volgen.
await btn('Ongedaan maken').click(); await page.waitForTimeout(600);

let noted = false;
for (let i = 0; i < csv.length; i++) {
  const desc = csv[i][1] + ' ' + csv[i][2];
  const regret = regretRe.test(desc);
  if (!noted && /Zalando/.test(desc)) {
    await btn('Wat was het?').click(); await page.waitForTimeout(700);
    await page.getByRole('textbox').first().click();
    await page.keyboard.type('Jas die ik nooit draag');
    await page.getByRole('checkbox', { name: 'Impuls' }).click();
    await page.getByRole('checkbox', { name: 'Verveling' }).click();
    await page.waitForTimeout(300);
    await shot('09_wat_was_het_sheet');
    await btn('Bewaren').click(); await page.waitForTimeout(700);
    await shot('10_kaart_met_notitie');
    noted = true;
  }
  if (/AMAZON/.test(desc)) await shot('11_kaart_ruwe_descriptor_amazon');
  await btn(regret ? 'Spijt (links)' : 'Opnieuw (rechts)').click();
  await page.waitForTimeout(420);
  if (i === 17) {
    await shot('12_swipe_voortgang');
    // Herladen: state moet blijven (localStorage).
    await page.reload(); await ready();
    await shot('13_na_herladen');
    const t = await semText();
    console.log('na reload:', /Voortgang 19 van 41/.test(t) ? 'OK: 18 swipes bewaard (kaart 19/41)' : 'NIET bewaard: ' + t.slice(0, 200));
  }
  if (/STEAM/.test(desc)) { /* na de swipe */ }
}
await page.waitForTimeout(400);
await shot('14_overzicht_confetti');
await page.waitForTimeout(2500);
await shot('15_overzicht_top');
for (let k = 0; k < 6; k++) { await page.mouse.move(195, 600); await page.mouse.wheel(0, 650); await page.waitForTimeout(400); await shot(`${16 + k}_overzicht_scroll_${k + 1}`); }
const sum = await semText();
fs.writeFileSync('/tmp/ss_overzicht_semantics.txt', sum);

// Argenta-pdf import met het VERZONNEN voorbeeld-afschrift.
const page2 = await ctx.newPage();
await page2.goto(url); await page2.waitForSelector('flt-semantics', { state: 'attached' }); await page2.waitForTimeout(1500);
const [chooser] = await Promise.all([
  page2.waitForEvent('filechooser'),
  page2.getByRole('button', { name: 'Kies pdf-afschrift' }).first().click(),
]);
await chooser.setFiles(`${root}/test/fixtures/argenta_voorbeeld.pdf`);
await page2.waitForTimeout(2500);
await page2.mouse.move(388, 2);
await page2.screenshot({ path: `${out}/22_pdf_import_voorbeeld.png` }); console.log('shot 22_pdf_import_voorbeeld');
const t2 = await page2.evaluate(() => document.querySelector('flt-semantics-host')?.innerText ?? '');
console.log('pdf voorbeeld:', (t2.match(/\d+ uitgaven ingeladen/) || ['?'])[0], /Klopt met/.test(t2) ? 'saldo klopt' : 'saldo?');
await page2.getByRole('button', { name: 'Start met swipen' }).first().click(); await page2.waitForTimeout(800);
for (let i = 0; i < 3; i++) { await page2.getByRole('button', { name: 'Opnieuw (rechts)' }).first().click(); await page2.waitForTimeout(450); }
await page2.mouse.move(388, 2); await page2.waitForTimeout(600);
await page2.screenshot({ path: `${out}/23_pdf_kaart_usd_koers.png` }); console.log('shot 23_pdf_kaart_usd_koers');

console.log('errors:', JSON.stringify(errors));
await browser.close();
