# Regretto (demo)

<img src="web/icons/Icon-192.png" width="96" alt="Regretto-logo">

_Werktitel was "Swipe Spend"; de repo heet nog `swipe-spend`._

**Live demo:** https://martyrules.github.io/swipe-spend/

Laad de uitgaven van je maand in en swipe ze één voor één, Tinder-gewijs:
rechts = "zou ik opnieuw doen", links = "niet meer" (spijt). Daarna zie je hoeveel spijt
je had, per categorie, en wat je per maand kan besparen als je dat schrapt.

> ⚠️ **Dit is een demo met voorbeelddata.** Alle uitgaven in deze repo
> (`assets/voorbeelddata_oktober_2026.csv` en het verzonnen afschrift
> `test/fixtures/argenta_voorbeeld.pdf`) zijn verzonnen. Er komen géén echte
> bankgegevens in deze repo. Laad je in de app zelf een CSV of pdf in, dan blijft die
> lokaal in je browser (localStorage): er is geen backend en niks wordt verstuurd.

## Wat zit erin (v2)
- Onboarding met vector-illustraties (enkel de eerste keer; "Intro opnieuw tonen" in het menu)
- Import: voorbeelddata, eigen CSV, of **Argenta kredietkaart (pdf)**: pdf.js leest de pdf in de browser
  (gebundeld in `web/pdfjs`), de parser controleert de som tegen het "Nieuw Saldo"
- Opkuis van ruwe bank-omschrijvingen ("Public Charging Belgiu Bruxelles BEL" → Laadpaal) + categorie;
  de ruwe omschrijving blijft klein zichtbaar op de kaart
- Swipe-kaarten met avatar, categoriekleur, grote bedragen (Inter, tabular figures), vreemde munt + koers,
  stempels OPNIEUW/SPIJT, veer-terug-animatie, undo
- "Wat was het?": notitie + reden-chips (impuls, verveling, nodig, cadeau, gepland), zichtbaar in de spijt-lijst
- Spijt-overzicht met tellende bedragen, donut per categorie, confetti na je sessie
- Alles wordt lokaal bewaard: swipes en notities overleven een refresh; "Alle data wissen" in het menu

## Naam veranderen
De app-naam staat op één plek in de code: `lib/app_config.dart` (`AppConfig.appName`, nu "Regretto").
Daarnaast: `<title>` in `web/index.html`, `web/manifest.json`, en de iconen (`python3 tool/make_icons.py`).

## Structuur
`lib/models`, `lib/services` (CSV- en Argenta-parser, merchant-mapping, categorisatie, inzichten,
pdf-tekst via JS-interop), `lib/state`, `lib/screens`, `lib/widgets`.

## Lokaal draaien
```
flutter pub get
flutter test
flutter run -d chrome
```
Gebouwd met Flutter 3.50 (Material 3 via `package:material_ui`). Lettertype Inter (SIL OFL),
pdf.js (Apache-2.0).
