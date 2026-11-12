// Startzustand der Web-App: leer.
// Die Web-App liegt öffentlich im Internet, deshalb stehen hier bewusst KEINE Noten.
// Eigene Daten kommen über "Info & Daten → Daten importieren" in die App und bleiben
// dann nur auf dem eigenen Gerät gespeichert.
export const STARTDATEN = {
  format: 'abi-rechner-nrw',
  schemaVersion: 1,
  einstellungen: { zielschnittZehntel: 13 },
  pruefungen: [null, null, null, null],
  faecher: [],
};
