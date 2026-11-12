// Modell.swift – die Daten, mit denen gerechnet wird (ohne Oberfläche, ohne Datenbank).
// Ein "Stand" ist alles zusammen: Fächer, Prüfungsnoten und Einstellungen.
// Dasselbe Format wird auch für Export/Import benutzt (siehe shared/export-format.md).

import Foundation

/// Ein Fach mit seinen vier Halbjahresnoten.
public struct Fach: Encodable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    /// Leistungskurs (true) oder Grundkurs (false)
    public var istLK: Bool
    /// 0 = kein Abifach, sonst 1–4
    public var abifach: Int
    /// Zusatzkurs: findet nur in Q2.1 und Q2.2 statt
    public var istZusatzkurs: Bool
    /// In Q2 abgewählt: findet nur in Q1.1 und Q1.2 statt
    public var nurQ1: Bool
    /// Muss immer eingebracht werden
    public var pflicht: Bool
    /// Profilfach: alle belegten Kurse müssen eingebracht werden (höchstens eins)
    public var istProfilfach: Bool
    /// Immer genau 4 Einträge: Q1.1, Q1.2, Q2.1, Q2.2 (nil = noch leer)
    public var noten: [Int?]
    /// Feste Annahme für offene Q2-Noten
    public var annahmeQ2: Int?
    /// Note aus dem 1. Quartal Q2.1
    public var quartalsnote: Int?

    public init(
        id: String = AbiRechner.neueId(),
        name: String = "",
        istLK: Bool = false,
        abifach: Int = 0,
        istZusatzkurs: Bool = false,
        nurQ1: Bool = false,
        pflicht: Bool = false,
        istProfilfach: Bool = false,
        noten: [Int?] = [nil, nil, nil, nil],
        annahmeQ2: Int? = nil,
        quartalsnote: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.istLK = istLK
        self.abifach = abifach
        self.istZusatzkurs = istZusatzkurs
        self.nurQ1 = nurQ1
        self.pflicht = pflicht
        self.istProfilfach = istProfilfach
        self.noten = noten
        self.annahmeQ2 = annahmeQ2
        self.quartalsnote = quartalsnote
    }

    /// Welche der 4 Halbjahre finden für dieses Fach statt?
    public var belegung: [Bool] {
        let q1 = !istZusatzkurs // Zusatzkurs: Q1 gesperrt
        let q2 = !nurQ1 // in Q2 abgewählt: Q2 gesperrt
        return [q1, q1, q2, q2]
    }

    // Beim Speichern schreiben wir leere Werte ausdrücklich als "null",
    // genau wie die Web-App.
    private enum Schluessel: String, CodingKey {
        case id, name, istLK, abifach, istZusatzkurs, nurQ1, pflicht, istProfilfach, noten, annahmeQ2, quartalsnote
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Schluessel.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(istLK, forKey: .istLK)
        try container.encode(abifach, forKey: .abifach)
        try container.encode(istZusatzkurs, forKey: .istZusatzkurs)
        try container.encode(nurQ1, forKey: .nurQ1)
        try container.encode(pflicht, forKey: .pflicht)
        try container.encode(istProfilfach, forKey: .istProfilfach)
        try container.encode(noten, forKey: .noten)
        try container.encode(annahmeQ2, forKey: .annahmeQ2)
        try container.encode(quartalsnote, forKey: .quartalsnote)
    }
}

public struct Einstellungen: Encodable, Equatable, Sendable {
    /// Zielschnitt in Zehnteln: 13 bedeutet 1,3
    public var zielschnittZehntel: Int

    public init(zielschnittZehntel: Int = AbiRechner.zielStandard) {
        self.zielschnittZehntel = zielschnittZehntel
    }
}

/// Alle Daten der App zusammen.
public struct Stand: Equatable, Sendable {
    public var einstellungen: Einstellungen
    /// Immer genau 4 Einträge für Abifach 1–4 (nil = noch leer)
    public var pruefungen: [Int?]
    public var faecher: [Fach]

    public init(
        einstellungen: Einstellungen = Einstellungen(),
        pruefungen: [Int?] = [nil, nil, nil, nil],
        faecher: [Fach] = []
    ) {
        self.einstellungen = einstellungen
        self.pruefungen = pruefungen
        self.faecher = faecher
    }
}

// MARK: - Daten aufräumen

extension AbiRechner {
    /// Eine neue, eindeutige Kennung für ein Fach.
    public static func neueId() -> String {
        UUID().uuidString.lowercased()
    }

    /// Begrenzt eine Punktzahl auf 0–15.
    public static func begrenze(_ punkte: Int) -> Int {
        min(15, max(0, punkte))
    }

    /// Macht aus einer Kommazahl eine Punktzahl 0–15 (kaufmännisch gerundet).
    static func punkte(aus zahl: Double) -> Int? {
        guard zahl.isFinite else { return nil }
        return Int(min(15, max(0, (zahl + 0.5).rounded(.down))))
    }

    /// Macht aus einem getippten Text eine Punktzahl 0–15 oder nil ("leer").
    /// Erlaubt sind nur einfache Zahlen wie "12", "-3" oder "12,5".
    public static func punkteOderLeer(text: String) -> Int? {
        let sauber = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var teile = sauber.split(omittingEmptySubsequences: false) { $0 == "." || $0 == "," }
        guard teile.count == 1 || teile.count == 2 else { return nil }
        if teile[0].hasPrefix("-") { teile[0] = teile[0].dropFirst() }
        let nurZiffern = teile.allSatisfy { teil in
            !teil.isEmpty && teil.allSatisfy { ("0"..."9").contains($0) }
        }
        guard nurZiffern, let zahl = Double(sauber.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return punkte(aus: zahl)
    }

    /// Macht aus einem beliebigen JSON-Wert eine Punktzahl 0–15 oder nil ("leer").
    static func punkteOderLeer(_ wert: JSONWert?) -> Int? {
        switch wert {
        case .zahl(let zahl): return punkte(aus: zahl)
        case .text(let text): return punkteOderLeer(text: text)
        default: return nil
        }
    }
}

extension Stand {
    /// Bringt die Daten in eine saubere, gültige Form:
    /// Punkte 0–15, höchstens ein Profilfach, jedes Abifach nur einmal usw.
    /// Dadurch kann die restliche App nie an kaputten Daten abstürzen.
    public func normalisiert() -> Stand {
        var vergebeneAbifaecher = Set<Int>()
        var vergebeneIds = Set<String>()
        var profilfachVergeben = false

        let saubereFaecher = faecher.map { fach -> Fach in
            var neu = fach
            neu.noten = (0..<4).map { i in
                i < fach.noten.count ? fach.noten[i].map(AbiRechner.begrenze) : nil
            }

            // Abifach: nur 1–4, und jede Nummer nur einmal (das erste Fach gewinnt).
            var abifach = (1...4).contains(fach.abifach) ? fach.abifach : 0
            if abifach != 0 && vergebeneAbifaecher.contains(abifach) { abifach = 0 }
            if abifach != 0 { vergebeneAbifaecher.insert(abifach) }
            neu.abifach = abifach

            // Höchstens ein Profilfach.
            neu.istProfilfach = fach.istProfilfach && !profilfachVergeben
            if neu.istProfilfach { profilfachVergeben = true }

            // Zusatzkurs (nur Q2) und "nur Q1" schließen sich aus.
            neu.nurQ1 = fach.nurQ1 && !fach.istZusatzkurs

            var id = fach.id.isEmpty ? AbiRechner.neueId() : fach.id
            if vergebeneIds.contains(id) { id = AbiRechner.neueId() }
            vergebeneIds.insert(id)
            neu.id = id

            neu.name = String(fach.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
            neu.pflicht = fach.pflicht || neu.istProfilfach // Profilfach ist immer Pflicht
            neu.annahmeQ2 = fach.annahmeQ2.map(AbiRechner.begrenze)
            neu.quartalsnote = fach.quartalsnote.map(AbiRechner.begrenze)
            return neu
        }

        let sauberePruefungen: [Int?] = (0..<4).map { i in
            i < pruefungen.count ? pruefungen[i].map(AbiRechner.begrenze) : nil
        }
        let ziel = min(AbiRechner.zielMax, max(AbiRechner.zielMin, einstellungen.zielschnittZehntel))

        return Stand(
            einstellungen: Einstellungen(zielschnittZehntel: ziel),
            pruefungen: sauberePruefungen,
            faecher: saubereFaecher
        )
    }

    /// Liest einen Stand aus beliebigem JSON (z. B. einer Import-Datei).
    /// Unsinnige Werte werden wie "leer" behandelt, nichts stürzt ab.
    public init(json: JSONWert?) {
        let rohFaecher = json?["faecher"]?.alsListe ?? []
        let faecher: [Fach] = rohFaecher.compactMap { roh in
            guard roh.alsObjekt != nil else { return nil }
            let rohNoten = roh["noten"]?.alsListe ?? []
            return Fach(
                id: roh["id"]?.alsText ?? "",
                name: roh["name"]?.alsText ?? "",
                istLK: roh["istLK"]?.alsBool == true,
                abifach: roh["abifach"]?.alsGanzzahl ?? 0,
                istZusatzkurs: roh["istZusatzkurs"]?.alsBool == true,
                nurQ1: roh["nurQ1"]?.alsBool == true,
                pflicht: roh["pflicht"]?.alsBool == true,
                istProfilfach: roh["istProfilfach"]?.alsBool == true,
                noten: (0..<4).map { i in
                    i < rohNoten.count ? AbiRechner.punkteOderLeer(rohNoten[i]) : nil
                },
                annahmeQ2: AbiRechner.punkteOderLeer(roh["annahmeQ2"]),
                quartalsnote: AbiRechner.punkteOderLeer(roh["quartalsnote"])
            )
        }

        let rohPruefungen = json?["pruefungen"]?.alsListe ?? []
        let pruefungen: [Int?] = (0..<4).map { i in
            i < rohPruefungen.count ? AbiRechner.punkteOderLeer(rohPruefungen[i]) : nil
        }

        var ziel = AbiRechner.zielStandard
        if let zahl = json?["einstellungen"]?["zielschnittZehntel"]?.alsZahl {
            ziel = Int(min(Double(AbiRechner.zielMax), max(Double(AbiRechner.zielMin), (zahl + 0.5).rounded(.down))))
        }

        self = Stand(
            einstellungen: Einstellungen(zielschnittZehntel: ziel),
            pruefungen: pruefungen,
            faecher: faecher
        ).normalisiert()
    }
}
