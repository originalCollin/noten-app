// Datenbank.swift – verbindet die gespeicherten Daten (SwiftData) mit der Rechenlogik (AbiCore).

import AbiCore
import Foundation
import SwiftData

@MainActor
enum Datenbank {
    /// Baut aus den gespeicherten Einträgen den "Stand", mit dem gerechnet wird.
    static func stand(faecher: [FachEintrag], daten: AppDaten?) -> Stand {
        Stand(
            einstellungen: Einstellungen(zielschnittZehntel: daten?.zielschnittZehntel ?? AbiRechner.zielStandard),
            pruefungen: daten?.pruefungen ?? [nil, nil, nil, nil],
            faecher: faecher.sorted { $0.reihenfolge < $1.reihenfolge }.map(\.alsFach)
        )
    }

    /// Legt beim allerersten Start die (leeren) Grunddaten an.
    static func stelleStartdatenSicher(in context: ModelContext) {
        let vorhanden = (try? context.fetchCount(FetchDescriptor<AppDaten>())) ?? 0
        if vorhanden == 0 {
            ersetzeAlles(durch: Startdaten.stand, in: context)
        }
    }

    /// Löscht alle Daten und schreibt den übergebenen Stand (für Import und "Alle Daten löschen").
    static func ersetzeAlles(durch roh: Stand, in context: ModelContext) {
        let stand = roh.normalisiert()
        for eintrag in (try? context.fetch(FetchDescriptor<FachEintrag>())) ?? [] {
            context.delete(eintrag)
        }
        for eintrag in (try? context.fetch(FetchDescriptor<AppDaten>())) ?? [] {
            context.delete(eintrag)
        }
        for (position, fach) in stand.faecher.enumerated() {
            context.insert(FachEintrag(fach: fach, reihenfolge: position))
        }
        context.insert(AppDaten(
            zielschnittZehntel: stand.einstellungen.zielschnittZehntel,
            pruefungen: stand.pruefungen
        ))
        try? context.save()
    }

    /// Sorgt dafür, dass es höchstens ein Profilfach und jede Abifach-Nummer nur einmal gibt.
    /// `geaendert` ist das Fach, das gerade bearbeitet wurde – es behält seine Werte.
    static func bereinigeDoppelte(nach geaendert: FachEintrag, alle: [FachEintrag]) {
        if geaendert.istProfilfach { geaendert.pflicht = true }
        if geaendert.istZusatzkurs { geaendert.nurQ1 = false }
        for anderes in alle where anderes.kennung != geaendert.kennung {
            if geaendert.istProfilfach && anderes.istProfilfach {
                anderes.istProfilfach = false
                anderes.pflicht = false
            }
            if geaendert.abifach != 0 && anderes.abifach == geaendert.abifach {
                anderes.abifach = 0
            }
        }
    }
}
