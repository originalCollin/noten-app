// ============================================================================
// calc.js – die komplette Rechenlogik des Abi-Rechners (NRW, APO-GOSt, vereinfacht)
//
// Diese Datei weiß NICHTS von der Oberfläche. Sie bekommt einen "Stand"
// (Fächer, Prüfungen, Einstellungen) und liefert ein Ergebnis zurück.
// Die Swift-Variante (ios/AbiCore/Sources/AbiCore/AbiRechner.swift) macht
// Schritt für Schritt dasselbe. Beide werden mit shared/testcases.json geprüft.
//
// Alle Noten sind Punkte von 0 bis 15. Abi-Schnitte werden als "Zehntel"
// gespeichert (13 bedeutet 1,3), damit es keine Rundungsfehler gibt.
// ============================================================================

export const SCHEMA_VERSION = 1;
export const FORMAT_NAME = 'abi-rechner-nrw';
export const HALBJAHRE = ['Q1.1', 'Q1.2', 'Q2.1', 'Q2.2'];
export const ZIEL_MIN = 10; // 1,0
export const ZIEL_MAX = 30; // 3,0
export const ZIEL_STANDARD = 13; // 1,3
export const FALLBACK_NOTE = 10; // Prognose, wenn es noch gar keine Note gibt
export const GK_PLAETZE = 32; // 40 Kurse = 8 LK + 32 GK
export const BEDINGUNGEN = [
  '40 Kurse eingebracht, davon 8 LK',
  'Block I mindestens 200 Punkte',
  'Höchstens 8 Kurse unter 5 Punkten, davon höchstens 3 LK',
  'Kein eingebrachter Kurs mit 0 Punkten',
  'Block II mindestens 100 Punkte',
  'Mindestens 2 Prüfungen mit 5 oder mehr Punkten, davon ein LK',
];

// ---------------------------------------------------------------------------
// Kleine Bausteine
// ---------------------------------------------------------------------------

/** Kaufmännisch runden: ab ,5 wird aufgerundet (12,5 -> 13). */
export function runde(wert) {
  return Math.floor(wert + 0.5);
}

/** Macht aus einer beliebigen Eingabe eine Punktzahl 0–15 oder null ("leer"). */
export function punkteOderLeer(wert) {
  if (wert === null || wert === undefined || wert === '' || typeof wert === 'boolean') return null;
  let zahl = wert;
  if (typeof wert === 'string') {
    // Erlaubt sind nur einfache Zahlen wie "12", "-3" oder "12,5".
    const text = wert.trim();
    if (!/^-?[0-9]+([.,][0-9]+)?$/.test(text)) return null;
    zahl = Number(text.replace(',', '.'));
  }
  if (typeof zahl !== 'number' || !Number.isFinite(zahl)) return null;
  return Math.min(15, Math.max(0, runde(zahl)));
}

/** Block I = (Summe GK + 2 × Summe LK) × 40 / 48, kaufmännisch gerundet. */
export function blockIAusSummen(summeGK, summeLK) {
  // × 40 / 48 ist dasselbe wie × 5 / 6. Mit ganzen Zahlen gerechnet: floor((5x + 3) / 6)
  return Math.floor(((summeGK + 2 * summeLK) * 5 + 3) / 6);
}

/** Abi-Schnitt in Zehnteln (13 = 1,3) oder null, wenn unter 300 Punkten (nicht bestanden). */
export function noteZehntelAusPunkten(punkte) {
  if (punkte < 300) return null;
  return Math.max(10, Math.floor((1020 - punkte) / 18));
}

/** Mindestpunktzahl für einen Zielschnitt (in Zehnteln). */
export function mindestpunkte(zielZehntel) {
  return 1003 - 18 * zielZehntel;
}

/** Zielschnitt-Rechner: Welcher Prüfungsschnitt wird für das Ziel gebraucht? */
export function zielRechner(blockI, zielZehntel) {
  const eMin = mindestpunkte(zielZehntel);
  const benoetigtBlockII = eMin - blockI;
  // Block II = Summe der 4 Prüfungen × 5 = Prüfungsschnitt × 20.
  // Schnitt in Zehnteln = benötigt / 20 × 10 = benötigt / 2, immer aufgerundet.
  const schnitt = Math.ceil(benoetigtBlockII / 2);
  let status = 'erreichbar';
  if (benoetigtBlockII <= 0) status = 'sicher';
  else if (schnitt > 150) status = 'nichtErreichbar';
  return {
    zielZehntel,
    eMin,
    benoetigtBlockII,
    status,
    schnittZehntel: status === 'erreichbar' ? schnitt : null,
  };
}

/** Schulnote 1–6 zu einer Punktzahl (15–13 = 1, 12–10 = 2, …, 0 = 6). */
export function schulnote(punkte) {
  return punkte === 0 ? 6 : 5 - Math.floor((punkte - 1) / 3);
}

/** 13 -> "1,3" */
export function zehntelText(zehntel) {
  return `${Math.floor(zehntel / 10)},${zehntel % 10}`;
}

// ---------------------------------------------------------------------------
// Daten aufräumen (gilt für gespeicherte Daten und für importierte Dateien)
// ---------------------------------------------------------------------------

let idZaehler = 0;
export function neueId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
  idZaehler += 1;
  return `fach-${Date.now().toString(36)}-${idZaehler}-${Math.random().toString(36).slice(2, 8)}`;
}

/** Ein leeres, neues Fach. */
export function neuesFach(name = '') {
  return {
    id: neueId(),
    name,
    istLK: false,
    abifach: 0,
    istZusatzkurs: false,
    nurQ1: false,
    pflicht: false,
    istProfilfach: false,
    noten: [null, null, null, null],
    annahmeQ2: null,
    quartalsnote: null,
  };
}

/**
 * Bringt beliebige Daten in eine saubere, gültige Form:
 * Punkte 0–15, höchstens ein Profilfach, jedes Abifach nur einmal usw.
 * Dadurch kann die restliche App nie an kaputten Daten abstürzen.
 */
export function normalisiere(roh) {
  const quelle = roh && typeof roh === 'object' ? roh : {};
  const rohFaecher = Array.isArray(quelle.faecher) ? quelle.faecher : [];
  const vergebeneAbifaecher = new Set();
  const vergebeneIds = new Set();
  let profilfachVergeben = false;

  const faecher = rohFaecher
    .filter((f) => f && typeof f === 'object')
    .map((f) => {
      const noten = [0, 1, 2, 3].map((i) => punkteOderLeer(Array.isArray(f.noten) ? f.noten[i] : null));

      // Abifach: nur 1–4, und jede Nummer nur einmal (das erste Fach gewinnt).
      let abifach = Number.isInteger(f.abifach) && f.abifach >= 1 && f.abifach <= 4 ? f.abifach : 0;
      if (abifach !== 0 && vergebeneAbifaecher.has(abifach)) abifach = 0;
      if (abifach !== 0) vergebeneAbifaecher.add(abifach);

      // Höchstens ein Profilfach.
      const istProfilfach = f.istProfilfach === true && !profilfachVergeben;
      if (istProfilfach) profilfachVergeben = true;

      // Zusatzkurs (nur Q2) und "nur Q1" schließen sich aus.
      const istZusatzkurs = f.istZusatzkurs === true;
      const nurQ1 = f.nurQ1 === true && !istZusatzkurs;

      let id = typeof f.id === 'string' && f.id !== '' ? f.id : neueId();
      if (vergebeneIds.has(id)) id = neueId();
      vergebeneIds.add(id);

      return {
        id,
        name: typeof f.name === 'string' ? f.name.trim().slice(0, 60) : '',
        istLK: f.istLK === true,
        abifach,
        istZusatzkurs,
        nurQ1,
        pflicht: f.pflicht === true || istProfilfach, // Profilfach ist immer Pflicht
        istProfilfach,
        noten,
        annahmeQ2: punkteOderLeer(f.annahmeQ2),
        quartalsnote: punkteOderLeer(f.quartalsnote),
      };
    });

  const rohPruefungen = Array.isArray(quelle.pruefungen) ? quelle.pruefungen : [];
  const pruefungen = [0, 1, 2, 3].map((i) => punkteOderLeer(rohPruefungen[i]));

  let ziel = quelle.einstellungen?.zielschnittZehntel;
  if (typeof ziel !== 'number' || !Number.isFinite(ziel)) ziel = ZIEL_STANDARD;
  ziel = Math.min(ZIEL_MAX, Math.max(ZIEL_MIN, runde(ziel)));

  return {
    format: FORMAT_NAME,
    schemaVersion: SCHEMA_VERSION,
    einstellungen: { zielschnittZehntel: ziel },
    pruefungen,
    faecher,
  };
}

// ---------------------------------------------------------------------------
// Belegung und Prognose
// ---------------------------------------------------------------------------

/** Welche der 4 Halbjahre finden für dieses Fach statt? */
export function belegung(fach) {
  const q1 = !fach.istZusatzkurs; // Zusatzkurs: Q1 gesperrt
  const q2 = !fach.nurQ1; // in Q2 abgewählt: Q2 gesperrt
  return [q1, q1, q2, q2];
}

/** Alle echten (eingetragenen) Noten eines Fachs in belegten Halbjahren. */
function echteNoten(fach) {
  const belegt = belegung(fach);
  return fach.noten.filter((note, i) => belegt[i] && note !== null);
}

/** Zählt die Quartalsnote (noch) mit? Nur solange Q2.1 belegt und noch offen ist. */
function quartalsnoteAktiv(fach) {
  return fach.quartalsnote !== null && belegung(fach)[2] && fach.noten[2] === null;
}

/**
 * Durchschnitt ganzer Zahlen, kaufmännisch gerundet – komplett mit ganzen Zahlen
 * gerechnet, damit Swift und JavaScript garantiert dasselbe Ergebnis liefern.
 * `faktor` 10 liefert den Schnitt in Zehnteln (z. B. 128 für 12,8).
 */
function gerundeterSchnitt(werte, faktor = 1) {
  const summe = werte.reduce((s, w) => s + w, 0);
  return Math.floor((2 * faktor * summe + werte.length) / (2 * werte.length));
}

/** Durchschnitt aller echten Noten aller Fächer (Fallback 10), kaufmännisch gerundet. */
function gesamtSchnitt(faecher) {
  const alle = faecher.flatMap(echteNoten);
  return alle.length === 0 ? FALLBACK_NOTE : gerundeterSchnitt(alle);
}

/** Fachschnitt = echte Noten + Quartalsnote, gerundet. null, wenn es noch nichts gibt. */
function fachSchnitt(fach) {
  const werte = echteNoten(fach);
  if (quartalsnoteAktiv(fach)) werte.push(fach.quartalsnote);
  return werte.length === 0 ? null : gerundeterSchnitt(werte);
}

/** Prognose für ein leeres Halbjahr (Regeln 1–4 aus Abschnitt 3.1). */
function prognoseHalbjahr(fach, halbjahr, alleSchnitt) {
  if (halbjahr === 2 && quartalsnoteAktiv(fach)) return fach.quartalsnote; // Regel 1
  if (halbjahr >= 2 && fach.annahmeQ2 !== null) return fach.annahmeQ2; // Regel 2 (nur Q2)
  return fachSchnitt(fach) ?? alleSchnitt; // Regel 3, sonst Regel 4
}

/** Prognose für eine Prüfung ohne Eingabe (Regeln 2–4). */
function prognosePruefung(fach, alleSchnitt) {
  if (!fach) return alleSchnitt;
  if (fach.annahmeQ2 !== null) return fach.annahmeQ2;
  return fachSchnitt(fach) ?? alleSchnitt;
}

// ---------------------------------------------------------------------------
// Die Hauptfunktion
// ---------------------------------------------------------------------------

/**
 * Berechnet alles, was die Oberfläche anzeigt.
 * `roh` darf unaufgeräumt sein – es wird zuerst normalisiert.
 */
export function berechne(roh) {
  const stand = normalisiere(roh);
  const { faecher } = stand;
  const alleSchnitt = gesamtSchnitt(faecher);

  // 1) Für jedes Fach die 4 Halbjahre mit echter Note oder Prognose füllen.
  const fachErgebnisse = faecher.map((fach) => {
    const belegt = belegung(fach);
    const kurse = belegt.map((istBelegt, i) => {
      if (!istBelegt) return { belegt: false, wert: null, istPrognose: false, eingebracht: false };
      const echt = fach.noten[i];
      return {
        belegt: true,
        wert: echt !== null ? echt : prognoseHalbjahr(fach, i, alleSchnitt),
        istPrognose: echt === null,
        eingebracht: false,
      };
    });
    return { id: fach.id, name: fach.name, kurse, schnittZehntel: null, schnittIstPrognose: false };
  });

  // 2) Block I: Welche Kurse werden eingebracht?
  //    Immer: alle LK-Kurse, Abifach 3 und 4, Profilfach, Pflichtfächer.
  const frei = []; // GK-Kurse, die um die restlichen Plätze konkurrieren
  let pflichtGK = 0;
  faecher.forEach((fach, f) => {
    const immer = fach.istLK || fach.abifach >= 3 || fach.pflicht || fach.istProfilfach;
    fachErgebnisse[f].kurse.forEach((kurs, h) => {
      if (!kurs.belegt) return;
      if (immer) {
        kurs.eingebracht = true;
        if (!fach.istLK) pflichtGK += 1;
      } else {
        frei.push({ f, h, wert: kurs.wert });
      }
    });
  });
  //    Restliche GK-Plätze mit den besten übrigen Kursen auffüllen.
  //    Bei Gleichstand gewinnt das Fach, das weiter oben steht, dann das frühere Halbjahr.
  frei.sort((a, b) => b.wert - a.wert || a.f - b.f || a.h - b.h);
  frei.slice(0, Math.max(0, GK_PLAETZE - pflichtGK)).forEach(({ f, h }) => {
    fachErgebnisse[f].kurse[h].eingebracht = true;
  });

  // 3) Summen bilden und Defizite zählen.
  let summeLK = 0;
  let summeGK = 0;
  let anzahlLK = 0;
  let anzahlGK = 0;
  let defizite = 0;
  let defiziteLK = 0;
  let nullKurse = 0;
  let hochgerechnet = false;
  faecher.forEach((fach, f) => {
    const ergebnis = fachErgebnisse[f];
    const belegte = ergebnis.kurse.filter((k) => k.belegt);
    if (belegte.length > 0) {
      ergebnis.schnittZehntel = gerundeterSchnitt(belegte.map((k) => k.wert), 10);
      ergebnis.schnittIstPrognose = belegte.some((k) => k.istPrognose);
    }
    ergebnis.kurse.forEach((kurs) => {
      if (!kurs.eingebracht) return;
      if (kurs.istPrognose) hochgerechnet = true;
      if (fach.istLK) {
        summeLK += kurs.wert;
        anzahlLK += 1;
      } else {
        summeGK += kurs.wert;
        anzahlGK += 1;
      }
      if (kurs.wert < 5) {
        defizite += 1;
        if (fach.istLK) defiziteLK += 1;
      }
      if (kurs.wert === 0) nullKurse += 1;
    });
  });
  const blockI = blockIAusSummen(summeGK, summeLK);

  // 4) Block II: die 4 Prüfungen, jeweils × 5.
  const pruefungen = [1, 2, 3, 4].map((abifach) => {
    const fach = faecher.find((x) => x.abifach === abifach) ?? null;
    const echt = stand.pruefungen[abifach - 1];
    const wert = echt !== null ? echt : prognosePruefung(fach, alleSchnitt);
    if (echt === null) hochgerechnet = true;
    return {
      abifach,
      fachId: fach ? fach.id : null,
      fachName: fach ? fach.name : null,
      istLK: abifach <= 2,
      muendlich: abifach === 4,
      wert,
      istPrognose: echt === null,
      punkte: wert * 5,
    };
  });
  const blockII = pruefungen.reduce((summe, p) => summe + p.punkte, 0);
  const gesamt = blockI + blockII;

  // 5) Zulassungs- und Bestehensbedingungen.
  const bestandenePruefungen = pruefungen.filter((p) => p.wert >= 5);
  const erfuellt = [
    anzahlLK + anzahlGK === 40 && anzahlLK === 8,
    blockI >= 200,
    defizite <= 8 && defiziteLK <= 3,
    nullKurse === 0,
    blockII >= 100,
    bestandenePruefungen.length >= 2 && bestandenePruefungen.some((p) => p.istLK),
  ];
  const bedingungen = BEDINGUNGEN.map((text, i) => ({ nummer: i + 1, text, erfuellt: erfuellt[i] }));

  // 6) Gesamtnote.
  let status = 'ok';
  let noteZehntel = noteZehntelAusPunkten(gesamt);
  if (erfuellt.includes(false)) {
    status = 'bedingungen';
    noteZehntel = null;
  } else if (noteZehntel === null) {
    status = 'nichtBestanden';
  }

  return {
    stand,
    faecher: fachErgebnisse,
    pruefungen,
    summeLK,
    summeGK,
    anzahlLK,
    anzahlGK,
    anzahlEingebracht: anzahlLK + anzahlGK,
    defizite,
    defiziteLK,
    blockI,
    blockII,
    gesamt,
    bedingungen,
    status, // 'ok' | 'bedingungen' | 'nichtBestanden'
    noteZehntel,
    hochgerechnet,
    ziel: zielRechner(blockI, stand.einstellungen.zielschnittZehntel),
  };
}

// ---------------------------------------------------------------------------
// Export / Import (gemeinsames Format mit der iPhone-App)
// ---------------------------------------------------------------------------

/** Erzeugt den Text der Export-Datei. */
export function exportiere(stand, quelle = 'web', jetzt = new Date()) {
  const sauber = normalisiere(stand);
  return JSON.stringify(
    {
      format: FORMAT_NAME,
      schemaVersion: SCHEMA_VERSION,
      exportiertAm: jetzt.toISOString(),
      quelle,
      einstellungen: sauber.einstellungen,
      pruefungen: sauber.pruefungen,
      faecher: sauber.faecher,
    },
    null,
    2,
  );
}

/**
 * Liest eine Export-Datei. Liefert { ok: true, stand } oder { ok: false, fehler }.
 * Wirft nie einen Fehler.
 */
export function importiere(text) {
  let daten;
  try {
    daten = JSON.parse(text);
  } catch {
    return { ok: false, fehler: 'Die Datei ist keine gültige JSON-Datei.' };
  }
  if (!daten || typeof daten !== 'object' || Array.isArray(daten)) {
    return { ok: false, fehler: 'Die Datei enthält keine Abi-Rechner-Daten.' };
  }
  if (daten.format !== FORMAT_NAME || !Array.isArray(daten.faecher)) {
    return { ok: false, fehler: 'Die Datei stammt nicht aus dem Abi-Rechner.' };
  }
  if (!Number.isInteger(daten.schemaVersion) || daten.schemaVersion < 1) {
    return { ok: false, fehler: 'Die Datei hat keine gültige Versionsnummer.' };
  }
  if (daten.schemaVersion > SCHEMA_VERSION) {
    return { ok: false, fehler: 'Die Datei stammt aus einer neueren App-Version. Bitte aktualisiere die App.' };
  }
  return { ok: true, stand: normalisiere(daten) };
}
