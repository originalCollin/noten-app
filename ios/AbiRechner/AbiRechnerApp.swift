// AbiRechnerApp.swift – der Startpunkt der iPhone-App.
// Hier wird die lokale Datenbank (SwiftData) eingerichtet. Beim allerersten Start ist
// die App leer; eigene Daten kommen per Eingabe oder Import hinein. Es gibt keine Cloud und keine Netzwerkzugriffe.

import SwiftData
import SwiftUI

@main
struct AbiRechnerApp: App {
    private let container: ModelContainer

    init() {
        container = Self.erzeugeContainer()
        Datenbank.stelleStartdatenSicher(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    /// Öffnet die Datenbank. Falls das (sehr unwahrscheinlich) scheitert, läuft die App
    /// mit einer Datenbank nur im Arbeitsspeicher weiter, statt abzustürzen.
    private static func erzeugeContainer() -> ModelContainer {
        if let container = try? ModelContainer(for: FachEintrag.self, AppDaten.self) {
            return container
        }
        let nurImSpeicher = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: FachEintrag.self, AppDaten.self, configurations: nurImSpeicher) {
            return container
        }
        fatalError("Die Datenbank konnte nicht angelegt werden.")
    }
}
