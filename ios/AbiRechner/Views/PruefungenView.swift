// PruefungenView.swift – Bereich "Prüfungen": vier Karten für die Abifächer
// und die Punkte-Noten-Tabelle.

import AbiCore
import SwiftData
import SwiftUI

struct PruefungenView: View {
    let ergebnis: Ergebnis
    let daten: AppDaten?

    private static let notenTabelle: [(note: Int, punkte: String)] = [
        (1, "15–13"), (2, "12–10"), (3, "9–7"), (4, "6–4"), (5, "3–1"), (6, "0"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(ergebnis.pruefungen) { pruefung in
                    Section {
                        karte(pruefung)
                    }
                }

                Section {
                    LabeledContent("Summe der 4 Prüfungen × 5") {
                        Text("\(ergebnis.blockII) / 300").monospacedDigit()
                    }
                } header: {
                    Text("Block II")
                }

                Section {
                    HStack(spacing: 0) {
                        ForEach(Self.notenTabelle, id: \.note) { zeile in
                            VStack(spacing: 2) {
                                Text("\(zeile.note)")
                                    .font(.title3.weight(.bold))
                                Text(zeile.punkte)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Note \(zeile.note): \(zeile.punkte.replacingOccurrences(of: "–", with: " bis ")) Punkte")
                        }
                    }
                } header: {
                    Text("Punkte und Noten")
                } footer: {
                    Text("Jede Prüfungsnote zählt fünffach in Block II. Abifach 1 bis 3 werden schriftlich geprüft, Abifach 4 mündlich. Die Zuordnung der Fächer änderst du im Bereich Kurse.")
                }
            }
            .listSectionSpacing(.compact)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Prüfungen")
            .tastaturFertigKnopf()
        }
    }

    private func karte(_ pruefung: PruefungErgebnis) -> some View {
        let farbe = pruefung.istLK ? Farben.lk : Color.accentColor
        let fachName = pruefung.fachName.map { $0.isEmpty ? "Ohne Namen" : $0 } ?? "Kein Fach zugeordnet"
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("\(pruefung.abifach)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(farbe)
                    .frame(width: 34, height: 34)
                    .background(farbe.opacity(0.16), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(fachName)
                        .font(.headline)
                    Text("\(pruefung.abifach). Abifach · \(pruefung.istLK ? "LK" : "GK") · \(pruefung.muendlich ? "mündlich" : "schriftlich")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                PunkteFeld(
                    label: "Prüfungsnote \(pruefung.abifach). Abifach, \(fachName), Punkte",
                    prognose: pruefung.istPrognose ? pruefung.wert : nil,
                    breite: 68,
                    wert: Binding(
                        get: { daten?.pruefungen[pruefung.abifach - 1] },
                        set: { daten?.setzePruefung(pruefung.abifach, $0) }
                    )
                )
            }
            HStack {
                if pruefung.istPrognose {
                    Text("Prognose").italic() + Text(" · Note \(AbiRechner.schulnote(punkte: pruefung.wert))")
                } else {
                    Text("Note \(AbiRechner.schulnote(punkte: pruefung.wert))")
                }
                Spacer()
                Text("\(pruefung.istPrognose ? "≈" : "")\(pruefung.wert) × 5 = ")
                    + Text("\(pruefung.punkte)").fontWeight(.semibold).foregroundStyle(.primary)
                    + Text(" Punkte")
            }
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(pruefung.istPrognose ? "Prognose " : "")\(pruefung.wert) mal 5 ergibt \(pruefung.punkte) Punkte in Block II")
        }
        .padding(.vertical, 4)
    }
}
