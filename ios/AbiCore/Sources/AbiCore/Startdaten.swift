// Startdaten.swift – der Zustand der App beim allerersten Start: leer.
// Im Code stehen bewusst keine Noten. Eigene Daten kommen über
// "Info & Daten → Daten importieren" in die App und bleiben nur auf dem Gerät.

public enum Startdaten {
    /// Ein leerer Stand: keine Fächer, keine Prüfungsnoten, Zielschnitt 1,3.
    public static var stand: Stand { Stand() }
}
