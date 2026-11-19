// sync.js – Synchronisierung zwischen Geräten über eine Online-Datenbank (Supabase).
//
// So funktioniert es: Beim Einrichten entsteht ein persönlicher Sync-Code
// (z. B. "K7QM-2XPA-9RTD-HW4C"). Jedes Gerät, auf dem dieser Code eingegeben wird,
// liest und schreibt denselben Datensatz. Wer den Code kennt, kann die Daten sehen –
// deshalb ist er lang und zufällig. Auf dem Server wird nur ein Hash des Codes gespeichert.
//
// Jede gespeicherte Fassung hat eine Versionsnummer. Gespeichert wird nur, wenn das Gerät
// die aktuelle Version kennt; sonst meldet der Server einen Konflikt und liefert den neuesten Stand.

const API = 'https://psvlpubujufvetchzaag.supabase.co/rest/v1/rpc/';
// Öffentlicher Schlüssel (darf im Code stehen; er erlaubt nur die beiden Sync-Funktionen).
const SCHLUESSEL = 'sb_publishable_qLwbP432g20n6hmBMR264w_HupZ6RAq';

const S_CODE = 'abi-rechner-sync-code';
const S_VERSION = 'abi-rechner-sync-version';
const S_OFFEN = 'abi-rechner-sync-offen';
const S_ZEIT = 'abi-rechner-sync-zeit';

// ----- kleine, abgesicherte Speicher-Helfer -----
const lies = (k) => { try { return localStorage.getItem(k); } catch { return null; } };
const schreib = (k, v) => {
  try {
    if (v === null || v === undefined) localStorage.removeItem(k);
    else localStorage.setItem(k, String(v));
  } catch { /* privater Modus o. Ä. */ }
};

export const syncCode = () => lies(S_CODE);
export const syncVersion = () => { const v = Number(lies(S_VERSION)); return Number.isFinite(v) && v > 0 ? v : null; };
export const hatOffeneAenderungen = () => lies(S_OFFEN) === '1';
export const letzterSync = () => lies(S_ZEIT);
export const markiereGeaendert = () => { if (syncCode()) schreib(S_OFFEN, '1'); };

export function setzeSync(code, version, offen) {
  schreib(S_CODE, code);
  schreib(S_VERSION, version);
  schreib(S_OFFEN, offen ? '1' : null);
}
export function beendeSync() {
  [S_CODE, S_VERSION, S_OFFEN, S_ZEIT].forEach((k) => schreib(k, null));
}

/** Neuer zufälliger Code, gut abzutippen (ohne 0/O, 1/I). */
export function neuerCode() {
  const zeichen = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const zufall = crypto.getRandomValues(new Uint8Array(16));
  const roh = Array.from(zufall, (b) => zeichen[b % zeichen.length]).join('');
  return roh.match(/.{4}/g).join('-');
}

/** Bringt einen eingetippten Code in die Standardform ("k7qm 2xpa…" -> "K7QM-2XPA-…"). */
export function normalisiereCode(eingabe) {
  const roh = String(eingabe ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (roh.length !== 16) return null;
  return roh.match(/.{4}/g).join('-');
}

async function rpc(name, body) {
  const antwort = await fetch(API + name, {
    method: 'POST',
    headers: { apikey: SCHLUESSEL, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!antwort.ok) throw new Error(`Server antwortet mit ${antwort.status}`);
  const zeilen = await antwort.json();
  return Array.isArray(zeilen) ? zeilen[0] ?? null : null;
}

/** Holt den Stand vom Server: { daten, version } oder null, wenn es den Code nicht gibt. */
export async function laden(code) {
  const zeile = await rpc('sync_laden', { p_code: code });
  return zeile ? { daten: zeile.daten, version: Number(zeile.version) } : null;
}

/** Speichert. Liefert { ok, daten, version }; ok=false bedeutet Konflikt (Server hat Neueres). */
export async function speichern(code, daten, basisVersion) {
  const zeile = await rpc('sync_speichern', { p_code: code, p_daten: daten, p_basis_version: basisVersion });
  if (!zeile) throw new Error('Leere Antwort');
  return { ok: zeile.ok === true, daten: zeile.daten, version: Number(zeile.version) };
}

export function merkeSyncZeit() { schreib(S_ZEIT, new Date().toISOString()); }
