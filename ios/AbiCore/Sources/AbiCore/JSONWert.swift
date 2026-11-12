// JSONWert.swift – ein beliebiger JSON-Wert.
// Damit können wir Import-Dateien lesen, auch wenn darin Unsinn steht
// (z. B. Text statt Zahl), ohne dass die App abstürzt.

import Foundation

public enum JSONWert: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case zahl(Double)
    case text(String)
    case liste([JSONWert])
    case objekt([String: JSONWert])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let wert = try? container.decode(Bool.self) {
            self = .bool(wert)
        } else if let wert = try? container.decode(Double.self) {
            self = .zahl(wert)
        } else if let wert = try? container.decode(String.self) {
            self = .text(wert)
        } else if let wert = try? container.decode([JSONWert].self) {
            self = .liste(wert)
        } else {
            self = .objekt(try container.decode([String: JSONWert].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let wert): try container.encode(wert)
        case .zahl(let wert): try container.encode(wert)
        case .text(let wert): try container.encode(wert)
        case .liste(let wert): try container.encode(wert)
        case .objekt(let wert): try container.encode(wert)
        }
    }

    /// Liest JSON-Daten. Liefert nil, wenn es kein gültiges JSON ist.
    public static func lies(_ daten: Data) -> JSONWert? {
        try? JSONDecoder().decode(JSONWert.self, from: daten)
    }

    // Bequeme Zugriffe ---------------------------------------------------

    /// Zugriff auf einen Schlüssel eines Objekts (nil, wenn es ihn nicht gibt).
    public subscript(schluessel: String) -> JSONWert? {
        if case .objekt(let inhalt) = self { return inhalt[schluessel] }
        return nil
    }

    public var alsListe: [JSONWert]? {
        if case .liste(let inhalt) = self { return inhalt }
        return nil
    }

    public var alsObjekt: [String: JSONWert]? {
        if case .objekt(let inhalt) = self { return inhalt }
        return nil
    }

    public var alsText: String? {
        if case .text(let inhalt) = self { return inhalt }
        return nil
    }

    public var alsBool: Bool? {
        if case .bool(let inhalt) = self { return inhalt }
        return nil
    }

    public var alsZahl: Double? {
        if case .zahl(let inhalt) = self, inhalt.isFinite { return inhalt }
        return nil
    }

    /// Ganze Zahl (nur wenn der Wert wirklich ganzzahlig ist).
    public var alsGanzzahl: Int? {
        guard let zahl = alsZahl, zahl == zahl.rounded(), abs(zahl) < 1_000_000_000 else { return nil }
        return Int(zahl)
    }
}
