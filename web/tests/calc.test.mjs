// Tests für die Rechenlogik der Web-App.
// Start:  node --test web/tests/
// Liest dieselben Testfälle wie die Swift-Tests: shared/testcases.json
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import {
  berechne, runde, blockIAusSummen, noteZehntelAusPunkten, mindestpunkte, zielRechner,
  normalisiere, exportiere, importiere, schulnote, zehntelText,
} from '../calc.js';
import { STARTDATEN } from '../startdaten.js';

const shared = (datei) => JSON.parse(readFileSync(fileURLToPath(new URL(`../../shared/${datei}`, import.meta.url)), 'utf8'));
const tc = shared('testcases.json');

test('Gesamtnote aus Punkten (Pflicht-Testfälle 3.4)', () => {
  for (const fall of tc.notenFaelle) {
    assert.equal(noteZehntelAusPunkten(fall.punkte), fall.noteZehntel, `${fall.punkte} Punkte`);
    assert.equal(noteZehntelAusPunkten(fall.punkte) !== null, fall.bestanden, `${fall.punkte} bestanden?`);
  }
});

test('Mindestpunktzahl für Zielnote', () => {
  for (const fall of tc.mindestpunkte) {
    assert.equal(mindestpunkte(fall.zielZehntel), fall.eMin);
    // Gegenprobe: genau diese Punktzahl ergibt die Zielnote, ein Punkt weniger nicht mehr.
    assert.equal(noteZehntelAusPunkten(fall.eMin), fall.zielZehntel);
    if (fall.zielZehntel < 40) assert.equal(noteZehntelAusPunkten(fall.eMin - 1), fall.zielZehntel + 1);
  }
});

test('Kaufmännisches Runden', () => {
  for (const fall of tc.rundenFaelle) assert.equal(runde(fall.wert), fall.erwartet, `runde(${fall.wert})`);
});

test('Block-I-Formel', () => {
  for (const fall of tc.blockIFaelle) assert.equal(blockIAusSummen(fall.summeGK, fall.summeLK), fall.blockI);
});

test('Zielschnitt-Rechner', () => {
  for (const fall of tc.zielFaelle) {
    const z = zielRechner(fall.blockI, fall.zielZehntel);
    assert.equal(z.status, fall.status, JSON.stringify(fall));
    assert.equal(z.schnittZehntel, fall.schnittZehntel, JSON.stringify(fall));
  }
});

// Vergleicht nur die Schlüssel, die im Testfall unter "erwartet" stehen.
function pruefeSzenario(sz) {
  const daten = sz.datenDatei ? shared(sz.datenDatei) : sz.daten;
  const e = berechne(daten);
  const erw = sz.erwartet;
  for (const key of ['blockI', 'blockII', 'gesamt', 'status', 'noteZehntel', 'hochgerechnet', 'summeLK', 'summeGK', 'anzahlEingebracht', 'anzahlLK']) {
    if (key in erw) assert.equal(e[key], erw[key], key);
  }
  if (erw.bedingungen) assert.deepEqual(e.bedingungen.map((b) => b.erfuellt), erw.bedingungen, 'bedingungen');
  if (erw.ziel) for (const [k, v] of Object.entries(erw.ziel)) assert.equal(e.ziel[k], v, `ziel.${k}`);
  if (erw.pruefungen) {
    erw.pruefungen.forEach((p, i) => {
      for (const [k, v] of Object.entries(p)) assert.equal(e.pruefungen[i][k], v, `pruefung ${i + 1}.${k}`);
    });
  }
  for (const [name, k] of Object.entries(erw.kurse ?? {})) {
    const fach = e.faecher.find((f) => f.name === name);
    assert.ok(fach, `Fach ${name} fehlt`);
    if (k.werte) assert.deepEqual(fach.kurse.map((x) => x.wert), k.werte, `${name}.werte`);
    for (const feld of ['belegt', 'istPrognose', 'eingebracht']) {
      if (k[feld]) assert.deepEqual(fach.kurse.map((x) => x[feld]), k[feld], `${name}.${feld}`);
    }
  }
}

for (const sz of tc.szenarien) {
  test(`Szenario: ${sz.name} – ${sz.beschreibung}`, () => pruefeSzenario(sz));
}

test('Startdaten der Web-App ergeben die Kontrollwerte (517 / 260 / 777 / 1,3 / Ø 12,6)', () => {
  const e = berechne(STARTDATEN);
  assert.deepEqual([e.blockI, e.blockII, e.gesamt, e.noteZehntel, e.status], [517, 260, 777, 13, 'ok']);
  assert.equal(e.ziel.schnittZehntel, 126);
  assert.equal(e.anzahlEingebracht, 40);
  assert.deepEqual(e.faecher.find((f) => f.name === 'Russisch ab EF').kurse.map((k) => k.eingebracht), [true, true, true, true]);
});

test('Export und Import ergeben wieder denselben Stand', () => {
  const stand = normalisiere(shared('beispieldaten.json'));
  stand.pruefungen = [12, null, 9, 15];
  stand.faecher[0].quartalsnote = 11;
  const text = exportiere(stand, 'web', new Date('2026-11-11T10:00:00Z'));
  const zurueck = importiere(text);
  assert.equal(zurueck.ok, true);
  assert.deepEqual(zurueck.stand, stand);
  assert.equal(JSON.parse(text).schemaVersion, 1);
  assert.equal(JSON.parse(text).quelle, 'web');
});

test('Import lehnt fremde, kaputte und zu neue Dateien ab, ohne abzustürzen', () => {
  for (const text of ['', 'kein json', '[]', '42', 'null', '{}', '{"format":"anders","faecher":[]}',
    '{"format":"abi-rechner-nrw","schemaVersion":1}', '{"format":"abi-rechner-nrw","schemaVersion":2,"faecher":[]}',
    '{"format":"abi-rechner-nrw","faecher":[]}']) {
    const r = importiere(text);
    assert.equal(r.ok, false, text);
    assert.equal(typeof r.fehler, 'string');
  }
});

test('Normalisieren: höchstens ein Profilfach, jedes Abifach nur einmal, Profilfach ist Pflicht', () => {
  const s = normalisiere({ faecher: [
    { name: 'A', istProfilfach: true, abifach: 1 },
    { name: 'B', istProfilfach: true, abifach: 1, istZusatzkurs: true, nurQ1: true },
  ] });
  assert.deepEqual(s.faecher.map((f) => f.istProfilfach), [true, false]);
  assert.deepEqual(s.faecher.map((f) => f.pflicht), [true, false]);
  assert.deepEqual(s.faecher.map((f) => f.abifach), [1, 0]);
  assert.equal(s.faecher[1].nurQ1, false);
  assert.equal(s.einstellungen.zielschnittZehntel, 13);
});

test('Kein Absturz bei unsinnigen Eingaben', () => {
  for (const roh of [null, undefined, 42, 'x', [], {}, { faecher: 'nein' }, { faecher: [null, 3, {}] }, { pruefungen: {} }]) {
    const e = berechne(roh);
    assert.equal(typeof e.blockI, 'number');
    assert.ok(['ok', 'bedingungen', 'nichtBestanden'].includes(e.status));
  }
});

test('Hilfsfunktionen für die Anzeige', () => {
  assert.deepEqual([15, 13, 12, 10, 9, 7, 6, 4, 3, 1, 0].map(schulnote), [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6]);
  assert.equal(zehntelText(13), '1,3');
  assert.equal(zehntelText(126), '12,6');
});

// Austausch zwischen den Varianten: Beide Beispiel-Dateien (eine so, wie die Web-App sie
// schreibt, eine so, wie die iPhone-App sie schreibt) müssen denselben Stand ergeben.
test('Export-Dateien aus Web-App und iPhone-App werden gleich gelesen', () => {
  const web = importiere(readFileSync(fileURLToPath(new URL('../../shared/beispiel-export-web.json', import.meta.url)), 'utf8'));
  const ios = importiere(readFileSync(fileURLToPath(new URL('../../shared/beispiel-export-ios.json', import.meta.url)), 'utf8'));
  assert.equal(web.ok, true);
  assert.equal(ios.ok, true);
  assert.deepEqual(web.stand, ios.stand);
  const e = berechne(ios.stand);
  // Deutsch 10+11+14+12 = 47, Englisch 9+10+11+10 = 40 -> LK 87; GK 328
  // Block I = (328 + 174) x 5 / 6 = 418,3 -> 418; Prüfungen 14 + 10 + 11 + 11 = 46 x 5 = 230
  assert.deepEqual([e.blockI, e.blockII, e.gesamt, e.noteZehntel], [418, 230, 648, 20]);
  assert.equal(e.ziel.schnittZehntel, 113);
  assert.deepEqual(e.pruefungen.map((p) => p.wert), [14, 10, 11, 11]);
});
