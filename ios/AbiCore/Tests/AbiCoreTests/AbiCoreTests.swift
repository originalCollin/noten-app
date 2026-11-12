// Tests für die Swift-Rechenlogik.
// Liest dieselben Testfälle wie die JavaScript-Tests: shared/testcases.json
// Start im Terminal:  swift test   (im Ordner ios/AbiCore)

import Foundation
import Testing
@testable import AbiCore

/// Zugriff auf die gemeinsamen Dateien im Ordner shared/.
enum Gemeinsam {
    static func lade(_ datei: String) throws -> JSONWert {
        // Diese Datei liegt in ios/AbiCore/Tests/AbiCoreTests – fünf Ebenen darüber ist das Projekt.
        var ordner = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { ordner.deleteLastPathComponent() }
        let url = ordner.appendingPathComponent("shared").appendingPathComponent(datei)
        return try JSONDecoder().decode(JSONWert.self, from: Data(contentsOf: url))
    }

    static func liste(_ name: String) throws -> [JSONWert] {
        try #require(try lade("testcases.json")[name]?.alsListe)
    }
}

@Test func gesamtnoteAusPunkten() throws {
    // Pflicht-Testfälle aus Abschnitt 3.4
    for fall in try Gemeinsam.liste("notenFaelle") {
        let punkte = try #require(fall["punkte"]?.alsGanzzahl)
        #expect(AbiRechner.noteZehntel(punkte: punkte) == fall["noteZehntel"]?.alsGanzzahl, "\(punkte) Punkte")
        #expect((AbiRechner.noteZehntel(punkte: punkte) != nil) == fall["bestanden"]?.alsBool, "\(punkte) bestanden?")
    }
}

@Test func mindestpunktzahlFuerZielnote() throws {
    for fall in try Gemeinsam.liste("mindestpunkte") {
        let ziel = try #require(fall["zielZehntel"]?.alsGanzzahl)
        let eMin = try #require(fall["eMin"]?.alsGanzzahl)
        #expect(AbiRechner.mindestpunkte(zielZehntel: ziel) == eMin)
        // Gegenprobe: genau diese Punktzahl ergibt die Zielnote, ein Punkt weniger nicht mehr.
        #expect(AbiRechner.noteZehntel(punkte: eMin) == ziel)
        #expect(AbiRechner.noteZehntel(punkte: eMin - 1) == ziel + 1)
    }
}

@Test func kaufmaennischesRunden() throws {
    for fall in try Gemeinsam.liste("rundenFaelle") {
        let wert = try #require(fall["wert"]?.alsZahl)
        #expect(AbiRechner.runde(wert) == fall["erwartet"]?.alsGanzzahl, "runde(\(wert))")
    }
}

@Test func blockIFormel() throws {
    for fall in try Gemeinsam.liste("blockIFaelle") {
        let gk = try #require(fall["summeGK"]?.alsGanzzahl)
        let lk = try #require(fall["summeLK"]?.alsGanzzahl)
        #expect(AbiRechner.blockI(summeGK: gk, summeLK: lk) == fall["blockI"]?.alsGanzzahl)
    }
}

@Test func zielschnittRechner() throws {
    for fall in try Gemeinsam.liste("zielFaelle") {
        let blockI = try #require(fall["blockI"]?.alsGanzzahl)
        let ziel = try #require(fall["zielZehntel"]?.alsGanzzahl)
        let ergebnis = AbiRechner.zielRechner(blockI: blockI, zielZehntel: ziel)
        #expect(ergebnis.status.rawValue == fall["status"]?.alsText, "Block I \(blockI), Ziel \(ziel)")
        #expect(ergebnis.schnittZehntel == fall["schnittZehntel"]?.alsGanzzahl, "Block I \(blockI), Ziel \(ziel)")
    }
}

/// Vergleicht nur die Schlüssel, die im Testfall unter "erwartet" stehen.
@Test func szenarien() throws {
    let alle = try Gemeinsam.liste("szenarien")
    #expect(alle.count >= 30)
    for sz in alle {
        let name = sz["name"]?.alsText ?? "?"
        let daten: JSONWert?
        if let datei = sz["datenDatei"]?.alsText {
            daten = try Gemeinsam.lade(datei)
        } else {
            daten = sz["daten"]
        }
        let e = AbiRechner.berechne(Stand(json: daten))
        let erw = try #require(sz["erwartet"])

        let zahlen: [String: Int] = [
            "blockI": e.blockI, "blockII": e.blockII, "gesamt": e.gesamt, "summeLK": e.summeLK,
            "summeGK": e.summeGK, "anzahlEingebracht": e.anzahlEingebracht, "anzahlLK": e.anzahlLK,
        ]
        for (schluessel, ist) in zahlen {
            if let soll = erw[schluessel] { #expect(soll.alsGanzzahl == ist, "\(name): \(schluessel)") }
        }
        if let soll = erw["status"] { #expect(soll.alsText == e.status.rawValue, "\(name): status") }
        if let soll = erw["noteZehntel"] { #expect(soll.alsGanzzahl == e.noteZehntel, "\(name): noteZehntel") }
        if let soll = erw["hochgerechnet"] { #expect(soll.alsBool == e.hochgerechnet, "\(name): hochgerechnet") }
        if let soll = erw["bedingungen"]?.alsListe {
            #expect(soll.map(\.alsBool) == e.bedingungen.map { Optional($0.erfuellt) }, "\(name): bedingungen")
        }

        if let ziel = erw["ziel"] {
            if let soll = ziel["status"] { #expect(soll.alsText == e.ziel.status.rawValue, "\(name): ziel.status") }
            if let soll = ziel["eMin"] { #expect(soll.alsGanzzahl == e.ziel.eMin, "\(name): ziel.eMin") }
            if let soll = ziel["zielZehntel"] { #expect(soll.alsGanzzahl == e.ziel.zielZehntel, "\(name): ziel.zielZehntel") }
            if let soll = ziel["benoetigtBlockII"] { #expect(soll.alsGanzzahl == e.ziel.benoetigtBlockII, "\(name): ziel.benoetigtBlockII") }
            if let soll = ziel["schnittZehntel"] { #expect(soll.alsGanzzahl == e.ziel.schnittZehntel, "\(name): ziel.schnittZehntel") }
        }

        for (i, soll) in (erw["pruefungen"]?.alsListe ?? []).enumerated() {
            if let wert = soll["wert"] { #expect(wert.alsGanzzahl == e.pruefungen[i].wert, "\(name): Prüfung \(i + 1) wert") }
            if let prognose = soll["istPrognose"] { #expect(prognose.alsBool == e.pruefungen[i].istPrognose, "\(name): Prüfung \(i + 1) istPrognose") }
        }

        for (fachName, soll) in erw["kurse"]?.alsObjekt ?? [:] {
            let fach = try #require(e.faecher.first { $0.name == fachName }, "\(name): Fach \(fachName) fehlt")
            if let werte = soll["werte"]?.alsListe {
                #expect(werte.map(\.alsGanzzahl) == fach.kurse.map(\.wert), "\(name): \(fachName).werte")
            }
            if let belegt = soll["belegt"]?.alsListe {
                #expect(belegt.map(\.alsBool) == fach.kurse.map { Optional($0.belegt) }, "\(name): \(fachName).belegt")
            }
            if let prognose = soll["istPrognose"]?.alsListe {
                #expect(prognose.map(\.alsBool) == fach.kurse.map { Optional($0.istPrognose) }, "\(name): \(fachName).istPrognose")
            }
            if let eingebracht = soll["eingebracht"]?.alsListe {
                #expect(eingebracht.map(\.alsBool) == fach.kurse.map { Optional($0.eingebracht) }, "\(name): \(fachName).eingebracht")
            }
        }
    }
}

@Test func appStartetLeer() {
    #expect(Startdaten.stand.faecher.isEmpty)
    #expect(Startdaten.stand.pruefungen == [nil, nil, nil, nil])
    #expect(Startdaten.stand == Stand().normalisiert())
}

@Test func exportUndImportErgebenDenselbenStand() throws {
    var stand = Stand(json: try Gemeinsam.lade("beispieldaten.json"))
    #expect(stand.faecher.count == 11)
    stand.pruefungen = [12, nil, 9, 15]
    stand.faecher[0].quartalsnote = 11
    let daten = AbiExport.exportiere(stand)
    #expect(try AbiExport.importiere(daten).get() == stand)

    let json = try #require(JSONWert.lies(daten))
    #expect(json["schemaVersion"]?.alsGanzzahl == 1)
    #expect(json["quelle"]?.alsText == "ios")
    #expect(json["format"]?.alsText == "abi-rechner-nrw")
    // Leere Werte stehen ausdrücklich als null in der Datei (wie in der Web-App).
    #expect(json["faecher"]?.alsListe?.first?["annahmeQ2"] == .null)
    #expect(json["pruefungen"]?.alsListe?[1] == .null)
}

@Test func importLehntFremdeDateienAb() {
    let kaputt = [
        "", "kein json", "[]", "42", "null", "{}", #"{"format":"anders","faecher":[]}"#,
        #"{"format":"abi-rechner-nrw","schemaVersion":1}"#,
        #"{"format":"abi-rechner-nrw","schemaVersion":2,"faecher":[]}"#,
        #"{"format":"abi-rechner-nrw","faecher":[]}"#,
    ]
    for text in kaputt {
        if case .success = AbiExport.importiere(text: text) {
            Issue.record("Import hätte scheitern müssen: \(text)")
        }
    }
    #expect(AbiExport.importiere(text: #"{"format":"abi-rechner-nrw","schemaVersion":2,"faecher":[]}"#) == .failure(.zuNeu))
}

@Test func normalisieren() {
    let stand = Stand(faecher: [
        Fach(name: "A", abifach: 1, istProfilfach: true, noten: [99, -4]),
        Fach(name: "B", abifach: 1, istZusatzkurs: true, nurQ1: true, istProfilfach: true),
    ]).normalisiert()
    #expect(stand.faecher.map(\.istProfilfach) == [true, false])
    #expect(stand.faecher.map(\.pflicht) == [true, false])
    #expect(stand.faecher.map(\.abifach) == [1, 0])
    #expect(stand.faecher[0].noten == [15, 0, nil, nil])
    #expect(stand.faecher[1].nurQ1 == false)
    #expect(stand.einstellungen.zielschnittZehntel == 13)
}

@Test func keinAbsturzBeiUnsinnigenEingaben() {
    let unsinn: [JSONWert?] = [
        nil, .null, .zahl(42), .text("x"), .liste([]), .objekt([:]),
        .objekt(["faecher": .text("nein")]),
        .objekt(["faecher": .liste([.null, .zahl(3), .objekt([:])])]),
        .objekt(["pruefungen": .objekt([:])]),
    ]
    for roh in unsinn {
        let e = AbiRechner.berechne(Stand(json: roh))
        #expect(e.blockI >= 0)
        #expect(e.pruefungen.count == 4)
    }
}

@Test func eingabeTextWirdBegrenzt() {
    #expect(AbiRechner.punkteOderLeer(text: "12") == 12)
    #expect(AbiRechner.punkteOderLeer(text: " 99 ") == 15)
    #expect(AbiRechner.punkteOderLeer(text: "-3") == 0)
    #expect(AbiRechner.punkteOderLeer(text: "12,5") == 13)
    #expect(AbiRechner.punkteOderLeer(text: "") == nil)
    #expect(AbiRechner.punkteOderLeer(text: "abc") == nil)
    #expect(AbiRechner.punkteOderLeer(text: "1.2.3") == nil)
}

@Test func hilfsfunktionenFuerDieAnzeige() {
    #expect([15, 13, 12, 10, 9, 7, 6, 4, 3, 1, 0].map(AbiRechner.schulnote) == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6])
    #expect(AbiRechner.zehntelText(13) == "1,3")
    #expect(AbiRechner.zehntelText(126) == "12,6")
}

/// Austausch zwischen den Varianten: Beide Beispiel-Dateien (eine so, wie die Web-App sie
/// schreibt, eine so, wie die iPhone-App sie schreibt) müssen denselben Stand ergeben.
@Test func exportDateienAusWebUndIosWerdenGleichGelesen() throws {
    func lies(_ datei: String) throws -> Stand {
        var ordner = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { ordner.deleteLastPathComponent() }
        let daten = try Data(contentsOf: ordner.appendingPathComponent("shared").appendingPathComponent(datei))
        return try AbiExport.importiere(daten).get()
    }
    let web = try lies("beispiel-export-web.json")
    let ios = try lies("beispiel-export-ios.json")
    #expect(web == ios)

    let e = AbiRechner.berechne(web)
    #expect(e.blockI == 418)
    #expect(e.blockII == 230)
    #expect(e.gesamt == 648)
    #expect(e.noteZehntel == 20)
    #expect(e.ziel.schnittZehntel == 113)
    #expect(e.pruefungen.map(\.wert) == [14, 10, 11, 11])

    // Was die iPhone-App selbst exportiert, liest sie identisch wieder ein.
    #expect(try AbiExport.importiere(AbiExport.exportiere(web)).get() == web)
}
