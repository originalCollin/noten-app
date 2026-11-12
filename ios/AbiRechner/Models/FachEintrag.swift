// FachEintrag.swift – ein Fach, so wie es auf dem iPhone gespeichert wird (SwiftData).
// Für die Berechnung wird es in ein einfaches `Fach` aus AbiCore umgewandelt.

import AbiCore
import Foundation
import SwiftData

@Model
final class FachEintrag {
    /// Eindeutige Kennung (bleibt beim Export/Import erhalten)
    var kennung: String = ""
    var name: String = ""
    var istLK: Bool = false
    /// 0 = kein Abifach, sonst 1–4
    var abifach: Int = 0
    var istZusatzkurs: Bool = false
    var nurQ1: Bool = false
    var pflicht: Bool = false
    var istProfilfach: Bool = false
    // Die vier Halbjahresnoten (nil = noch leer)
    var q11: Int?
    var q12: Int?
    var q21: Int?
    var q22: Int?
    var annahmeQ2: Int?
    var quartalsnote: Int?
    /// Position in der Liste (wichtig, damit iPhone und Web gleich rechnen)
    var reihenfolge: Int = 0

    init(fach: Fach, reihenfolge: Int) {
        self.reihenfolge = reihenfolge
        uebernimm(fach)
    }

    /// Schreibt alle Eigenschaften eines `Fach` in diesen Eintrag.
    func uebernimm(_ fach: Fach) {
        kennung = fach.id
        name = fach.name
        istLK = fach.istLK
        abifach = fach.abifach
        istZusatzkurs = fach.istZusatzkurs
        nurQ1 = fach.nurQ1
        pflicht = fach.pflicht
        istProfilfach = fach.istProfilfach
        q11 = fach.noten.count > 0 ? fach.noten[0] : nil
        q12 = fach.noten.count > 1 ? fach.noten[1] : nil
        q21 = fach.noten.count > 2 ? fach.noten[2] : nil
        q22 = fach.noten.count > 3 ? fach.noten[3] : nil
        annahmeQ2 = fach.annahmeQ2
        quartalsnote = fach.quartalsnote
    }

    /// Dieses Fach in der Form, mit der AbiCore rechnet.
    var alsFach: Fach {
        Fach(
            id: kennung,
            name: name,
            istLK: istLK,
            abifach: abifach,
            istZusatzkurs: istZusatzkurs,
            nurQ1: nurQ1,
            pflicht: pflicht,
            istProfilfach: istProfilfach,
            noten: [q11, q12, q21, q22],
            annahmeQ2: annahmeQ2,
            quartalsnote: quartalsnote
        )
    }

    /// Note eines Halbjahrs lesen (0 = Q1.1 … 3 = Q2.2).
    func note(_ halbjahr: Int) -> Int? {
        switch halbjahr {
        case 0: return q11
        case 1: return q12
        case 2: return q21
        default: return q22
        }
    }

    /// Note eines Halbjahrs setzen (0 = Q1.1 … 3 = Q2.2).
    func setzeNote(_ halbjahr: Int, _ wert: Int?) {
        switch halbjahr {
        case 0: q11 = wert
        case 1: q12 = wert
        case 2: q21 = wert
        default: q22 = wert
        }
    }
}
