// InfoView.swift – Sheet "Info & Daten": Export, Import, Löschen und Hinweise.
// Export und Import benutzen dasselbe Dateiformat wie die Web-App.

import AbiCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct InfoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var schliessen
    @Query(sort: \FachEintrag.reihenfolge) private var faecher: [FachEintrag]
    @Query private var appDaten: [AppDaten]

    @State private var zeigeExport = false
    @State private var exportDokument = ExportDokument(daten: Data())
    @State private var zeigeImport = false
    @State private var importierterStand: Stand?
    @State private var frageZuruecksetzen = false
    @State private var meldung: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Daten exportieren") {
                        let stand = Datenbank.stand(faecher: faecher, daten: appDaten.first)
                        exportDokument = ExportDokument(daten: AbiExport.exportiere(stand, quelle: "ios"))
                        zeigeExport = true
                    }
                    .fileExporter(
                        isPresented: $zeigeExport,
                        document: exportDokument,
                        contentType: .json,
                        defaultFilename: Self.dateiname()
                    ) { ergebnis in
                        if case .failure = ergebnis { meldung = "Der Export hat nicht geklappt." }
                    }

                    Button("Daten importieren") { zeigeImport = true }
                        .fileImporter(isPresented: $zeigeImport, allowedContentTypes: [.json]) { ergebnis in
                            leseImport(ergebnis)
                        }
                } header: {
                    Text("Sicherung und Übertragung")
                } footer: {
                    Text("Die Export-Datei enthält alle Fächer, Noten und Einstellungen. Du kannst sie in der iPhone-App und in der Web-App wieder importieren.")
                }

                Section {
                    Button("Alle Daten löschen", role: .destructive) { frageZuruecksetzen = true }
                }

                Section {
                    Text("Die Berechnung ist vereinfacht nach der APO-GOSt NRW. **Verbindlich ist allein die Berechnung deiner Schule.**")
                    Text("Kursive Werte mit ≈ sind Prognosen: zuerst die Quartalsnote (nur Q2.1), dann deine Annahme für Q2, sonst der gerundete Durchschnitt deiner bisherigen Noten im Fach.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Hinweis")
                } footer: {
                    Text("Alle Daten bleiben auf diesem Gerät. Es wird nichts ins Internet übertragen. Abi-Rechner 2027 · Format-Version \(AbiRechner.schemaVersion)")
                }
            }
            .navigationTitle("Info & Daten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { schliessen() }
                }
            }
            // Rückfrage vor dem Überschreiben beim Import
            .confirmationDialog(
                "Daten überschreiben?",
                isPresented: Binding(get: { importierterStand != nil }, set: { if !$0 { importierterStand = nil } }),
                titleVisibility: .visible
            ) {
                Button("Importieren und ersetzen", role: .destructive) {
                    if let stand = importierterStand {
                        Datenbank.ersetzeAlles(durch: stand, in: context)
                        meldung = "Import abgeschlossen."
                    }
                    importierterStand = nil
                }
                Button("Abbrechen", role: .cancel) { importierterStand = nil }
            } message: {
                let anzahl = importierterStand?.faecher.count ?? 0
                Text("Die Datei enthält \(anzahl) \(anzahl == 1 ? "Fach" : "Fächer"). Deine jetzigen Daten werden vollständig ersetzt.")
            }
            .confirmationDialog("Alle Daten löschen?", isPresented: $frageZuruecksetzen, titleVisibility: .visible) {
                Button("Alle Daten löschen", role: .destructive) {
                    Datenbank.ersetzeAlles(durch: Startdaten.stand, in: context)
                    meldung = "Alle Daten gelöscht."
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Fächer, Noten und Prüfungen werden von diesem Gerät entfernt. Exportiere sie vorher, wenn du sie behalten willst.")
            }
            .alert(meldung ?? "", isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) {
                Button("OK", role: .cancel) { meldung = nil }
            }
        }
    }

    /// Liest die gewählte Datei und fragt danach, ob überschrieben werden soll.
    private func leseImport(_ ergebnis: Result<URL, Error>) {
        guard case .success(let url) = ergebnis else {
            if case .failure = ergebnis { meldung = "Die Datei konnte nicht geöffnet werden." }
            return
        }
        // Dateien aus der Dateien-App müssen ausdrücklich "geöffnet" werden.
        let zugriff = url.startAccessingSecurityScopedResource()
        defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
        guard let daten = try? Data(contentsOf: url) else {
            meldung = "Die Datei konnte nicht gelesen werden."
            return
        }
        switch AbiExport.importiere(daten) {
        case .success(let stand):
            importierterStand = stand
        case .failure(let fehler):
            meldung = fehler.errorDescription ?? "Die Datei konnte nicht importiert werden."
        }
    }

    private static func dateiname() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        format.locale = Locale(identifier: "en_US_POSIX")
        return "abi-rechner-\(format.string(from: Date()))"
    }
}

/// Die Export-Datei als "Dokument", damit iOS den Sichern-Dialog anzeigen kann.
struct ExportDokument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    var daten: Data

    init(daten: Data) {
        self.daten = daten
    }

    init(configuration: ReadConfiguration) throws {
        daten = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: daten)
    }
}
