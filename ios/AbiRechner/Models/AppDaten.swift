// AppDaten.swift – Einstellungen und Prüfungsnoten (es gibt genau einen Eintrag davon).

import Foundation
import SwiftData

@Model
final class AppDaten {
    /// Zielschnitt in Zehnteln: 13 bedeutet 1,3
    var zielschnittZehntel: Int = 13
    // Prüfungsnoten für Abifach 1–4 (nil = noch leer)
    var pruefung1: Int?
    var pruefung2: Int?
    var pruefung3: Int?
    var pruefung4: Int?

    init(zielschnittZehntel: Int = 13, pruefungen: [Int?] = []) {
        self.zielschnittZehntel = zielschnittZehntel
        self.pruefungen = pruefungen
    }

    /// Alle vier Prüfungsnoten als Liste.
    var pruefungen: [Int?] {
        get { [pruefung1, pruefung2, pruefung3, pruefung4] }
        set {
            pruefung1 = newValue.count > 0 ? newValue[0] : nil
            pruefung2 = newValue.count > 1 ? newValue[1] : nil
            pruefung3 = newValue.count > 2 ? newValue[2] : nil
            pruefung4 = newValue.count > 3 ? newValue[3] : nil
        }
    }

    func setzePruefung(_ abifach: Int, _ wert: Int?) {
        var liste = pruefungen
        guard (1...4).contains(abifach) else { return }
        liste[abifach - 1] = wert
        pruefungen = liste
    }
}
