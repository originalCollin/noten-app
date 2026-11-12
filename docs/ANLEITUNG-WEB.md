# Anleitung: Abi-Rechner als Web-App aufs iPhone bringen

Die Web-App läuft **ohne Mac**, **ohne Ablaufdatum** und nach dem ersten Öffnen auch
**ohne Internet**. Du öffnest sie einmal in Safari und legst sie auf den Home-Bildschirm.
Danach sieht sie aus und verhält sich wie eine normale App.

Alles in dieser Anleitung geht im Browser – du brauchst kein Terminal.

> **Deine Noten und die Öffentlichkeit:** Kostenloses GitHub Pages geht nur mit einem
> **öffentlichen** Repository. Im Code stehen deshalb **keine Noten** – nur frei erfundene
> Beispieldaten für die Tests. Beide Apps starten leer. Was du eintippst oder importierst,
> bleibt nur auf deinem Gerät.

---

## Teil A: Die Web-App online stellen (einmalig, ca. 10 Minuten)

### Schritt 1: Die App in den Hauptzweig übernehmen

Die App liegt zuerst in einem Arbeitszweig. GitHub Pages veröffentlicht nur den Hauptzweig „main“.

1. Öffne `https://github.com/originalCollin/noten-app`
2. Klicke oben auf **Pull requests** und dann auf den grünen Knopf **New pull request**.
3. Wähle bei **compare** den Zweig `claude/abi-rechner-ios-web-9wc8gh`.
4. Klicke auf **Create pull request** und noch einmal auf **Create pull request**.
5. Klicke auf **Merge pull request** und dann auf **Confirm merge**.

(Du kannst mich auch einfach bitten, den Pull Request für dich anzulegen.)

### Schritt 2: Repository öffentlich machen (falls es privat ist)

1. Klicke oben auf **Settings** (Zahnrad).
2. Scrolle ganz nach unten zum roten Bereich **Danger Zone**.
3. Klicke bei „Change repository visibility“ auf **Change visibility → Change to public**.
4. Folge den Bestätigungen (GitHub fragt mehrfach nach).

### Schritt 3: GitHub Pages einschalten

1. Bleib in **Settings** und klicke links in der Liste auf **Pages**.
2. Wähle unter **Build and deployment** bei **Source** den Eintrag **GitHub Actions**.

### Schritt 4: Veröffentlichung starten

1. Klicke oben auf **Actions**.
2. Klicke links auf **Web-App veröffentlichen**.
3. Klicke rechts auf **Run workflow** und im Aufklappmenü noch einmal auf **Run workflow**.
4. Warte etwa eine Minute, bis ein **grüner Haken** erscheint.

Deine Web-App ist jetzt erreichbar unter:

**`https://originalcollin.github.io/noten-app/`**

Ab jetzt wird sie automatisch aktualisiert, sobald sich im Hauptzweig etwas am Ordner `web/` ändert.

---

## Teil B: Auf dem iPhone installieren (2 Minuten)

1. Öffne auf dem iPhone **Safari** (es muss Safari sein, nicht Chrome).
2. Gib die Adresse ein: `https://originalcollin.github.io/noten-app/`
3. Tippe unten in der Mitte auf das **Teilen-Symbol** (Quadrat mit Pfeil nach oben).
4. Scrolle in der Liste nach unten und tippe auf **Zum Home-Bildschirm**.
5. Tippe oben rechts auf **Hinzufügen**.

Auf dem Home-Bildschirm liegt jetzt das Symbol **Abi-Rechner**. Tippst du es an, öffnet sich
die App im Vollbild ohne Safari-Leisten. Sie funktioniert ab sofort auch im Flugmodus.

### Deine Noten in die Web-App laden

Die Web-App startet leer. So kommen deine Noten hinein:

1. Sichere die Datei **`meine-noten.json`** (habe ich dir im Chat geschickt) auf dem iPhone
   in der App **Dateien**. Alternativ: in der iPhone-App **ⓘ → Daten exportieren**.
2. Öffne den Abi-Rechner vom Home-Bildschirm und tippe auf **Daten importieren …**
3. Tippe im Sheet noch einmal auf **Daten importieren** und wähle die Datei aus.
4. Bestätige mit **Importieren und ersetzen**.

> Die App vom Home-Bildschirm und die Seite in Safari haben **getrennte Daten**.
> Trage deine Noten deshalb in der App vom Home-Bildschirm ein.

---

## Teil C: Daten zwischen Web-App und iPhone-App übertragen

Beide Varianten benutzen dieselbe Datei (`abi-rechner-JJJJ-MM-TT.json`).

### Exportieren (in beiden Varianten gleich)

1. Tippe im Bereich **Übersicht** oben rechts auf das **ⓘ**.
2. Tippe auf **Daten exportieren**.
3. Wähle **In Dateien sichern**, such dir einen Ort aus und tippe auf **Sichern**.

### Importieren (in beiden Varianten gleich)

1. Tippe im Bereich **Übersicht** oben rechts auf das **ⓘ**.
2. Tippe auf **Daten importieren** und wähle die gesicherte Datei aus.
3. Die App zeigt, wie viele Fächer in der Datei stehen, und fragt nach.
   Tippe auf **Importieren und ersetzen**.

**Tipp:** Mach nach jeder Zeugnis- oder Quartalsnote einen Export. Das ist zugleich dein Backup.

---

## Gut zu wissen

- **Speicherort:** Die Noten liegen nur im Speicher des Browsers auf deinem iPhone.
  Löschst du die App vom Home-Bildschirm oder die Website-Daten in den Safari-Einstellungen,
  sind sie weg. Deshalb: regelmäßig exportieren.
- **Updates:** Öffne die App nach einer Aktualisierung zweimal. Beim ersten Öffnen lädt sie
  die neue Version im Hintergrund, beim zweiten zeigt sie sie an.
- **Textgröße und Dunkelmodus:** Die Web-App folgt den iPhone-Einstellungen automatisch.

## Wenn etwas nicht klappt

| Problem | Lösung |
|---|---|
| Unter **Settings → Pages** steht, Pages sei nicht verfügbar | Das Repository ist noch privat (Schritt 2). |
| Roter Fehler bei **Actions** | Prüfe, ob bei Pages als Source **GitHub Actions** gewählt ist (Schritt 3). Sonst schick mir den Fehlertext. |
| Die Adresse zeigt „404“ | Ein bis zwei Minuten warten und neu laden. |
| „Zum Home-Bildschirm“ fehlt | Du bist nicht in Safari, oder du musst in der Teilen-Liste weiter nach unten scrollen. |
| Die App zeigt alte Daten | Du hast sie einmal in Safari und einmal vom Home-Bildschirm geöffnet – das sind getrennte Speicher. Per Export/Import übertragen. |
