// FachBearbeitenView.swift – Sheet zum Anlegen und Bearbeiten eines Fachs.
// Gearbeitet wird auf einer Kopie ("entwurf"). Erst "Fertig" übernimmt die Änderungen,
// "Abbrechen" verwirft sie.

import AbiCore
import SwiftData
import SwiftUI

struct FachBearbeitenView: View {
    /// Das bearbeitete Fach – nil bedeutet: ein neues Fach anlegen
    let eintrag: FachEintrag?
    let alle: [FachEintrag]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var schliessen
    @State private var entwurf: Fach
    @State private var frageLoeschen = false
    @FocusState private var nameHatFokus: Bool

    private enum Belegung: Hashable { case alle, nurQ1, zusatzkurs }

    init(eintrag: FachEintrag?, alle: [FachEintrag]) {
        self.eintrag = eintrag
        self.alle = alle
        _entwurf = State(initialValue: eintrag?.alsFach ?? Fach())
    }

    private var istNeu: Bool { eintrag == nil }
    private var nameIstLeer: Bool { entwurf.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Ein anderes Fach, das diese Abifach-Nummer bisher hat.
    private func bisherigesAbifach(_ nummer: Int) -> FachEintrag? {
        alle.first { $0.abifach == nummer && $0.kennung != entwurf.id }
    }

    private var bisherigesProfilfach: FachEintrag? {
        alle.first { $0.istProfilfach && $0.kennung != entwurf.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, z. B. Chemie", text: $entwurf.name)
                        .focused($nameHatFokus)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .accessibilityLabel("Name des Fachs")
                    Picker("Kursart", selection: $entwurf.istLK) {
                        Text("Grundkurs").tag(false)
                        Text("Leistungskurs").tag(true)
                    }
                    .pickerStyle(.segmented)
                    Picker("Abiturfach", selection: $entwurf.abifach) {
                        Text("Kein Abifach").tag(0)
                        ForEach(1...4, id: \.self) { nummer in
                            Text("\(nummer). Abifach\(nummer == 4 ? " (mündlich)" : "")").tag(nummer)
                        }
                    }
                } footer: {
                    if entwurf.abifach > 0, let anderes = bisherigesAbifach(entwurf.abifach) {
                        Text("\(anderes.anzeigeName) ist dann kein Abifach mehr.")
                    }
                }

                Section {
                    Picker("Belegung", selection: belegungBindung) {
                        Text("Q1 und Q2").tag(Belegung.alle)
                        Text("Nur Q1").tag(Belegung.nurQ1)
                        Text("Zusatzkurs").tag(Belegung.zusatzkurs)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Belegung")
                } footer: {
                    Text("„Nur Q1“: in Q2 abgewählt. „Zusatzkurs“: findet nur in Q2.1 und Q2.2 statt.")
                }

                Section {
                    Toggle("Profilfach", isOn: profilBindung)
                    Toggle("Immer einbringen (Pflicht)", isOn: pflichtBindung)
                        .disabled(entwurf.istProfilfach) // Profilfach ist immer Pflicht
                } header: {
                    Text("Einbringung")
                } footer: {
                    if entwurf.istProfilfach {
                        if let anderes = bisherigesProfilfach {
                            Text("Beim Profilfach werden alle belegten Kurse eingebracht. \(anderes.anzeigeName) ist dann kein Profilfach mehr.")
                        } else {
                            Text("Beim Profilfach werden alle belegten Kurse eingebracht.")
                        }
                    } else {
                        Text("Es gibt höchstens ein Profilfach. Alle seine belegten Kurse werden eingebracht.")
                    }
                }

                Section("Noten (0–15 Punkte)") {
                    ForEach(0..<4, id: \.self) { halbjahr in
                        if entwurf.belegung[halbjahr] {
                            LabeledContent(AbiRechner.halbjahre[halbjahr]) {
                                PunkteFeld(
                                    label: "\(AbiRechner.halbjahre[halbjahr]), Punkte",
                                    breite: 68,
                                    wert: $entwurf.noten[halbjahr]
                                )
                            }
                        }
                    }
                }

                if entwurf.belegung[2] {
                    Section {
                        LabeledContent("Annahme für offene Q2-Noten") {
                            PunkteFeld(label: "Annahme für offene Q2-Noten, Punkte", breite: 68, wert: $entwurf.annahmeQ2)
                        }
                        LabeledContent("Quartalsnote Q2.1") {
                            PunkteFeld(label: "Quartalsnote Q2.1, Punkte", breite: 68, wert: $entwurf.quartalsnote)
                        }
                    } header: {
                        Text("Prognose")
                    } footer: {
                        Text("Leer lassen, damit die App aus deinen bisherigen Noten hochrechnet.")
                    }
                }

                if !istNeu {
                    Section {
                        Button("Fach löschen", role: .destructive) { frageLoeschen = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(istNeu ? "Neues Fach" : "Fach bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { schliessen() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(istNeu ? "Hinzufügen" : "Fertig") { speichern() }
                        .disabled(nameIstLeer)
                }
            }
            .tastaturFertigKnopf()
            .confirmationDialog("„\(eintrag?.anzeigeName ?? "")“ löschen?", isPresented: $frageLoeschen, titleVisibility: .visible) {
                Button("Fach löschen", role: .destructive) {
                    if let eintrag { context.delete(eintrag) }
                    schliessen()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Noten dieses Fachs werden entfernt. Das lässt sich nicht rückgängig machen.")
            }
            .onAppear { if istNeu { nameHatFokus = true } }
            .sensoryFeedback(.selection, trigger: entwurf.istProfilfach)
        }
    }

    // MARK: Bindungen für zusammengesetzte Eigenschaften

    private var belegungBindung: Binding<Belegung> {
        Binding(
            get: { entwurf.istZusatzkurs ? .zusatzkurs : (entwurf.nurQ1 ? .nurQ1 : .alle) },
            set: { neu in
                entwurf.istZusatzkurs = neu == .zusatzkurs
                entwurf.nurQ1 = neu == .nurQ1
            }
        )
    }

    private var profilBindung: Binding<Bool> {
        Binding(
            get: { entwurf.istProfilfach },
            set: { neu in
                entwurf.istProfilfach = neu
                entwurf.pflicht = neu // Profilfach setzt Pflicht automatisch
            }
        )
    }

    private var pflichtBindung: Binding<Bool> {
        Binding(
            get: { entwurf.pflicht || entwurf.istProfilfach },
            set: { entwurf.pflicht = $0 }
        )
    }

    // MARK: Speichern

    private func speichern() {
        guard !nameIstLeer else { return }
        let ziel: FachEintrag
        if let eintrag {
            eintrag.uebernimm(entwurf)
            ziel = eintrag
        } else {
            let naechstePosition = (alle.map(\.reihenfolge).max() ?? -1) + 1
            ziel = FachEintrag(fach: entwurf, reihenfolge: naechstePosition)
            context.insert(ziel)
        }
        ziel.name = String(entwurf.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        // Es gibt nur ein Profilfach und jedes Abifach nur einmal: das bearbeitete Fach gewinnt.
        Datenbank.bereinigeDoppelte(nach: ziel, alle: alle)
        schliessen()
    }
}
