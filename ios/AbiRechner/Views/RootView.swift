// RootView.swift – die Tab-Leiste mit den vier Bereichen.
// Hier wird bei jeder Änderung der Daten sofort neu gerechnet; alle Bereiche
// bekommen dasselbe Ergebnis und zeigen es live an.

import AbiCore
import SwiftData
import SwiftUI

struct RootView: View {
    @Query(sort: \FachEintrag.reihenfolge) private var faecher: [FachEintrag]
    @Query private var appDaten: [AppDaten]

    var body: some View {
        // Die komplette Berechnung – sie ist so schnell, dass sie bei jeder Eingabe neu läuft.
        let ergebnis = AbiRechner.berechne(Datenbank.stand(faecher: faecher, daten: appDaten.first))

        TabView {
            UebersichtView(ergebnis: ergebnis, daten: appDaten.first)
                .tabItem { Label("Übersicht", systemImage: "graduationcap") }
            KurseView(ergebnis: ergebnis, faecher: faecher)
                .tabItem { Label("Kurse", systemImage: "list.bullet") }
            QuartalView(ergebnis: ergebnis, faecher: faecher)
                .tabItem { Label("Quartal", systemImage: "calendar") }
            PruefungenView(ergebnis: ergebnis, daten: appDaten.first)
                .tabItem { Label("Prüfungen", systemImage: "square.and.pencil") }
        }
    }
}
