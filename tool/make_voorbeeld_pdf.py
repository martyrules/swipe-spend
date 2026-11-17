"""Genereert een VERZONNEN Argenta-achtig kredietkaartafschrift (voorbeelddata).

Zelfde layout als het echte afschrift (kolommen, vreemde munt + koersregel,
kosten zonder datum, saldi, header per pagina), maar alle namen, nummers en
bedragen zijn verzonnen. Gebruik: python3 tool/make_voorbeeld_pdf.py
"""
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

OUT = 'test/fixtures/argenta_voorbeeld.pdf'

PREV = 412.30
PAGE1 = [
    ('03/10', '14/10', 'DOMICILIERING VIA UW BANK', None, '412,30+'),
    'CARD',
    ('06/10', '07/10', 'Public Charging Belgiu Bruxelles BEL', None, '5,12-'),
    ('07/10', '08/10', 'BPOST GENT Gent BEL', None, '12,40-'),
    ('08/10', '09/10', 'Bistro De Hoek Gent BEL', None, '18,60-'),
    ('09/10', '09/10', 'TRADINGVIEW CHARTING S Dublin D', '15,00-USD', '13,64-'),
    'FX 1 EUR=1,0997067 USD',
    ('10/10', '11/10', 'WL STEAM PURCHASE BELLEVUE WA', None, '9,99-'),
    ('12/10', '13/10', 'CARREFOUR GENT ZUID GENT BEL', None, '47,85-'),
    ('14/10', '15/10', 'CASH Bancontact Gent Zuid BEL', None, '40,00-'),
    'FEE 6,00-',
    ('16/10', '17/10', 'AMAZON.BE X7K2M9Q1A LUXEMBOURG DUB', None, '23,99-'),
]
PAGE2 = [
    ('19/10', '20/10', 'AMAZON.BE X7K2M9Q1A LUXEMBOURG DUB', None, '23,99+'),
    ('21/10', '22/10', 'ANTHROPIC CLAUDE SUB SAN FRANCISCO CA', None, '19,36-'),
    ('24/10', '25/10', 'Public Charging Belgiu Bruxelles BEL', None, '3,96-'),
    ('27/10', '28/10', 'Battle.net Cork IRL', None, '9,49-'),
    ('30/10', '31/10', 'HETZNER ONLINE GMBH GUNZENHAUSEN DEU', None, '5,40-'),
    ('02/11', '03/11', 'WWW.F1.COM LONDON LND', None, '10,99-'),
]


def amount(s):
    v = float(s[:-1].replace('.', '').replace(',', '.'))
    return v if s.endswith('-') else -v


def total():
    t = PREV
    for row in PAGE1 + PAGE2:
        if isinstance(row, tuple):
            t += amount(row[4])
        elif row.startswith('FEE'):
            t += amount(row.split()[1])
    return t


def fmt(v):
    s = f'{abs(v):,.2f}'.replace(',', 'X').replace('.', ',').replace('X', '.')
    return s + ('-' if v >= 0 else '+')


def header(c, page, pages):
    c.setFont('Helvetica', 8)
    c.drawString(40, 800, 'Datum 04/11/2026')
    c.drawString(300, 800, f'{page}/{pages}')
    c.drawString(40, 780, 'Transacties van 05/10/2026 tot 04/11/2026')
    c.drawString(360, 770, 'DHR. VOORBEELD KLANT')
    c.drawString(360, 760, 'VOORBEELDSTRAAT 1')
    c.drawString(40, 750, 'Klantenreferentie 0000000000')
    c.drawString(360, 750, '1000 BRUSSEL')
    c.drawString(40, 730, 'Gebruikslimiet 1.000,00 EUR')
    c.setFont('Helvetica-Bold', 10)
    c.drawString(40, 712, 'ARGENTA')
    c.drawString(300, 712, 'VOORBEELDDATA - VERZONNEN AFSCHRIFT')
    c.setFont('Helvetica', 8)
    c.drawString(48, 680, 'DATUM')
    c.drawString(118, 680, 'DATUM')
    c.drawString(40, 670, 'TRANSACTIE')
    c.drawString(110, 670, 'VERREKENING')
    c.drawString(190, 670, 'OMSCHRIJVING')
    c.drawRightString(560, 670, 'BEDRAG (EUR)')


def rows(c, data, y):
    for row in data:
        if row == 'CARD':
            c.drawString(190, y, 'Kaartnummer : 0000-00XX-XXXX-0000')
            c.drawString(400, y, 'VOORBEELD KLANT')
        elif isinstance(row, str) and row.startswith('FX'):
            c.drawRightString(470, y, row[3:])
        elif isinstance(row, str) and row.startswith('FEE'):
            c.drawString(190, y, 'KOSTEN OP GELDOPNEMING')
            c.drawRightString(560, y, row.split()[1])
        else:
            d1, d2, desc, fx, amt = row
            c.drawString(40, y, d1)
            c.drawString(110, y, d2)
            c.drawString(190, y, desc)
            if fx:
                c.drawRightString(460, y, fx)
            c.drawRightString(560, y, amt)
        y -= 14
    return y


c = canvas.Canvas(OUT, pagesize=A4)
c.setTitle('Voorbeelddata Argenta kredietkaart')
header(c, 1, 2)
c.drawString(190, 640, 'Vorig saldo van 05/10/2026')
c.drawRightString(560, 640, fmt(PREV))
rows(c, PAGE1, 620)
c.showPage()
header(c, 2, 2)
y = rows(c, PAGE2, 640)
c.drawString(40, y - 14, 'Nieuw Saldo')
c.drawRightString(560, y - 14, fmt(total()))
c.drawString(40, y - 28, 'Betaling door uw financiële instelling')
c.save()
print(OUT, 'nieuw saldo', fmt(total()))
