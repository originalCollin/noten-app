# Gemeinsames Export-Format (schemaVersion 1)

Die iPhone-App und die Web-App schreiben und lesen dieselbe JSON-Datei.
Damit lassen sich Daten zwischen beiden übertragen und Backups anlegen.

Dateiname: `abi-rechner-JJJJ-MM-TT.json`

```json
{
  "format": "abi-rechner-nrw",
  "schemaVersion": 1,
  "exportiertAm": "2026-11-11T10:00:00.000Z",
  "quelle": "web",
  "einstellungen": { "zielschnittZehntel": 13 },
  "pruefungen": [null, null, null, null],
  "faecher": [
    {
      "id": "deutsch",
      "name": "Deutsch",
      "istLK": true,
      "abifach": 1,
      "istZusatzkurs": false,
      "nurQ1": false,
      "pflicht": false,
      "istProfilfach": false,
      "noten": [10, 11, null, null],
      "annahmeQ2": null,
      "quartalsnote": null
    }
  ]
}
```

| Feld | Bedeutung |
|---|---|
| `format` | Immer `abi-rechner-nrw`. Andere Dateien werden abgelehnt. |
| `schemaVersion` | Versionsnummer des Formats. Dateien mit höherer Nummer als die App kennt werden abgelehnt. |
| `exportiertAm`, `quelle` | Nur zur Information (`ios` oder `web`). Werden beim Import ignoriert. |
| `einstellungen.zielschnittZehntel` | Zielschnitt in Zehnteln: 13 bedeutet 1,3. Erlaubt: 10 bis 30. |
| `pruefungen` | 4 Prüfungsnoten für Abifach 1 bis 4, `null` = noch leer. |
| `faecher[].noten` | 4 Werte für Q1.1, Q1.2, Q2.1, Q2.2, `null` = noch leer. |
| `faecher[].abifach` | 0 = kein Abifach, sonst 1 bis 4. Abifach 4 ist die mündliche Prüfung. |

Alle Punktzahlen liegen zwischen 0 und 15.

## Was beim Einlesen automatisch korrigiert wird

Beide Varianten räumen die Daten beim Import gleich auf:

- Punkte außerhalb von 0 bis 15 werden begrenzt, Unsinn (z. B. Text) gilt als leer.
- Es gibt höchstens ein Profilfach, und jede Abifach-Nummer nur einmal (das erste Fach gewinnt).
- Ein Profilfach ist immer auch Pflichtfach.
- „Zusatzkurs“ und „nur Q1“ schließen sich aus (Zusatzkurs gewinnt).
- Fehlende Felder bekommen ihren Standardwert.
