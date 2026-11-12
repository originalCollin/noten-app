// storage.js – speichert die Daten lokal im Browser (localStorage).
// Es wird nichts ins Internet übertragen. Alle Zugriffe sind abgesichert,
// weil der Speicher z. B. im privaten Modus gesperrt oder voll sein kann.

import { normalisiere } from './calc.js';
import { STARTDATEN } from './startdaten.js';

const SCHLUESSEL = 'abi-rechner-stand-v1';
const SCHLUESSEL_KAPUTT = 'abi-rechner-stand-kaputt';

/**
 * Lädt den gespeicherten Stand.
 * Rückgabe: { stand, hinweis } – `hinweis` ist ein Text, falls etwas schiefging.
 */
export function lade() {
  let text = null;
  try {
    text = localStorage.getItem(SCHLUESSEL);
  } catch {
    return { stand: normalisiere(STARTDATEN), hinweis: 'Der Browser erlaubt kein Speichern. Deine Eingaben gehen beim Schließen verloren.' };
  }
  if (text === null) return { stand: normalisiere(STARTDATEN), hinweis: null }; // erster Start
  try {
    const daten = JSON.parse(text);
    if (!daten || !Array.isArray(daten.faecher)) throw new Error('unbekanntes Format');
    return { stand: normalisiere(daten), hinweis: null };
  } catch {
    // Kaputte Daten nicht einfach wegwerfen, sondern zur Seite legen.
    try {
      localStorage.setItem(SCHLUESSEL_KAPUTT, text);
    } catch { /* nichts zu tun */ }
    return { stand: normalisiere(STARTDATEN), hinweis: 'Die gespeicherten Daten waren beschädigt. Es wurden die Startdaten geladen.' };
  }
}

/** Speichert den Stand. Rückgabe: true, wenn es geklappt hat. */
export function speichere(stand) {
  try {
    localStorage.setItem(SCHLUESSEL, JSON.stringify(stand));
    return true;
  } catch {
    return false;
  }
}
