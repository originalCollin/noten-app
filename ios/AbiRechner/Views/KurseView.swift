// KurseView.swift – Bereich "Kurse": alle Fächer mit ihren vier Halbjahresnoten.
// Tippen auf ein Fach öffnet das Bearbeiten-Sheet, Wischen nach links löscht es (mit Rückfrage).

import AbiCore
import SwiftData
import SwiftUI

struct KurseView: View {
    let ergebnis: Ergebnis
    let faecher: [FachEintrag]

    @Environment(\.modelContext) private var context
    @State private var bearbeitetesFach: FachEintrag?
    @State private var zeigeNeuesFach = false
    @State private var zuLoeschen: FachEintrag?

    var body: some View {
        NavigationStack {
            List {
                if faecher.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Fächer",
                        systemImage: "books.vertical",
                        description: Text("Tippe oben rechts auf +, um ein Fach hinzuzufügen.")
                    )
                } else {
                    Section {
                        ForEach(sortiertFuerAnzeige(faecher)) { eintrag in
                            FachZeile(
                                eintrag: eintrag,
                                ergebnis: ergebnis.faecher.first { $0.id == eintrag.kennung },
                                bearbeiten: { bearbeitetesFach = eintrag }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    zuLoeschen = eintrag
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    } footer: {
                        Text("Kursive Werte mit ≈ sind Prognosen. Blass dargestellte Kurse werden nicht in Block I eingebracht. Tippe auf ein Fach, um es zu bearbeiten; wische nach links, um es zu löschen.")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Kurse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        zeigeNeuesFach = true
                    } label: {
                        Label("Fach hinzufügen", systemImage: "plus")
                    }
                }
            }
            .tastaturFertigKnopf()
            .sheet(item: $bearbeitetesFach) { eintrag in
                FachBearbeitenView(eintrag: eintrag, alle: faecher)
            }
            .sheet(isPresented: $zeigeNeuesFach) {
                FachBearbeitenView(eintrag: nil, alle: faecher)
            }
            .confirmationDialog(
                "„\(zuLoeschen?.anzeigeName ?? "")“ löschen?",
                isPresented: Binding(get: { zuLoeschen != nil }, set: { if !$0 { zuLoeschen = nil } }),
                titleVisibility: .visible
            ) {
                Button("Fach löschen", role: .destructive) {
                    if let fach = zuLoeschen {
                        withAnimation { context.delete(fach) }
                    }
                    zuLoeschen = nil
                }
                Button("Abbrechen", role: .cancel) { zuLoeschen = nil }
            } message: {
                Text("Alle Noten dieses Fachs werden entfernt. Das lässt sich nicht rückgängig machen.")
            }
        }
    }
}

/// Eine Zeile der Kursliste: Name, Marken, Fachschnitt und vier Eingabefelder.
private struct FachZeile: View {
    @Bindable var eintrag: FachEintrag
    let ergebnis: FachErgebnis?
    let bearbeiten: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kopfzeile: Tippen öffnet das Bearbeiten-Sheet.
            Button(action: bearbeiten) {
                HStack(alignment: .firstTextBaseline) {
                    Text(eintrag.anzeigeName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if let schnitt = ergebnis?.schnittZehntel {
                        let prognose = ergebnis?.schnittIstPrognose == true
                        Text("Ø \(prognose ? "≈" : "")\(AbiRechner.zehntelText(schnitt))")
                            .italic(prognose)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(eintrag.anzeigeName) bearbeiten")

            marken

            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<4, id: \.self) { halbjahr in
                    halbjahrFeld(halbjahr)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var marken: some View {
        let hatMarken = eintrag.istLK || eintrag.abifach > 0 || eintrag.pflicht || eintrag.istProfilfach
            || eintrag.istZusatzkurs || eintrag.nurQ1 || eintrag.annahmeQ2 != nil
        if hatMarken {
            // Passen die Marken nicht in eine Zeile (z. B. bei großer Schrift), kann man sie seitlich schieben.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    if eintrag.istLK { Marke(text: "LK", art: .lk) }
                    if eintrag.abifach > 0 {
                        Marke(text: "Abifach \(eintrag.abifach)\(eintrag.abifach == 4 ? " · mündlich" : "")", art: .akzent)
                    }
                    if eintrag.istProfilfach {
                        Marke(text: "Profilfach", art: .akzent)
                    } else if eintrag.pflicht {
                        Marke(text: "Pflicht")
                    }
                    if eintrag.istZusatzkurs { Marke(text: "Zusatzkurs") }
                    if eintrag.nurQ1 { Marke(text: "nur Q1") }
                    if let annahme = eintrag.annahmeQ2 { Marke(text: "Annahme \(annahme)") }
                }
            }
        }
    }

    @ViewBuilder
    private func halbjahrFeld(_ halbjahr: Int) -> some View {
        let name = AbiRechner.halbjahre[halbjahr]
        let kurs = ergebnis?.kurse[halbjahr]
        let belegt = eintrag.alsFach.belegung[halbjahr]
        VStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if belegt {
                PunkteFeld(
                    label: vorleseLabel(name: name, kurs: kurs),
                    prognose: kurs?.istPrognose == true ? kurs?.wert : nil,
                    wert: Binding(
                        get: { eintrag.note(halbjahr) },
                        set: { eintrag.setzeNote(halbjahr, $0) }
                    )
                )
            } else {
                // Gesperrtes Halbjahr: kein Eingabefeld
                Text("–")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .accessibilityLabel("\(name) nicht belegt")
            }
        }
        // Nicht eingebrachte Kurse werden abgeschwächt dargestellt.
        .opacity(belegt && kurs?.eingebracht == false ? 0.38 : 1)
    }

    private func vorleseLabel(name: String, kurs: KursErgebnis?) -> String {
        var text = "\(eintrag.anzeigeName), \(name), Punkte"
        if kurs?.eingebracht == false { text += ", nicht eingebracht" }
        return text
    }
}
