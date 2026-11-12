# Anleitung: Abi-Rechner als App auf dein iPhone bringen

Diese Anleitung erklärt jeden Klick. Du brauchst dafür etwa 30 bis 45 Minuten,
das meiste davon ist Warten auf Downloads.

## Was du brauchst

- einen **Mac** mit macOS 14.5 (Sonoma) oder neuer
- **Xcode 16 oder neuer** (kostenlos, siehe Schritt 1)
- dein **iPhone** mit iOS 17 oder neuer und ein **USB-Kabel**
- deine **Apple-ID** (die normale, mit der du auch im App Store einkaufst – kostenlos)

> **Wichtig zu wissen:** Mit einer kostenlosen Apple-ID läuft die App nur **7 Tage**.
> Danach startet sie nicht mehr, bis du sie neu aufspielst (Schritt 7 wiederholen, dauert
> eine Minute). **Deine Noten bleiben dabei erhalten**, solange du die App nicht löschst.
> Mehr dazu ganz unten.

---

## Schritt 1: Xcode installieren

1. Öffne auf dem Mac den **App Store** (blaues Symbol mit dem „A“).
2. Tippe oben links ins Suchfeld **Xcode** ein und drücke Enter.
3. Klicke bei „Xcode“ auf **Laden** und dann auf **Installieren**.
4. Warte, bis der Download fertig ist (mehrere Gigabyte, das kann dauern).
5. Öffne Xcode einmal. Beim ersten Start fragt es, welche Plattformen du brauchst:
   Lass **iOS** angehakt und klicke auf **Download & Install**.

## Schritt 2: Das Projekt auf den Mac holen

1. Öffne im Browser die Seite deines Projekts: `https://github.com/originalCollin/noten-app`
2. Klicke auf den grünen Knopf **Code**.
3. Klicke ganz unten auf **Download ZIP**.
4. Öffne den Ordner **Downloads** und klicke doppelt auf die ZIP-Datei. Es entsteht ein Ordner `noten-app-main`.

> Steht die App noch nicht im Hauptzweig? Dann wähle vor Schritt 2.2 oben links im
> Auswahlfeld (dort steht „main“) den Zweig `claude/abi-rechner-ios-web-9wc8gh` aus.

## Schritt 3: Das Projekt in Xcode öffnen

1. Öffne den entpackten Ordner, dann den Ordner **ios**.
2. Klicke doppelt auf **AbiRechner.xcodeproj** (blaues Symbol).
3. Falls eine Frage erscheint, ob du dem Projekt vertraust: **Trust and Open** klicken.
4. Warte ein paar Sekunden, bis oben in der Mitte nichts mehr lädt.

## Schritt 4: Deine Apple-ID in Xcode eintragen

1. Klicke in der Menüleiste ganz oben auf **Xcode** und dann auf **Settings…**
2. Klicke oben auf den Reiter **Accounts**.
3. Klicke unten links auf das **+** und wähle **Apple Account** (früher „Apple ID“).
4. Melde dich mit deiner Apple-ID und deinem Passwort an.
5. Schließe das Fenster.

## Schritt 5: Dich als „Team“ auswählen (Signing)

Apple will wissen, wer die App gebaut hat. Das stellst du einmal ein:

1. Klicke in der linken Spalte ganz oben auf den blauen Eintrag **AbiRechner**.
2. Klicke in der Mitte unter **TARGETS** auf **AbiRechner**.
3. Klicke oben auf den Reiter **Signing & Capabilities**.
4. Setze den Haken bei **Automatically manage signing** (falls er fehlt).
5. Wähle bei **Team** deinen Namen mit dem Zusatz **(Personal Team)**.

Erscheint darunter in Rot „Failed to register bundle identifier“? Dann ist der Name schon
vergeben. Ändere im Feld **Bundle Identifier** den Text auf etwas Eigenes, zum Beispiel
`de.deinvorname.abirechner`, und drücke Enter.

## Schritt 6: iPhone verbinden und Entwicklermodus einschalten

1. Verbinde das iPhone per Kabel mit dem Mac und entsperre es.
2. Fragt das iPhone „Diesem Computer vertrauen?“, tippe auf **Vertrauen** und gib deinen Code ein.
3. Öffne auf dem iPhone **Einstellungen → Datenschutz & Sicherheit**.
4. Scrolle ganz nach unten und tippe auf **Entwicklermodus**.
   (Der Eintrag erscheint erst, nachdem das iPhone einmal mit Xcode verbunden war.)
5. Schalte den Entwicklermodus ein und tippe auf **Neu starten**.
6. Nach dem Neustart: entsperren, auf **Aktivieren** tippen und deinen Code eingeben.

## Schritt 7: Die App installieren

1. Klicke in Xcode oben in der Mitte auf die Geräteauswahl (rechts neben „AbiRechner“).
2. Wähle dort **dein iPhone** aus (unter „iOS Device“).
3. Klicke oben links auf den **Play-Knopf ▶** (oder drücke `Cmd + R`).
4. Beim ersten Mal bereitet Xcode das iPhone vor. Das kann einige Minuten dauern.
5. Fragt der Mac nach dem Schlüsselbund-Passwort („codesign möchte …“): Gib dein
   **Mac-Passwort** ein und klicke auf **Immer erlauben**.

Am Ende meldet Xcode eventuell, dass die App nicht gestartet werden konnte. Das ist beim
ersten Mal normal – weiter mit Schritt 8.

## Schritt 8: Dir selbst als Entwickler vertrauen

1. Öffne auf dem iPhone **Einstellungen → Allgemein → VPN & Geräteverwaltung**.
2. Tippe unter „Entwickler-App“ auf deine Apple-ID.
3. Tippe auf **„… vertrauen“** und bestätige. (Das iPhone braucht dafür kurz Internet.)
4. Tippe auf dem Home-Bildschirm auf **Abi-Rechner**. Die App startet leer.
5. Lade deine Noten: Sichere die Datei **`meine-noten.json`** (habe ich dir im Chat geschickt)
   in der App **Dateien**, tippe im Abi-Rechner auf **Daten importieren …**, dann noch einmal auf
   **Daten importieren**, wähle die Datei aus und bestätige mit **Importieren und ersetzen**.

Jetzt kannst du das Kabel abziehen.

---

## Die 7-Tage-Regel

| | Kostenlose Apple-ID | Apple-Entwicklerprogramm (99 € pro Jahr) |
|---|---|---|
| App läuft | 7 Tage | 1 Jahr |
| Erneuern | iPhone anschließen, in Xcode ▶ drücken | einmal im Jahr |
| Apps gleichzeitig | höchstens 3 pro Gerät | viele |
| Weitergabe | nur per Kabel vom Mac | auch über TestFlight und App Store |

Weil du nur ab und zu an einen Mac kommst: **Die Web-App läuft ohne Mac und ohne
Ablaufdatum** (siehe [ANLEITUNG-WEB.md](ANLEITUNG-WEB.md)). Du kannst deine Daten jederzeit
zwischen beiden übertragen.

## Daten sichern und übertragen

1. Tippe im Bereich **Übersicht** oben rechts auf das **ⓘ**.
2. **Daten exportieren** → Ort wählen (z. B. „Auf meinem iPhone“ oder iCloud Drive) → **Sichern**.
3. In der anderen Variante: **ⓘ → Daten importieren** → Datei auswählen → **Importieren und ersetzen**.

Mach am besten vor jedem Neu-Aufspielen kurz einen Export. Dann kann nichts verloren gehen.

## Die Rechen-Tests selbst ausführen (freiwillig)

Drücke in Xcode `Cmd + U`. Xcode prüft dann alle Testfälle aus `shared/testcases.json`.
Ein grüner Haken bedeutet: Alles rechnet richtig.

## Wenn etwas nicht klappt

| Problem | Lösung |
|---|---|
| Mein iPhone taucht in der Geräteauswahl nicht auf | Kabel neu einstecken, iPhone entsperren, „Vertrauen“ antippen. Ein anderes Kabel probieren. |
| „Developer Mode disabled“ | Schritt 6 wiederholen. |
| „Untrusted Developer“ auf dem iPhone | Schritt 8 wiederholen. |
| „Failed to register bundle identifier“ | Bundle Identifier ändern (Schritt 5). |
| „iOS 17.x is not installed“ | Xcode → Settings → Components → iOS herunterladen. |
| Die App startet nach einer Woche nicht mehr | 7 Tage sind um: iPhone anschließen, ▶ drücken. |
| Rote Fehler beim Bauen | Kopiere den Fehlertext und schick ihn mir – ich behebe das. |
