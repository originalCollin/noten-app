// ExportImport.swift – Daten als JSON-Datei sichern und wieder einlesen.
// Das Format ist dasselbe wie in der Web-App (siehe shared/export-format.md),
// deshalb lassen sich die Dateien zwischen beiden Varianten austauschen.

import Foundation

/// Warum ein Import nicht geklappt hat (mit verständlichem Text für die Anzeige).
public enum ImportFehler: Error, Equatable, Sendable, LocalizedError {
    case keinJSON
    case keineDaten
    case fremdesFormat
    case keineVersion
    case zuNeu

    public var errorDescription: String? {
        switch self {
        case .keinJSON: return "Die Datei ist keine gültige JSON-Datei."
        case .keineDaten: return "Die Datei enthält keine Abi-Rechner-Daten."
        case .fremdesFormat: return "Die Datei stammt nicht aus dem Abi-Rechner."
        case .keineVersion: return "Die Datei hat keine gültige Versionsnummer."
        case .zuNeu: return "Die Datei stammt aus einer neueren App-Version. Bitte aktualisiere die App."
        }
    }
}

public enum AbiExport {
    /// So sieht die Export-Datei aus.
    private struct Datei: Encodable {
        var format: String
        var schemaVersion: Int
        var exportiertAm: String
        var quelle: String
        var einstellungen: Einstellungen
        var pruefungen: [Int?]
        var faecher: [Fach]
    }

    /// Erzeugt den Inhalt der Export-Datei.
    public static func exportiere(_ stand: Stand, quelle: String = "ios", jetzt: Date = Date()) -> Data {
        let sauber = stand.normalisiert()
        let datumsformat = ISO8601DateFormatter()
        datumsformat.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let datei = Datei(
            format: AbiRechner.formatName,
            schemaVersion: AbiRechner.schemaVersion,
            exportiertAm: datumsformat.string(from: jetzt),
            quelle: quelle,
            einstellungen: sauber.einstellungen,
            pruefungen: sauber.pruefungen,
            faecher: sauber.faecher
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Das Kodieren dieser einfachen Daten kann nicht fehlschlagen; zur Sicherheit trotzdem ein Ersatzwert.
        return (try? encoder.encode(datei)) ?? Data("{}".utf8)
    }

    /// Liest eine Export-Datei. Stürzt nie ab, sondern liefert im Zweifel einen Fehler.
    public static func importiere(_ daten: Data) -> Result<Stand, ImportFehler> {
        guard let json = JSONWert.lies(daten) else { return .failure(.keinJSON) }
        guard json.alsObjekt != nil else { return .failure(.keineDaten) }
        guard json["format"]?.alsText == AbiRechner.formatName, json["faecher"]?.alsListe != nil else {
            return .failure(.fremdesFormat)
        }
        guard let version = json["schemaVersion"]?.alsGanzzahl, version >= 1 else {
            return .failure(.keineVersion)
        }
        guard version <= AbiRechner.schemaVersion else { return .failure(.zuNeu) }
        return .success(Stand(json: json))
    }

    public static func importiere(text: String) -> Result<Stand, ImportFehler> {
        importiere(Data(text.utf8))
    }
}
