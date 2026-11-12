// PunkteFeld.swift – das Eingabefeld für Punkte (0–15) mit Ziffernblock.
// Ist das Feld leer, zeigt es die Prognose kursiv und blass mit "≈" davor.

import SwiftUI

struct PunkteFeld: View {
    /// Text für VoiceOver, z. B. "Mathematik, Q1.1, Punkte"
    let label: String
    /// Hochgerechneter Wert, der im leeren Feld angezeigt wird
    var prognose: Int?
    /// Feste Breite (nil = so breit wie möglich)
    var breite: CGFloat?
    @Binding var wert: Int?

    @State private var text = ""
    @FocusState private var hatFokus: Bool

    var body: some View {
        TextField("", text: $text, prompt: platzhalter)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .focused($hatFokus)
            .frame(minHeight: 36)
            .frame(width: breite)
            .frame(maxWidth: breite == nil ? .infinity : nil)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                if hatFokus {
                    RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.accentColor, lineWidth: 2)
                }
            }
            .onAppear { text = wert.map(String.init) ?? "" }
            .onChange(of: text) { _, neu in
                // Nur Ziffern, höchstens zwei Stellen, höchstens 15.
                let ziffern = String(neu.filter { ("0"..."9").contains($0) }.prefix(2))
                let zahl = Int(ziffern).map { min(15, $0) }
                let sauber = zahl.map(String.init) ?? ""
                if sauber != neu { text = sauber }
                if zahl != wert { wert = zahl }
            }
            .onChange(of: wert) { _, neu in
                // Wert wurde von außen geändert (z. B. Import).
                let soll = neu.map(String.init) ?? ""
                if soll != text { text = soll }
            }
            .sensoryFeedback(.selection, trigger: wert) // kurzes haptisches Feedback
            .accessibilityLabel(label)
            .accessibilityValue(vorleseWert)
    }

    private var platzhalter: Text {
        Text(prognose.map { "≈\($0)" } ?? "–")
            .italic()
            .foregroundStyle(.secondary)
    }

    private var vorleseWert: String {
        if let wert { return "\(wert) Punkte" }
        if let prognose { return "leer, Prognose \(prognose) Punkte" }
        return "leer"
    }
}
