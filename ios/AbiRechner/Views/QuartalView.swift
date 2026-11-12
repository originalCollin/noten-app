// QuartalView.swift – Bereich "Quartal": Quartalsnoten des 1. Quartals Q2.1,
// eine Zeile pro Fach, das in Q2 belegt ist.

import AbiCore
import SwiftData
import SwiftUI

struct QuartalView: View {
    let ergebnis: Ergebnis
    let faecher: [FachEintrag]

    private var faecherInQ2: [FachEintrag] {
        sortiertFuerAnzeige(faecher).filter { !$0.nurQ1 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if faecherInQ2.isEmpty {
                        Text("Kein Fach ist in Q2 belegt.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(faecherInQ2) { eintrag in
                        QuartalZeile(eintrag: eintrag, kurs: ergebnis.faecher.first { $0.id == eintrag.kennung }?.kurse[2])
                    }
                } header: {
                    Text("1. Quartal Q2.1")
                } footer: {
                    Text("Quartalsnoten ersetzen die Prognose für Q2.1, bis die Halbjahresnote da ist. Außerdem fließen sie in die Prognose für Q2.2 und die Prüfungen ein.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Quartal")
            .tastaturFertigKnopf()
        }
    }
}

private struct QuartalZeile: View {
    @Bindable var eintrag: FachEintrag
    let kurs: KursErgebnis?

    private var hinweis: String {
        if let note = eintrag.q21 { return "Q2.1 steht fest: \(note) Punkte" }
        guard let wert = kurs?.wert else { return "" }
        if eintrag.quartalsnote != nil { return "Prognose Q2.1: \(wert) Punkte (Quartalsnote)" }
        return "Prognose Q2.1: ≈\(wert) Punkte"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(eintrag.anzeigeName)
                Text(hinweis)
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            PunkteFeld(label: "\(eintrag.anzeigeName), Quartalsnote", breite: 68, wert: $eintrag.quartalsnote)
        }
    }
}
