// ============================================================================
// AbiRechner.swift – die komplette Rechenlogik (NRW, APO-GOSt, vereinfacht)
//
// Diese Datei weiß NICHTS von der Oberfläche. Sie bekommt einen "Stand"
// (Fächer, Prüfungen, Einstellungen) und liefert ein "Ergebnis" zurück.
// Die Web-App (web/calc.js) macht Schritt für Schritt dasselbe.
// Beide werden mit shared/testcases.json geprüft.
//
// Alle Noten sind Punkte von 0 bis 15. Abi-Schnitte werden als "Zehntel"
// gespeichert (13 bedeutet 1,3), damit es keine Rundungsfehler gibt.
// ============================================================================

import Foundation

// MARK: - Ergebnis-Typen

/// Ein Halbjahr eines Fachs im Ergebnis.
public struct KursErgebnis: Equatable, Sendable {
    /// Findet das Halbjahr für dieses Fach statt?
    public var belegt: Bool
    /// Echte Note oder Prognose (nil, wenn nicht belegt)
    public var wert: Int?
    /// true = hochgerechnet, false = echte Note
    public var istPrognose: Bool
    /// Zählt dieser Kurs in Block I?
    public var eingebracht: Bool
}

public struct FachErgebnis: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    /// Immer 4 Einträge: Q1.1, Q1.2, Q2.1, Q2.2
    public var kurse: [KursErgebnis]
    /// Durchschnitt der belegten Halbjahre in Zehnteln (128 = 12,8)
    public var schnittZehntel: Int?
    public var schnittIstPrognose: Bool
}

public struct PruefungErgebnis: Equatable, Identifiable, Sendable {
    public var abifach: Int
    public var fachId: String?
    public var fachName: String?
    public var istLK: Bool
    public var muendlich: Bool
    public var wert: Int
    public var istPrognose: Bool
    /// wert × 5 = Punkte in Block II
    public var punkte: Int

    public var id: Int { abifach }
}

public struct Bedingung: Equatable, Identifiable, Sendable {
    public var nummer: Int
    public var text: String
    public var erfuellt: Bool

    public var id: Int { nummer }
}

public enum AbiStatus: String, Equatable, Sendable {
    /// Alles in Ordnung, es gibt eine Note
    case ok
    /// Mindestens eine Bedingung ist verletzt
    case bedingungen
    /// Unter 300 Punkten
    case nichtBestanden
}

public enum ZielStatus: String, Equatable, Sendable {
    case erreichbar
    case nichtErreichbar
    case sicher
}

public struct ZielErgebnis: Equatable, Sendable {
    public var zielZehntel: Int
    /// Mindestpunktzahl für die Zielnote
    public var eMin: Int
    /// So viele Punkte braucht man dafür in Block II
    public var benoetigtBlockII: Int
    public var status: ZielStatus
    /// Benötigter Prüfungsschnitt in Zehnteln (126 = 12,6), nur bei "erreichbar"
    public var schnittZehntel: Int?
}

public struct Ergebnis: Equatable, Sendable {
    /// Die aufgeräumten Daten, mit denen gerechnet wurde
    public var stand: Stand
    public var faecher: [FachErgebnis]
    public var pruefungen: [PruefungErgebnis]
    public var summeLK: Int
    public var summeGK: Int
    public var anzahlLK: Int
    public var anzahlGK: Int
    public var anzahlEingebracht: Int
    public var defizite: Int
    public var defiziteLK: Int
    public var blockI: Int
    public var blockII: Int
    public var gesamt: Int
    public var bedingungen: [Bedingung]
    public var status: AbiStatus
    /// Abi-Schnitt in Zehnteln (13 = 1,3), nil wenn es keine Note gibt
    public var noteZehntel: Int?
    /// true, solange Prognosen in der Rechnung stecken
    public var hochgerechnet: Bool
    public var ziel: ZielErgebnis
}

// MARK: - Rechner

public enum AbiRechner {
    public static let schemaVersion = 1
    public static let formatName = "abi-rechner-nrw"
    public static let halbjahre = ["Q1.1", "Q1.2", "Q2.1", "Q2.2"]
    public static let zielMin = 10 // 1,0
    public static let zielMax = 30 // 3,0
    public static let zielStandard = 13 // 1,3
    /// Prognose, wenn es noch gar keine Note gibt
    public static let fallbackNote = 10
    /// 40 Kurse = 8 LK + 32 GK
    public static let gkPlaetze = 32
    public static let bedingungsTexte = [
        "40 Kurse eingebracht, davon 8 LK",
        "Block I mindestens 200 Punkte",
        "Höchstens 8 Kurse unter 5 Punkten, davon höchstens 3 LK",
        "Kein eingebrachter Kurs mit 0 Punkten",
        "Block II mindestens 100 Punkte",
        "Mindestens 2 Prüfungen mit 5 oder mehr Punkten, davon ein LK",
    ]

    // MARK: Kleine Bausteine

    /// Kaufmännisch runden: ab ,5 wird aufgerundet (12,5 -> 13).
    public static func runde(_ wert: Double) -> Int {
        Int((wert + 0.5).rounded(.down))
    }

    /// Durchschnitt ganzer Zahlen, kaufmännisch gerundet – komplett mit ganzen Zahlen
    /// gerechnet, damit Swift und JavaScript garantiert dasselbe Ergebnis liefern.
    /// `faktor` 10 liefert den Schnitt in Zehnteln (z. B. 128 für 12,8).
    static func gerundeterSchnitt(_ werte: [Int], faktor: Int = 1) -> Int {
        let summe = werte.reduce(0, +)
        return (2 * faktor * summe + werte.count) / (2 * werte.count)
    }

    /// Block I = (Summe GK + 2 × Summe LK) × 40 / 48, kaufmännisch gerundet.
    public static func blockI(summeGK: Int, summeLK: Int) -> Int {
        // × 40 / 48 ist dasselbe wie × 5 / 6. Mit ganzen Zahlen gerechnet: (5x + 3) / 6
        ((summeGK + 2 * summeLK) * 5 + 3) / 6
    }

    /// Abi-Schnitt in Zehnteln (13 = 1,3) oder nil, wenn unter 300 Punkten (nicht bestanden).
    public static func noteZehntel(punkte: Int) -> Int? {
        if punkte < 300 { return nil }
        return max(10, (1020 - punkte) / 18)
    }

    /// Mindestpunktzahl für einen Zielschnitt (in Zehnteln).
    public static func mindestpunkte(zielZehntel: Int) -> Int {
        1003 - 18 * zielZehntel
    }

    /// Zielschnitt-Rechner: Welcher Prüfungsschnitt wird für das Ziel gebraucht?
    public static func zielRechner(blockI: Int, zielZehntel: Int) -> ZielErgebnis {
        let eMin = mindestpunkte(zielZehntel: zielZehntel)
        let benoetigt = eMin - blockI
        // Block II = Summe der 4 Prüfungen × 5 = Prüfungsschnitt × 20.
        // Schnitt in Zehnteln = benötigt / 20 × 10 = benötigt / 2, immer aufgerundet.
        let schnitt = benoetigt > 0 ? (benoetigt + 1) / 2 : 0
        var status = ZielStatus.erreichbar
        if benoetigt <= 0 {
            status = .sicher
        } else if schnitt > 150 {
            status = .nichtErreichbar
        }
        return ZielErgebnis(
            zielZehntel: zielZehntel,
            eMin: eMin,
            benoetigtBlockII: benoetigt,
            status: status,
            schnittZehntel: status == .erreichbar ? schnitt : nil
        )
    }

    /// Schulnote 1–6 zu einer Punktzahl (15–13 = 1, 12–10 = 2, …, 0 = 6).
    public static func schulnote(punkte: Int) -> Int {
        punkte <= 0 ? 6 : 5 - (punkte - 1) / 3
    }

    /// 13 -> "1,3"
    public static func zehntelText(_ zehntel: Int) -> String {
        "\(zehntel / 10),\(zehntel % 10)"
    }

    // MARK: Prognose

    /// Alle echten (eingetragenen) Noten eines Fachs in belegten Halbjahren.
    static func echteNoten(_ fach: Fach) -> [Int] {
        let belegt = fach.belegung
        return (0..<4).compactMap { i in belegt[i] ? fach.noten[i] : nil }
    }

    /// Zählt die Quartalsnote (noch) mit? Nur solange Q2.1 belegt und noch offen ist.
    static func quartalsnoteAktiv(_ fach: Fach) -> Bool {
        fach.quartalsnote != nil && fach.belegung[2] && fach.noten[2] == nil
    }

    /// Durchschnitt aller echten Noten aller Fächer (Fallback 10), kaufmännisch gerundet.
    static func gesamtSchnitt(_ faecher: [Fach]) -> Int {
        let alle = faecher.flatMap(echteNoten)
        return alle.isEmpty ? fallbackNote : gerundeterSchnitt(alle)
    }

    /// Fachschnitt = echte Noten + Quartalsnote, gerundet. nil, wenn es noch nichts gibt.
    static func fachSchnitt(_ fach: Fach) -> Int? {
        var werte = echteNoten(fach)
        if quartalsnoteAktiv(fach), let quartal = fach.quartalsnote { werte.append(quartal) }
        return werte.isEmpty ? nil : gerundeterSchnitt(werte)
    }

    /// Prognose für ein leeres Halbjahr (Regeln 1–4 aus Abschnitt 3.1).
    static func prognoseHalbjahr(_ fach: Fach, halbjahr: Int, alleSchnitt: Int) -> Int {
        if halbjahr == 2, quartalsnoteAktiv(fach), let quartal = fach.quartalsnote { return quartal } // Regel 1
        if halbjahr >= 2, let annahme = fach.annahmeQ2 { return annahme } // Regel 2 (nur Q2)
        return fachSchnitt(fach) ?? alleSchnitt // Regel 3, sonst Regel 4
    }

    /// Prognose für eine Prüfung ohne Eingabe (Regeln 2–4).
    static func prognosePruefung(_ fach: Fach?, alleSchnitt: Int) -> Int {
        guard let fach else { return alleSchnitt }
        if let annahme = fach.annahmeQ2 { return annahme }
        return fachSchnitt(fach) ?? alleSchnitt
    }

    // MARK: Die Hauptfunktion

    /// Berechnet alles, was die Oberfläche anzeigt.
    /// Der Stand darf unaufgeräumt sein – er wird zuerst normalisiert.
    public static func berechne(_ roh: Stand) -> Ergebnis {
        let stand = roh.normalisiert()
        let faecher = stand.faecher
        let alleSchnitt = gesamtSchnitt(faecher)

        // 1) Für jedes Fach die 4 Halbjahre mit echter Note oder Prognose füllen.
        var fachErgebnisse: [FachErgebnis] = faecher.map { fach in
            let belegt = fach.belegung
            let kurse: [KursErgebnis] = (0..<4).map { i in
                guard belegt[i] else {
                    return KursErgebnis(belegt: false, wert: nil, istPrognose: false, eingebracht: false)
                }
                let echt = fach.noten[i]
                return KursErgebnis(
                    belegt: true,
                    wert: echt ?? prognoseHalbjahr(fach, halbjahr: i, alleSchnitt: alleSchnitt),
                    istPrognose: echt == nil,
                    eingebracht: false
                )
            }
            return FachErgebnis(id: fach.id, name: fach.name, kurse: kurse, schnittZehntel: nil, schnittIstPrognose: false)
        }

        // 2) Block I: Welche Kurse werden eingebracht?
        //    Immer: alle LK-Kurse, Abifach 3 und 4, Profilfach, Pflichtfächer.
        struct FreierKurs {
            var f: Int
            var h: Int
            var wert: Int
        }
        var frei: [FreierKurs] = [] // GK-Kurse, die um die restlichen Plätze konkurrieren
        var pflichtGK = 0
        for (f, fach) in faecher.enumerated() {
            let immer = fach.istLK || fach.abifach >= 3 || fach.pflicht || fach.istProfilfach
            for h in 0..<4 {
                let kurs = fachErgebnisse[f].kurse[h]
                guard kurs.belegt, let wert = kurs.wert else { continue }
                if immer {
                    fachErgebnisse[f].kurse[h].eingebracht = true
                    if !fach.istLK { pflichtGK += 1 }
                } else {
                    frei.append(FreierKurs(f: f, h: h, wert: wert))
                }
            }
        }
        //    Restliche GK-Plätze mit den besten übrigen Kursen auffüllen.
        //    Bei Gleichstand gewinnt das Fach, das weiter oben steht, dann das frühere Halbjahr.
        frei.sort { a, b in
            if a.wert != b.wert { return a.wert > b.wert }
            if a.f != b.f { return a.f < b.f }
            return a.h < b.h
        }
        for kurs in frei.prefix(max(0, gkPlaetze - pflichtGK)) {
            fachErgebnisse[kurs.f].kurse[kurs.h].eingebracht = true
        }

        // 3) Summen bilden und Defizite zählen.
        var summeLK = 0
        var summeGK = 0
        var anzahlLK = 0
        var anzahlGK = 0
        var defizite = 0
        var defiziteLK = 0
        var nullKurse = 0
        var hochgerechnet = false
        for (f, fach) in faecher.enumerated() {
            let belegteWerte = fachErgebnisse[f].kurse.compactMap { $0.belegt ? $0.wert : nil }
            if !belegteWerte.isEmpty {
                fachErgebnisse[f].schnittZehntel = gerundeterSchnitt(belegteWerte, faktor: 10)
                fachErgebnisse[f].schnittIstPrognose = fachErgebnisse[f].kurse.contains { $0.belegt && $0.istPrognose }
            }
            for kurs in fachErgebnisse[f].kurse {
                guard kurs.eingebracht, let wert = kurs.wert else { continue }
                if kurs.istPrognose { hochgerechnet = true }
                if fach.istLK {
                    summeLK += wert
                    anzahlLK += 1
                } else {
                    summeGK += wert
                    anzahlGK += 1
                }
                if wert < 5 {
                    defizite += 1
                    if fach.istLK { defiziteLK += 1 }
                }
                if wert == 0 { nullKurse += 1 }
            }
        }
        let blockI = Self.blockI(summeGK: summeGK, summeLK: summeLK)

        // 4) Block II: die 4 Prüfungen, jeweils × 5.
        var pruefungen: [PruefungErgebnis] = []
        for abifach in 1...4 {
            let fach = faecher.first { $0.abifach == abifach }
            let echt = stand.pruefungen[abifach - 1]
            let wert = echt ?? prognosePruefung(fach, alleSchnitt: alleSchnitt)
            if echt == nil { hochgerechnet = true }
            pruefungen.append(PruefungErgebnis(
                abifach: abifach,
                fachId: fach?.id,
                fachName: fach?.name,
                istLK: abifach <= 2,
                muendlich: abifach == 4,
                wert: wert,
                istPrognose: echt == nil,
                punkte: wert * 5
            ))
        }
        let blockII = pruefungen.reduce(0) { $0 + $1.punkte }
        let gesamt = blockI + blockII

        // 5) Zulassungs- und Bestehensbedingungen.
        let bestandenePruefungen = pruefungen.filter { $0.wert >= 5 }
        let erfuellt = [
            anzahlLK + anzahlGK == 40 && anzahlLK == 8,
            blockI >= 200,
            defizite <= 8 && defiziteLK <= 3,
            nullKurse == 0,
            blockII >= 100,
            bestandenePruefungen.count >= 2 && bestandenePruefungen.contains { $0.istLK },
        ]
        let bedingungen = bedingungsTexte.enumerated().map { i, text in
            Bedingung(nummer: i + 1, text: text, erfuellt: erfuellt[i])
        }

        // 6) Gesamtnote.
        var status = AbiStatus.ok
        var note = noteZehntel(punkte: gesamt)
        if erfuellt.contains(false) {
            status = .bedingungen
            note = nil
        } else if note == nil {
            status = .nichtBestanden
        }

        return Ergebnis(
            stand: stand,
            faecher: fachErgebnisse,
            pruefungen: pruefungen,
            summeLK: summeLK,
            summeGK: summeGK,
            anzahlLK: anzahlLK,
            anzahlGK: anzahlGK,
            anzahlEingebracht: anzahlLK + anzahlGK,
            defizite: defizite,
            defiziteLK: defiziteLK,
            blockI: blockI,
            blockII: blockII,
            gesamt: gesamt,
            bedingungen: bedingungen,
            status: status,
            noteZehntel: note,
            hochgerechnet: hochgerechnet,
            ziel: zielRechner(blockI: blockI, zielZehntel: stand.einstellungen.zielschnittZehntel)
        )
    }
}
