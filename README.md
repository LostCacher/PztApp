# PztApp

Flutter-Werkzeugkasten für Prozess- und Elektrotechnik. Für Android gestaltet,
mit responsiver Weboberfläche, dunklem Theme und Lila/Pink-Akzenten.

## Starten

```sh
flutter pub get
flutter run -d chrome
```

Unter Linux bei Chromium ggf. zuvor `export CHROME_EXECUTABLE=/usr/bin/chromium`.
Android: `flutter devices`, dann `flutter run -d <device-id>`.

Die Startseite zeigt das zuletzt geöffnete Werkzeug als Direktzugriff.
Diese Auswahl wird lokal auf Android bzw. im jeweiligen Browser gespeichert.

## Werkzeuge

- Signal-Converter: 0–20 mA, 4–20 mA, 0–10 V ↔ frei skalierbarer Prozessbereich.
  Absolute Prozesswerte mit frei wählbarer Einheit, Signalwert und Prozentwert;
  Zusätzliche Eingabe als Prozent des Messbereichs; Slider für alle drei Eingaberichtungen. Auch invertierte Prozessbereiche; Über-/Unterschreitungen werden gekennzeichnet.
- Prozentrechner: Grundwert, Prozentwert und Prozentsatz.
- Pt100/Pt1000: °C ↔ Ω, Callendar-Van-Dusen, −200 bis +850 °C,
  α = 0,00385. Idealwerte ohne Leitungs-/Sensorkorrektur.
- Motor: Frequenz ↔ Drehzahl mit wählbarer Polzahl und optionalem Schlupf
  (0 ≤ s < 100 %); ohne Schlupf wird die Synchrondrehzahl berechnet.
- Drehmoment & Leistung: Drehmoment aus mechanischer Wellenleistung P₂ (kW)
  und Nenndrehzahl/Betriebsdrehzahl (U/min), oder aus U, I und Wirkungsgrad.
  DC, Wechselstrom und symmetrischer Drehstrom; bei AC zusätzlich cos φ.
  P₁ und P₂ werden getrennt ausgewiesen. Keine Berechnung des Anlaufmoments.

- Druckeinheiten: bar, mbar, Pa, hPa, kPa, MPa, psi, mWS, atm, Torr, mmHg.
- 5-Punkt-Kalibrierhelfer: Sollsignal und Prozesswert bei 0/25/50/75/100 %;
  optionale Istwerte, signierte Abweichung und Bewertung gegen eine frei vorgegebene
  Toleranz in Prozent der Messspanne.
- SPS-Rohwertskalierung: Rohwert ↔ Prozesswert, Vorlagen 0…27648, ±27648,
  12/16 Bit und freie Grenzen. Überbereiche werden kenntlich gemacht.
- Elektrische Grundlagen: DC mit sechs Kombinationen aus U, I, R und P.
  AC einphasig und symmetrischer Drehstrom mit acht Eingabepaaren aus U, I,
  |Z|, P und S, cos φ sowie induktivem/kapazitivem Lastcharakter. Stern/Dreieck,
  Außenleiter-/Strangwerte, Wirk-, Blind- und Scheinleistung, φ, |Z|, R und X.
  AC setzt sinusförmige Größen voraus. U/I sind bei Drehstrom Außenleiterwerte,
  Impedanzen gelten pro Strang, Leistungen insgesamt. cos φ = 0 ist bei U/I/Z/S
  erlaubt; bei Wirkleistung P als Eingabe muss cos φ > 0 sein.
- Hydrostatischer Füllstand: Differenzdruck ↔ Höhe mit frei wählbarer Dichte,
  g = 9,80665 m/s². Druckbezug und Gasraumdruck müssen berücksichtigt sein.
- Tankvolumen: Quader, Zylinder stehend/liegend und Kugel; Innenmaße, Füllhöhe
  mit Slider, Inhalt in m³/Liter, Gesamtvolumen und Volumenfüllgrad.
- Differenzdruck & Durchfluss: Q = Qmax × √(Δp/Δpmax), beide Richtungen,
  konstante Stoffdaten, keine doppelte Radizierung.
- Thermoelemente: alle zehn Typen der IEC 60584-1 (**A, B, C, E, J, K, N, R, S, T**),
  °C ↔ mV mit Vergleichsstellentemperatur. Acht NIST-ITS-90-Kennlinien sowie
  A/C nach BIPM/IEC. Numerische Rückrechnung aus denselben Referenzfunktionen;
  Typ B auf 250…1820 °C begrenzt. Typ K nutzt den NIST-Bereich bis 1372 °C
  (IEC 60584-1:2013 begrenzt diesen auf 1300 °C). Kennlinienbereiche sind
  keine zugesicherten Einsatz- oder Genauigkeitsbereiche konkreter Sensoren.

Alle Berechnungen laufen lokal. Dezimalpunkt und Dezimalkomma werden akzeptiert.
Ergebnisse werden auf maximal drei Nachkommastellen gerundet, Thermospannungen
auf maximal sechs Nachkommastellen in mV.

Beispiele: 12 mA bei 4–20 mA und 0–10 bar ergeben 5 bar (50 %).
50 Hz, 4 Pole und 3 % Schlupf ergeben 1455 U/min.
7,5 kW Wellenleistung bei 1450 U/min ergeben ca. 49,393 Nm.

## Struktur

- `lib/core/`: Theme und unabhängig testbare Berechnungen
- `lib/features/`: Werkzeugübersicht, Katalog, Routing und Rechner
- `lib/features/process/`, `electrical/`, `temperature/`: neue Rechner nach Gebiet
- `lib/features/basic_tool_screen.dart`: bisherige fünf Rechner
- `data/reference/`: archivierte NIST-Koeffizienten und A/C-Daten mit Quellen
- `tool/import_thermocouple_coefficients.py`: reproduzierbarer Import der Kennlinien
- `lib/widgets/`: gemeinsames Branding und Entwicklerhinweis
- `assets/branding/`: Logo als bearbeitbare SVG-Datei und PNG
- `tool/generate_branding.py`: erzeugt Android-/Web-Icons (Python + Pillow)

Neue Werkzeuge: `ToolKind` in `lib/core/tool_kind.dart` ergänzen, eine Seite
mit `CalculatorPage` anlegen, in `tool_screen.dart` routen und in
`tool_catalog.dart` registrieren. Kategorien auf der Startseite entstehen
automatisch aus dem Katalog. Zuletzt verwendet speichert die stabile Tool-ID.

## Prüfen und bauen

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

Eine spätere Veröffentlichung benötigt eine endgültige Android-Application-ID,
Release-Signierung und die jeweiligen Store-/Hosting-Einstellungen.

Kennlinienreferenz: [Analog Devices – RTD Measurement System Design Essentials](https://www.analog.com/en/resources/technical-articles/rtd-measurement-system-design-essentials.html).

Motorgrundlagen: [ABB – Motor-Typenschild und Schlupf](https://new.abb.com/news/detail/80778/how-to-read-a-nema-motor-nameplate),
[Grundfos – Leistungsfaktor und Aufnahmeleistung](https://www.grundfos.com/ie/learn/research-and-insights/power-factor),
[Danfoss – Facts Worth Knowing (Drehmoment, Leistung und Drehzahl)](https://assets.danfoss.com/documents/latest/275346/AB313939917054en-000101.pdf).

Weitere Berechnungsreferenzen:
- [NIST ITS-90 SRD 60](https://its90.nist.gov/),
  [heruntergeladene Koeffizienten](https://its90.nist.gov/downloadFiles/allcoeff.tab.txt).
  Tabellenwerte in `test/fixtures/nist_reference_points.json` stammen aus den
  separaten NIST-Tabellendateien und sind auf 0,001 mV gerundet.
- [BIPM – Thermocouple Thermometry Part 1, Appendix A (A/C)](https://www.bipm.org/documents/20126/41773843/Thermocouple_Thermometry_Part1.pdf/d23088f8-3bab-bacc-0cae-7358eb2666b4?download=true&version=2.0).
- [IEC 60584-1:2013 – erfasste Typen](https://webstore.iec.ch/en/publication/2521).
- [Endress+Hauser – Differenzdruck und Durchfluss](https://www.uk.endress.com/en/endress-hauser-group/endresshauser-at-a-glance/Endress-Hauser-UK/dp-flow).
- [Endress+Hauser – Hydrostatischer Füllstand](https://www.endress.com/en/field-instruments-overview/level-measurement/Hydrostatic-level-measurement).
- [Siemens – exemplarische Analogwertdarstellung](https://cache.industry.siemens.com/dl/files/331/109805331/att_1089308/v2/AI4xI_2_wire4to20mA_HART_manual_en_US_en-US.pdf).

AC-Leistungsbeziehungen: [Schneider Electric – Electrical Installation Guide](https://www.electrical-installation.org/enwiki/Definition_of_reactive_power).

@by LostCacher
