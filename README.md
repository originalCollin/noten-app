# Abi-Rechner 2027 (NRW)

Berechnet und prognostiziert den Abitur-Schnitt nach den Regeln in Nordrhein-Westfalen
(APO-GOSt, vereinfacht) – als **native iPhone-App** und als **Web-App** mit identischem
Funktionsumfang.

> Die Berechnung ist vereinfacht. Verbindlich ist allein die Berechnung der Schule.

## Anleitungen

- [iPhone-App installieren](docs/ANLEITUNG-IPHONE.md) (braucht einen Mac mit Xcode)
- [Web-App online stellen und aufs iPhone bringen](docs/ANLEITUNG-WEB.md) (ohne Mac)

## Aufbau

| Ordner | Inhalt |
|---|---|
| `shared/` | Gemeinsame Testfälle (`testcases.json`), Beispieldaten, Beschreibung des Export-Formats, Icon-Vorlage |
| `ios/AbiCore/` | Rechenlogik in reinem Swift (ohne Oberfläche) mit Tests |
| `ios/AbiRechner/` | iPhone-App: SwiftUI-Bildschirme und SwiftData-Datenmodell |
| `web/` | Web-App (HTML, CSS, JavaScript, ohne Frameworks), installierbar und offline nutzbar |
| `docs/` | Schritt-für-Schritt-Anleitungen |
| `.github/workflows/` | Automatische Tests und Veröffentlichung der Web-App |

Wo steht was?

- **Rechenregeln:** `web/calc.js` und `ios/AbiCore/Sources/AbiCore/AbiRechner.swift`.
  Beide Dateien sind gleich aufgebaut und gleich kommentiert.
- **Bildschirme iPhone:** `ios/AbiRechner/Views/` (eine Datei pro Bereich).
- **Bildschirme Web:** `web/app.js` (Logik) und `web/styles.css` (Aussehen).

## Tests

Beide Varianten lesen dieselbe Datei `shared/testcases.json` und müssen dieselben
Ergebnisse liefern.

```
node --test web/tests/*.test.mjs      # JavaScript
cd ios/AbiCore && swift test          # Swift
```

Auf GitHub laufen beide Testläufe und ein Probe-Build der iPhone-App automatisch bei jeder Änderung.

## Keine Noten im Code

Beide Apps starten **leer**. Eigene Noten kommen per Eingabe oder über „Daten importieren“
hinein und bleiben nur auf dem Gerät. `shared/beispieldaten.json` enthält frei erfundene
Beispieldaten für die Tests.

## Eine Auslegung der Regeln

Sobald die echte Halbjahresnote für Q2.1 eingetragen ist, zählt die Quartalsnote nicht mehr
in den Fachschnitt (sie steckt ja schon in der Halbjahresnote).
