# Swipe Spend (demo)

**Live demo:** https://martyrules.github.io/swipe-spend/

Laad de uitgaven van je maand in en swipe ze één voor één, Tinder-gewijs:
rechts = "zou ik opnieuw doen", links = "niet meer" (spijt). Daarna zie je hoeveel spijt
je had, per categorie, en wat je per maand kan besparen als je dat schrapt.

> ⚠️ **Dit is een demo met voorbeelddata.** Alle uitgaven in deze repo
> (`assets/voorbeelddata_oktober_2026.csv`) zijn verzonnen. Er komen géén echte
> bankgegevens in deze repo. Laad je in de app zelf een CSV in, dan blijft die
> lokaal in je browser: er is geen backend en niks wordt opgeslagen of verstuurd.

## Wat zit erin
- Onboarding (3 schermpjes)
- Import: voorbeelddata of eigen CSV (`date;description;counterparty;amount`, `;` of `,`, dd/mm/jjjj, komma-decimalen)
- Automatische categorieën op trefwoorden (Boodschappen, Uit eten/Takeaway, Shopping, Abonnementen, Vervoer, Ontspanning, Overig)
- Swipe-sessie met drag, groene/rode overlay, knoppen, ongedaan maken en voortgang
- Spijt-overzicht: totaal vs spijt (€ en %), donut per categorie, lijst spijt-uitgaven, besparing per maand

## Structuur
`lib/models`, `lib/services` (CSV-parser, categorisatie, inzichten), `lib/state`, `lib/screens`, `lib/widgets`.

## Lokaal draaien
```
flutter pub get
flutter test
flutter run -d chrome
```
Gebouwd met Flutter 3.50 (Material 3 via `package:material_ui`).
