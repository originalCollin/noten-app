// Design.swift – Farben und kleine Bausteine, die mehrere Bildschirme benutzen.
// Die Akzentfarbe (Indigo) steht in Assets.xcassets/AccentColor.

import AbiCore
import SwiftUI
import UIKit

enum Farben {
    /// Orange: Leistungskurs
    static let lk = Color.orange
    /// Grün: bestanden / erfüllt
    static let gut = Color.green
    /// Rot: nicht bestanden / verletzt
    static let schlecht = Color.red
}

/// Kleine farbige Marke wie "LK" oder "Abifach 1".
struct Marke: View {
    enum Art { case lk, akzent, neutral }

    let text: String
    var art: Art = .neutral

    private var farbe: Color {
        switch art {
        case .lk: return Farben.lk
        case .akzent: return .accentColor
        case .neutral: return .secondary
        }
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundStyle(farbe)
            .background(farbe.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

extension View {
    /// Schließt die Tastatur (der Ziffernblock hat keine eigene Taste dafür).
    func tastaturSchliessen() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Blendet über der Tastatur einen "Fertig"-Knopf ein.
    func tastaturFertigKnopf() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { tastaturSchliessen() }
                    .fontWeight(.semibold)
            }
        }
    }
}

extension FachEintrag {
    var anzeigeName: String { name.isEmpty ? "Ohne Namen" : name }
}

/// Reihenfolge in den Listen: LK zuerst, dann Abifächer, dann der Rest.
func sortiertFuerAnzeige(_ faecher: [FachEintrag]) -> [FachEintrag] {
    func rang(_ fach: FachEintrag) -> Int { fach.istLK ? 0 : (fach.abifach > 0 ? 1 : 2) }
    return faecher.sorted { a, b in
        if rang(a) != rang(b) { return rang(a) < rang(b) }
        let abiA = a.abifach == 0 ? 9 : a.abifach
        let abiB = b.abifach == 0 ? 9 : b.abifach
        if abiA != abiB { return abiA < abiB }
        return a.reihenfolge < b.reihenfolge
    }
}
