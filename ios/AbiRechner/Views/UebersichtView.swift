// UebersichtView.swift – Bereich "Übersicht":
// großer Abi-Schnitt, Punkte in Block I / II, Zielschnitt-Rechner und Zulassungs-Checkliste.

import AbiCore
import SwiftData
import SwiftUI

struct UebersichtView: View {
    let ergebnis: Ergebnis
    let daten: AppDaten?

    @State private var zeigeInfo = false
    @Environment(\.accessibilityReduceMotion) private var bewegungReduzieren
    @ScaledMetric(relativeTo: .largeTitle) private var notenGroesse: CGFloat = 84

    var body: some View {
        NavigationStack {
            List {
                if ergebnis.faecher.isEmpty {
                    willkommen
                } else {
                    inhalt
                }
            }
            .navigationTitle("Übersicht")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        zeigeInfo = true
                    } label: {
                        Label("Info und Daten", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $zeigeInfo) {
                InfoView()
            }
            .animation(bewegungReduzieren ? nil : .snappy, value: ergebnis.gesamt)
        }
    }

    // MARK: Erster Start (noch keine Fächer)

    private var willkommen: some View {
        Section {
            ContentUnavailableView {
                Label("Willkommen", systemImage: "graduationcap")
            } description: {
                Text("Hier siehst du gleich deinen Abi-Schnitt. Lade zuerst deine gesicherten Daten oder lege im Bereich Kurse deine Fächer an.")
            } actions: {
                Button("Daten importieren …") { zeigeInfo = true }
                    .buttonStyle(.borderedProminent)
            }
        } footer: {
            Text("Deine Daten bleiben auf diesem Gerät. Berechnung vereinfacht nach APO-GOSt NRW. Verbindlich ist die Berechnung deiner Schule.")
        }
    }

    // MARK: Normale Ansicht

    @ViewBuilder
    private var inhalt: some View {
                Section {
                    held
                }
                Section {
                    PunkteBalken(name: "Block I", wert: ergebnis.blockI, maximum: 600)
                    PunkteBalken(name: "Block II", wert: ergebnis.blockII, maximum: 300)
                    PunkteBalken(name: "Gesamt", wert: ergebnis.gesamt, maximum: 900)
                } header: {
                    Text("Punkte")
                } footer: {
                    Text("Block I: \(ergebnis.anzahlEingebracht) eingebrachte Kurse, davon \(ergebnis.anzahlLK) LK. Block II: 4 Prüfungen × 5.")
                }
                zielAbschnitt
                Section {
                    ForEach(ergebnis.bedingungen) { bedingung in
                        Label {
                            Text(bedingung.text)
                        } icon: {
                            Image(systemName: bedingung.erfuellt ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(bedingung.erfuellt ? Farben.gut : Farben.schlecht)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(bedingung.text): \(bedingung.erfuellt ? "erfüllt" : "nicht erfüllt")")
                    }
                } header: {
                    Text("Zulassung und Bestehen")
                } footer: {
                    Text("Berechnung vereinfacht nach APO-GOSt NRW. Verbindlich ist die Berechnung deiner Schule.")
                }
    }

    // MARK: Großer Abi-Schnitt

    private var held: some View {
        VStack(spacing: 4) {
            Text("Abi-Schnitt")
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            if let note = ergebnis.noteZehntel, ergebnis.status == .ok {
                Text(AbiRechner.zehntelText(note))
                    .font(.system(size: notenGroesse, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(bewegungReduzieren ? .identity : .numericText())
            } else {
                Text(ergebnis.status == .bedingungen ? "Bedingungen nicht erfüllt" : "Nicht bestanden")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Farben.schlecht)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
            }

            Text("\(ergebnis.gesamt) von 900 Punkten")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            if ergebnis.hochgerechnet {
                Label("hochgerechnet", systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.14), in: Capsule())
                    .padding(.top, 8)
            } else {
                Text("alle Noten eingetragen")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .foregroundStyle(Farben.gut)
                    .background(Farben.gut.opacity(0.14), in: Capsule())
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heldVorlesen)
        .sensoryFeedback(.success, trigger: ergebnis.noteZehntel)
    }

    private var heldVorlesen: String {
        switch ergebnis.status {
        case .ok:
            let note = ergebnis.noteZehntel.map(AbiRechner.zehntelText) ?? ""
            return "Abi-Schnitt \(note)\(ergebnis.hochgerechnet ? ", hochgerechnet" : ""), \(ergebnis.gesamt) von 900 Punkten"
        case .bedingungen:
            return "Bedingungen nicht erfüllt, \(ergebnis.gesamt) von 900 Punkten"
        case .nichtBestanden:
            return "Nicht bestanden, \(ergebnis.gesamt) von 900 Punkten"
        }
    }

    // MARK: Zielschnitt-Rechner

    private var zielAbschnitt: some View {
        let ziel = ergebnis.ziel
        let zielText = AbiRechner.zehntelText(ziel.zielZehntel)
        return Section {
            Picker("Mein Ziel", selection: zielBindung) {
                ForEach(AbiRechner.zielMin...AbiRechner.zielMax, id: \.self) { zehntel in
                    Text(AbiRechner.zehntelText(zehntel)).tag(zehntel)
                }
            }
            LabeledContent("Benötigter Prüfungsschnitt") {
                switch ziel.status {
                case .sicher:
                    Text("Schon sicher").foregroundStyle(Farben.gut)
                case .nichtErreichbar:
                    Text("Nicht erreichbar").foregroundStyle(Farben.schlecht)
                case .erreichbar:
                    Text("Ø \(AbiRechner.zehntelText(ziel.schnittZehntel ?? 0)) Punkte").foregroundStyle(.primary)
                }
            }
            .fontWeight(.semibold)
            .monospacedDigit()
        } header: {
            Text("Zielschnitt")
        } footer: {
            switch ziel.status {
            case .sicher:
                Text("Für \(zielText) brauchst du mindestens \(ziel.eMin) Punkte. Die hast du schon mit Block I.")
            case .nichtErreichbar:
                Text("Für \(zielText) wären \(ziel.benoetigtBlockII) Punkte in Block II nötig, möglich sind höchstens 300.")
            case .erreichbar:
                Text("Für \(zielText) brauchst du mindestens \(ziel.eMin) Punkte, davon \(ziel.benoetigtBlockII) in Block II.")
            }
        }
    }

    private var zielBindung: Binding<Int> {
        Binding(
            get: { ergebnis.ziel.zielZehntel },
            set: { daten?.zielschnittZehntel = $0 }
        )
    }
}

/// Eine Zeile mit Namen, Punktzahl und Fortschrittsbalken.
private struct PunkteBalken: View {
    let name: String
    let wert: Int
    let maximum: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                Spacer()
                Text("\(wert)").fontWeight(.semibold) + Text(" / \(maximum)").foregroundStyle(.secondary)
            }
            .monospacedDigit()
            ProgressView(value: Double(min(max(wert, 0), maximum)), total: Double(maximum))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(wert) von \(maximum) Punkten")
    }
}
