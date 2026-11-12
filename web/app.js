// ============================================================================
// app.js – die Oberfläche der Web-App
//
// Aufbau:
//   1. Zustand (die Daten) und Speichern
//   2. Kleine Helfer (Symbole, Text-Formatierung)
//   3. Die vier Bereiche: Übersicht, Kurse, Quartal, Prüfungen
//   4. Sheets (Fach bearbeiten, Info & Daten) und Bestätigungsdialoge
//   5. Export / Import
//   6. Start
//
// Gerechnet wird ausschließlich in calc.js. Hier wird nur angezeigt.
// ============================================================================

import * as C from './calc.js';
import { lade, speichere } from './storage.js';
import { STARTDATEN } from './startdaten.js';

// ---------------------------------------------------------------------------
// 1. Zustand
// ---------------------------------------------------------------------------

let stand; // die Daten (Fächer, Prüfungen, Einstellungen)
let ergebnis; // das, was calc.js daraus berechnet
let aktiverTab = 'uebersicht';
let letzteNote = null; // zuletzt angezeigter Schnitt (für die Animation)
let letzteBalken = { blockI: 0, blockII: 0, gesamt: 0 };
let speicherWarnungGezeigt = false;

const ansicht = document.getElementById('ansicht');
const ebene = document.getElementById('ebene');
const leiste = document.getElementById('leiste');

const TABS = [
  { id: 'uebersicht', titel: 'Übersicht', symbol: 'hut' },
  { id: 'kurse', titel: 'Kurse', symbol: 'liste' },
  { id: 'quartal', titel: 'Quartal', symbol: 'kalender' },
  { id: 'pruefungen', titel: 'Prüfungen', symbol: 'stift' },
];

/** Nach jeder Änderung: neu rechnen, speichern, Anzeige auffrischen. */
function geaendert({ neuZeichnen = false } = {}) {
  stand = C.normalisiere(stand);
  ergebnis = C.berechne(stand);
  if (!speichere(stand) && !speicherWarnungGezeigt) {
    speicherWarnungGezeigt = true;
    zeigeHinweis('Speichern nicht möglich. Bitte exportiere deine Daten als Sicherung.');
  }
  if (neuZeichnen) zeichne();
  else frischeAuf();
}

// ---------------------------------------------------------------------------
// 2. Helfer
// ---------------------------------------------------------------------------

const SYMBOLE = {
  hut: '<path d="M12 4 2 9l10 5 10-5-10-5Z"/><path d="M6 11.4V16c0 1.4 2.7 3 6 3s6-1.6 6-3v-4.6"/><path d="M22 9v5.5"/>',
  liste: '<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r="1.2" fill="currentColor"/><circle cx="4.5" cy="12" r="1.2" fill="currentColor"/><circle cx="4.5" cy="18" r="1.2" fill="currentColor"/>',
  kalender: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  stift: '<path d="M11 5H7a3 3 0 0 0-3 3v9a3 3 0 0 0 3 3h9a3 3 0 0 0 3-3v-4"/><path d="m18.4 3.6 2 2L12 14l-2.8.8L10 12l8.4-8.4Z"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6"/><circle cx="12" cy="7.6" r="0.9" fill="currentColor" stroke="none"/>',
  funken: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3Z" fill="currentColor" stroke="none"/>',
};
const symbol = (name) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${SYMBOLE[name]}</svg>`;
const PFEIL = '<svg class="pfeil" viewBox="0 0 8 14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m1 1 6 6-6 6"/></svg>';
const HAKEN_JA = '<svg class="haken ja" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="11" fill="currentColor"/><path d="m7 12.5 3.4 3.4L17 9" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const HAKEN_NEIN = '<svg class="haken nein" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="11" fill="currentColor"/><path d="m8 8 8 8M16 8l-8 8" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/></svg>';

/** Macht Text sicher für die Ausgabe in HTML (z. B. Fachnamen). */
const esc = (text) =>
  String(text ?? '').replace(/[&<>"']/g, (z) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[z]);

const z = C.zehntelText; // 13 -> "1,3"
const fachName = (fach) => fach.name || 'Ohne Namen';

/** Kurzes Vibrieren bei Eingaben (auf dem iPhone unterstützt Safari das nicht – dann passiert einfach nichts). */
function haptik() {
  try {
    navigator.vibrate?.(8);
  } catch { /* nicht verfügbar */ }
}

/** Reihenfolge der Fächer in der Liste: LK zuerst, dann Abifächer, dann der Rest. */
function sortierteFaecher() {
  const rang = (f) => (f.istLK ? 0 : f.abifach > 0 ? 1 : 2);
  return stand.faecher
    .map((fach, index) => ({ fach, index }))
    .sort((a, b) => rang(a.fach) - rang(b.fach) || (a.fach.abifach || 9) - (b.fach.abifach || 9) || a.index - b.index);
}

/** Ein Punkte-Eingabefeld (0–15). `daten` landet als data-Attribute am Feld. */
function punkteFeld({ wert, prognose, label, daten, schmal = false }) {
  const attribute = Object.entries(daten).map(([k, v]) => `data-${k}="${esc(v)}"`).join(' ');
  return `<input class="punkte zahl${schmal ? ' schmal' : ''}" type="text" inputmode="numeric" pattern="[0-9]*" maxlength="2"
    autocomplete="off" enterkeyhint="done" value="${wert ?? ''}" placeholder="${prognose != null ? `≈${prognose}` : '–'}"
    aria-label="${esc(label)}" ${attribute}>`;
}

/** Liest ein Punkte-Feld aus: nur Ziffern, höchstens 15. Korrigiert das Feld gleich mit. */
function liesPunkte(feld) {
  const ziffern = feld.value.replace(/[^0-9]/g, '').slice(0, 2);
  const wert = ziffern === '' ? null : Math.min(15, Number(ziffern));
  const text = wert === null ? '' : String(wert);
  if (feld.value !== text) feld.value = text;
  return wert;
}

function zeigeHinweis(text) {
  document.querySelector('.hinweis')?.remove();
  const el = document.createElement('div');
  el.className = 'hinweis';
  el.setAttribute('role', 'status');
  el.textContent = text;
  document.body.append(el);
  setTimeout(() => el.remove(), 3200);
}

// ---------------------------------------------------------------------------
// 3. Die vier Bereiche
// ---------------------------------------------------------------------------

function zeichneTabbar() {
  document.getElementById('tabbar').innerHTML = TABS.map(
    (t) => `<button class="tab" data-tab="${t.id}" ${t.id === aktiverTab ? 'aria-current="page"' : ''}>${symbol(t.symbol)}<span>${t.titel}</span></button>`,
  ).join('');
}

/** Zeichnet den aktiven Bereich komplett neu. */
function zeichne() {
  const tab = TABS.find((t) => t.id === aktiverTab);
  document.getElementById('leiste-titel').textContent = tab.titel;
  ansicht.innerHTML = { uebersicht: htmlUebersicht, kurse: htmlKurse, quartal: htmlQuartal, pruefungen: htmlPruefungen }[aktiverTab]();
  zeichneTabbar();
  frischeAuf();
  aktualisiereLeiste();
}

/** Frischt nur Zahlen und Markierungen auf – Eingabefelder bleiben stehen (die Tastatur bleibt offen). */
function frischeAuf() {
  if (aktiverTab === 'uebersicht') frischeUebersichtAuf();
  if (aktiverTab === 'kurse') frischeKurseAuf();
  if (aktiverTab === 'quartal') frischeQuartalAuf();
  if (aktiverTab === 'pruefungen') frischePruefungenAuf();
}

const kopf = (titel, aktionen = '') => `<header class="kopf"><h1 class="grosser-titel" id="titel">${titel}</h1><div class="kopf-aktionen">${aktionen}</div></header>`;

// ----- Übersicht -----------------------------------------------------------

function htmlUebersicht() {
  return `${kopf('Übersicht', `<button class="symbol-knopf" data-aktion="info" aria-label="Info und Daten">${symbol('info')}</button>`)}
    <div id="uebersicht-inhalt"></div>`;
}

function frischeUebersichtAuf() {
  const e = ergebnis;
  let noteHtml;
  let ansage;
  if (e.status === 'ok') {
    noteHtml = `<div class="note${letzteNote !== null && letzteNote !== e.noteZehntel ? ' neu' : ''}">${z(e.noteZehntel)}</div>`;
    ansage = `Abi-Schnitt ${z(e.noteZehntel)}${e.hochgerechnet ? ', hochgerechnet' : ''}`;
  } else {
    const text = e.status === 'bedingungen' ? 'Bedingungen nicht erfüllt' : 'Nicht bestanden';
    noteHtml = `<div class="note text">${text}</div>`;
    ansage = text;
  }
  const kapsel = e.hochgerechnet
    ? `<div class="kapsel">${symbol('funken')} hochgerechnet</div>`
    : '<div class="kapsel gut">alle Noten eingetragen</div>';

  const balken = (name, wert, max, schluessel) => `
    <div class="zelle block" role="group" aria-label="${name}: ${wert} von ${max} Punkten">
      <div class="oben"><span>${name}</span><span class="wert zahl"><b>${wert}</b> / ${max}</span></div>
      <div class="balken"><i data-balken="${schluessel}" style="width:${(letzteBalken[schluessel] / max) * 100}%"></i></div>
    </div>`;

  const ziel = e.ziel;
  let zielText;
  let zielKlasse = '';
  let zielFuss = `Für ${z(ziel.zielZehntel)} brauchst du mindestens ${ziel.eMin} Punkte, davon ${Math.max(0, ziel.benoetigtBlockII)} in Block II.`;
  if (ziel.status === 'sicher') {
    zielText = 'Schon sicher';
    zielKlasse = 'gut';
    zielFuss = `Für ${z(ziel.zielZehntel)} brauchst du mindestens ${ziel.eMin} Punkte. Die hast du schon mit Block I.`;
  } else if (ziel.status === 'nichtErreichbar') {
    zielText = 'Nicht erreichbar';
    zielKlasse = 'schlecht';
    zielFuss = `Für ${z(ziel.zielZehntel)} wären ${ziel.benoetigtBlockII} Punkte in Block II nötig, möglich sind höchstens 300.`;
  } else {
    zielText = `Ø ${z(ziel.schnittZehntel)} Punkte`;
  }
  const optionen = [];
  for (let n = C.ZIEL_MIN; n <= C.ZIEL_MAX; n += 1) {
    optionen.push(`<option value="${n}" ${n === ziel.zielZehntel ? 'selected' : ''}>${z(n)}</option>`);
  }

  // Noch keine Fächer (erster Start): Begrüßung statt Zahlen.
  if (stand.faecher.length === 0) {
    document.getElementById('uebersicht-inhalt').innerHTML = `
      <section class="gruppe leer">
        <p style="font-size:1.25rem;font-weight:700;color:var(--text);margin-bottom:6px">Willkommen</p>
        <p>Hier siehst du gleich deinen Abi-Schnitt. Lade zuerst deine gesicherten Daten oder lege deine Fächer an.</p>
      </section>
      <section class="abschnitt"><div class="gruppe">
        <button class="zelle aktion" data-aktion="info">Daten importieren …</button>
        <button class="zelle aktion" data-aktion="zu-kursen">Fächer selbst anlegen</button>
      </div>
      <p class="abschnitt-fuss">Deine Daten bleiben auf diesem Gerät. Berechnung vereinfacht nach APO-GOSt NRW. Verbindlich ist die Berechnung deiner Schule.</p></section>`;
    letzteNote = null;
    return;
  }

  document.getElementById('uebersicht-inhalt').innerHTML = `
    <section class="gruppe held" aria-label="${ansage}">
      <div class="label">Abi-Schnitt</div>
      ${noteHtml}
      <div class="unter zahl">${e.gesamt} von 900 Punkten</div>
      ${kapsel}
    </section>

    <section class="abschnitt">
      <h2 class="abschnitt-titel">Punkte</h2>
      <div class="gruppe">
        ${balken('Block I', e.blockI, 600, 'blockI')}
        ${balken('Block II', e.blockII, 300, 'blockII')}
        ${balken('Gesamt', e.gesamt, 900, 'gesamt')}
      </div>
      <p class="abschnitt-fuss">Block I: ${e.anzahlEingebracht} eingebrachte Kurse, davon ${e.anzahlLK} LK. Block II: 4 Prüfungen × 5.</p>
    </section>

    <section class="abschnitt">
      <h2 class="abschnitt-titel">Zielschnitt</h2>
      <div class="gruppe">
        <label class="zelle"><span class="titel">Mein Ziel</span>
          <select class="auswahl zahl" data-feld="ziel" aria-label="Zielschnitt">${optionen.join('')}</select></label>
        <div class="zelle"><span class="titel">Benötigter Prüfungsschnitt</span><span class="ziel-ergebnis ${zielKlasse} zahl">${zielText}</span></div>
      </div>
      <p class="abschnitt-fuss">${zielFuss}</p>
    </section>

    <section class="abschnitt">
      <h2 class="abschnitt-titel">Zulassung und Bestehen</h2>
      <div class="gruppe">
        ${e.bedingungen.map((b) => `<div class="zelle">${b.erfuellt ? HAKEN_JA : HAKEN_NEIN}<span class="titel">${b.text}<span class="nur-vorlesen">: ${b.erfuellt ? 'erfüllt' : 'nicht erfüllt'}</span></span></div>`).join('')}
      </div>
      <p class="abschnitt-fuss">Berechnung vereinfacht nach APO-GOSt NRW. Verbindlich ist die Berechnung deiner Schule.</p>
    </section>`;

  // Balken nach dem Zeichnen auf den neuen Wert setzen – so gleiten sie weich dorthin.
  const neu = { blockI: e.blockI, blockII: e.blockII, gesamt: e.gesamt };
  const max = { blockI: 600, blockII: 300, gesamt: 900 };
  requestAnimationFrame(() => {
    ansicht.querySelectorAll('[data-balken]').forEach((el) => {
      const k = el.dataset.balken;
      el.style.width = `${Math.min(100, (neu[k] / max[k]) * 100)}%`;
    });
  });
  letzteBalken = neu;
  if (letzteNote !== e.noteZehntel) document.getElementById('ansage').textContent = ansage;
  letzteNote = e.noteZehntel;
}

// ----- Kurse ---------------------------------------------------------------

function marken(fach) {
  const m = [];
  if (fach.istLK) m.push('<span class="marke lk">LK</span>');
  if (fach.abifach > 0) m.push(`<span class="marke abi">Abifach ${fach.abifach}${fach.abifach === 4 ? ' · mündlich' : ''}</span>`);
  if (fach.istProfilfach) m.push('<span class="marke profil">Profilfach</span>');
  else if (fach.pflicht) m.push('<span class="marke">Pflicht</span>');
  if (fach.istZusatzkurs) m.push('<span class="marke">Zusatzkurs</span>');
  if (fach.nurQ1) m.push('<span class="marke">nur Q1</span>');
  if (fach.annahmeQ2 !== null) m.push(`<span class="marke zahl">Annahme ${fach.annahmeQ2}</span>`);
  return m.length ? `<div class="marken">${m.join('')}</div>` : '';
}

function htmlKurse() {
  const zeilen = sortierteFaecher().map(({ fach }) => {
    const belegt = C.belegung(fach);
    const felder = C.HALBJAHRE.map((hj, h) => {
      if (!belegt[h]) return `<div class="halbjahr"><span class="hj">${hj}</span><div class="gesperrt" aria-label="${hj} nicht belegt">–</div></div>`;
      const id = `n-${fach.id}-${h}`;
      return `<div class="halbjahr" data-zelle="${h}"><label for="${esc(id)}">${hj}</label>${punkteFeld({
        wert: fach.noten[h], prognose: null, label: `${fachName(fach)}, ${hj}, Punkte`, daten: { feld: 'note', fach: fach.id, h },
      }).replace('<input', `<input id="${esc(id)}"`)}</div>`;
    }).join('');
    return `<div class="fach" data-fach="${esc(fach.id)}">
      <button class="loeschen-flaeche" data-aktion="loeschen" data-fach="${esc(fach.id)}" tabindex="-1" aria-hidden="true">Löschen</button>
      <div class="fach-inhalt">
        <button class="fach-kopf" data-aktion="bearbeiten" data-fach="${esc(fach.id)}" aria-label="${esc(fachName(fach))} bearbeiten">
          <span class="fach-name">${esc(fachName(fach))}</span><span class="fach-schnitt zahl"></span>${PFEIL}
        </button>
        ${marken(fach)}
        <div class="halbjahre">${felder}</div>
      </div>
    </div>`;
  }).join('');

  return `${kopf('Kurse', `<button class="symbol-knopf" data-aktion="neu" aria-label="Fach hinzufügen">${symbol('plus')}</button>`)}
    ${stand.faecher.length === 0
      ? '<div class="gruppe leer">Noch keine Fächer.<br>Tippe oben rechts auf +, um ein Fach hinzuzufügen.</div>'
      : `<div class="gruppe">${zeilen}</div>
         <p class="abschnitt-fuss">Kursive Werte mit ≈ sind Prognosen. Blass dargestellte Kurse werden nicht in Block I eingebracht. Tippe auf ein Fach, um es zu bearbeiten; wische nach links, um es zu löschen.</p>`}`;
}

function frischeKurseAuf() {
  ergebnis.faecher.forEach((fe) => {
    const zeile = ansicht.querySelector(`.fach[data-fach="${CSS.escape(fe.id)}"]`);
    if (!zeile) return;
    const schnitt = zeile.querySelector('.fach-schnitt');
    schnitt.textContent = fe.schnittZehntel === null ? '' : `Ø ${fe.schnittIstPrognose ? '≈' : ''}${z(fe.schnittZehntel)}`;
    schnitt.classList.toggle('prognose', fe.schnittIstPrognose);
    fe.kurse.forEach((kurs, h) => {
      const zelle = zeile.querySelector(`[data-zelle="${h}"]`);
      if (!zelle) return;
      const feld = zelle.querySelector('input');
      feld.placeholder = kurs.istPrognose ? `≈${kurs.wert}` : '';
      if (document.activeElement !== feld) feld.value = kurs.istPrognose ? '' : kurs.wert;
      zelle.classList.toggle('aus', !kurs.eingebracht);
      const fach = stand.faecher.find((f) => f.id === fe.id);
      feld.setAttribute('aria-label', `${fachName(fach)}, ${C.HALBJAHRE[h]}, Punkte${kurs.istPrognose ? `, Prognose ${kurs.wert}` : ''}${kurs.eingebracht ? '' : ', nicht eingebracht'}`);
    });
  });
}

// ----- Quartal -------------------------------------------------------------

function htmlQuartal() {
  const inQ2 = sortierteFaecher().filter(({ fach }) => C.belegung(fach)[2]);
  const zeilen = inQ2.map(({ fach }) => `
    <label class="zelle" data-quartal="${esc(fach.id)}">
      <span class="titel">${esc(fachName(fach))}<div class="neben"></div></span>
      ${punkteFeld({ wert: fach.quartalsnote, prognose: null, label: `${fachName(fach)}, Quartalsnote`, daten: { feld: 'quartal', fach: fach.id }, schmal: true })}
    </label>`).join('');
  return `${kopf('Quartal')}
    <section class="abschnitt" style="margin-top:0">
      <h2 class="abschnitt-titel">1. Quartal Q2.1</h2>
      ${inQ2.length === 0 ? '<div class="gruppe leer">Kein Fach ist in Q2 belegt.</div>' : `<div class="gruppe">${zeilen}</div>`}
      <p class="abschnitt-fuss">Quartalsnoten ersetzen die Prognose für Q2.1, bis die Halbjahresnote da ist. Außerdem fließen sie in die Prognose für Q2.2 und die Prüfungen ein.</p>
    </section>`;
}

function frischeQuartalAuf() {
  stand.faecher.forEach((fach) => {
    const zeile = ansicht.querySelector(`[data-quartal="${CSS.escape(fach.id)}"]`);
    if (!zeile) return;
    const kurs = ergebnis.faecher.find((f) => f.id === fach.id).kurse[2];
    let text;
    if (fach.noten[2] !== null) text = `Q2.1 steht fest: ${fach.noten[2]} Punkte`;
    else if (fach.quartalsnote !== null) text = `Prognose Q2.1: ${kurs.wert} Punkte (Quartalsnote)`;
    else text = `Prognose Q2.1: ≈${kurs.wert} Punkte`;
    zeile.querySelector('.neben').textContent = text;
  });
}

// ----- Prüfungen -----------------------------------------------------------

function htmlPruefungen() {
  const karten = ergebnis.pruefungen.map((p) => `
    <div class="gruppe pruefung abschnitt" data-pruefung="${p.abifach}" ${p.abifach === 1 ? 'style="margin-top:0"' : ''}>
      <div class="oben">
        <div class="nr zahl${p.istLK ? ' lk' : ''}" aria-hidden="true">${p.abifach}</div>
        <div class="titel" style="flex:1;min-width:0">
          <div class="name">${p.fachName !== null ? esc(p.fachName || 'Ohne Namen') : 'Kein Fach zugeordnet'}</div>
          <div class="art">${p.abifach}. Abifach · ${p.istLK ? 'LK' : 'GK'} · ${p.muendlich ? 'mündlich' : 'schriftlich'}</div>
        </div>
        ${punkteFeld({ wert: stand.pruefungen[p.abifach - 1], prognose: null, label: `Prüfungsnote ${p.abifach}. Abifach${p.fachName ? `, ${p.fachName}` : ''}, Punkte`, daten: { feld: 'pruefung', abifach: p.abifach }, schmal: true })}
      </div>
      <div class="rechnung zahl"><span class="links"></span><span class="rechts"></span></div>
    </div>`).join('');

  const noten = [[1, '15–13'], [2, '12–10'], [3, '9–7'], [4, '6–4'], [5, '3–1'], [6, '0']];
  return `${kopf('Prüfungen')}
    ${karten}
    <section class="abschnitt">
      <h2 class="abschnitt-titel">Block II</h2>
      <div class="gruppe"><div class="zelle"><span class="titel">Summe der 4 Prüfungen × 5</span><span class="wert zahl" id="block2-summe"></span></div></div>
    </section>
    <section class="abschnitt">
      <h2 class="abschnitt-titel">Punkte und Noten</h2>
      <div class="gruppe tabelle" role="table" aria-label="Punkte-Noten-Tabelle">
        ${noten.map(([n, p]) => `<div role="row"><div class="n zahl" role="cell" aria-label="Note ${n}">${n}</div><div class="p zahl" role="cell" aria-label="${p.replace('–', ' bis ')} Punkte">${p}</div></div>`).join('')}
      </div>
      <p class="abschnitt-fuss">Jede Prüfungsnote zählt fünffach in Block II. Abifach 1 bis 3 werden schriftlich geprüft, Abifach 4 mündlich. Die Zuordnung der Fächer änderst du im Bereich Kurse.</p>
    </section>`;
}

function frischePruefungenAuf() {
  ergebnis.pruefungen.forEach((p) => {
    const karte = ansicht.querySelector(`[data-pruefung="${p.abifach}"]`);
    if (!karte) return;
    const feld = karte.querySelector('input');
    feld.placeholder = p.istPrognose ? `≈${p.wert}` : '';
    karte.querySelector('.links').innerHTML = p.istPrognose
      ? `<span class="prognose">Prognose</span> · Note ${C.schulnote(p.wert)}`
      : `Note ${C.schulnote(p.wert)}`;
    karte.querySelector('.rechts').innerHTML = `${p.istPrognose ? '≈' : ''}${p.wert} × 5 = <b>${p.punkte}</b> Punkte`;
  });
  document.getElementById('block2-summe').textContent = `${ergebnis.blockII} / 300`;
}

// ---------------------------------------------------------------------------
// 4. Sheets und Dialoge
// ---------------------------------------------------------------------------

/** Öffnet eine Ebene über der App. Tippen auf den dunklen Bereich schließt sie. */
function oeffneEbene(html, { beiSchliessen } = {}) {
  const vorher = document.activeElement;
  const schleier = document.createElement('div');
  schleier.className = 'schleier';
  schleier.innerHTML = html;
  const schliesse = () => {
    schleier.remove();
    document.removeEventListener('keydown', taste);
    beiSchliessen?.();
    vorher?.focus?.({ preventScroll: true });
  };
  const taste = (ev) => {
    if (ev.key === 'Escape' && ebene.lastElementChild === schleier) schliesse();
  };
  schleier.addEventListener('click', (ev) => {
    if (ev.target === schleier) schliesse();
  });
  document.addEventListener('keydown', taste);
  ebene.append(schleier);
  return { el: schleier, schliesse };
}

/** Bestätigungsdialog im iOS-Stil. Liefert true, wenn bestätigt wurde. */
function bestaetige({ titel, text, knopf, gefahr = true }) {
  return new Promise((fertig) => {
    let antwort = false;
    const { el, schliesse } = oeffneEbene(
      `<div class="aktionsblatt" role="alertdialog" aria-modal="true" aria-label="${esc(titel)}">
        <div class="karte"><div class="frage"><b>${esc(titel)}</b>${esc(text)}</div>
          <button class="${gefahr ? 'gefahr' : ''}" data-ja>${esc(knopf)}</button></div>
        <div class="karte abbrechen"><button data-nein>Abbrechen</button></div>
      </div>`,
      { beiSchliessen: () => fertig(antwort) },
    );
    el.querySelector('[data-ja]').addEventListener('click', () => {
      antwort = true;
      schliesse();
    });
    el.querySelector('[data-nein]').addEventListener('click', schliesse);
    el.querySelector('[data-nein]').focus();
  });
}

/** Sheet zum Bearbeiten oder Anlegen eines Fachs. Gearbeitet wird auf einer Kopie ("entwurf"). */
function oeffneFachSheet(fachId) {
  const istNeu = fachId === null;
  const original = istNeu ? null : stand.faecher.find((f) => f.id === fachId);
  if (!istNeu && !original) return;
  const entwurf = istNeu ? C.neuesFach('') : structuredClone(original);

  const { el, schliesse } = oeffneEbene(
    `<div class="sheet" role="dialog" aria-modal="true" aria-label="${istNeu ? 'Neues Fach' : 'Fach bearbeiten'}">
      <div class="sheet-kopf">
        <button class="links" data-abbrechen>Abbrechen</button>
        <h2>${istNeu ? 'Neues Fach' : 'Fach bearbeiten'}</h2>
        <button class="rechts" data-fertig>${istNeu ? 'Hinzufügen' : 'Fertig'}</button>
      </div>
      <div class="sheet-inhalt"></div>
    </div>`,
  );
  const inhalt = el.querySelector('.sheet-inhalt');
  const fertigKnopf = el.querySelector('[data-fertig]');

  const zeichneInhalt = () => {
    const belegt = C.belegung(entwurf);
    const belegung = entwurf.istZusatzkurs ? 'zusatz' : entwurf.nurQ1 ? 'q1' : 'alle';
    const vergeben = (n) => stand.faecher.find((f) => f.abifach === n && f.id !== entwurf.id);
    const profil = stand.faecher.find((f) => f.istProfilfach && f.id !== entwurf.id);
    const segment = (name, wert, text, aktiv) => `<label><input type="radio" name="${name}" value="${wert}" ${aktiv ? 'checked' : ''}><span>${text}</span></label>`;
    const noten = C.HALBJAHRE.map((hj, h) => (belegt[h]
      ? `<label class="zelle"><span class="titel">${hj}</span>${punkteFeld({ wert: entwurf.noten[h], prognose: null, label: `${hj}, Punkte`, daten: { e: 'note', h }, schmal: true })}</label>`
      : '')).join('');

    inhalt.innerHTML = `
      <section class="abschnitt">
        <div class="gruppe">
          <label class="zelle"><span>Name</span><input class="text-feld" data-e="name" type="text" maxlength="60" placeholder="z. B. Chemie" value="${esc(entwurf.name)}" autocomplete="off" autocapitalize="words" enterkeyhint="done"></label>
          <div class="zelle"><span class="titel">Kursart</span><div class="segmente" role="radiogroup" aria-label="Kursart">
            ${segment('art', 'gk', 'Grundkurs', !entwurf.istLK)}${segment('art', 'lk', 'Leistungskurs', entwurf.istLK)}</div></div>
          <label class="zelle"><span class="titel">Abiturfach</span>
            <select class="auswahl" data-e="abifach" aria-label="Abiturfach">
              <option value="0" ${entwurf.abifach === 0 ? 'selected' : ''}>Kein Abifach</option>
              ${[1, 2, 3, 4].map((n) => `<option value="${n}" ${entwurf.abifach === n ? 'selected' : ''}>${n}. Abifach${n === 4 ? ' (mündlich)' : ''}${vergeben(n) ? ` – bisher ${esc(fachName(vergeben(n)))}` : ''}</option>`).join('')}
            </select></label>
        </div>
        ${entwurf.abifach > 0 && vergeben(entwurf.abifach) ? `<p class="abschnitt-fuss">${esc(fachName(vergeben(entwurf.abifach)))} ist dann kein Abifach mehr.</p>` : ''}
      </section>

      <section class="abschnitt">
        <h2 class="abschnitt-titel">Belegung</h2>
        <div class="gruppe">
          <div class="zelle gestapelt"><div class="segmente" role="radiogroup" aria-label="Belegung">
            ${segment('belegung', 'alle', 'Q1 und Q2', belegung === 'alle')}${segment('belegung', 'q1', 'Nur Q1', belegung === 'q1')}${segment('belegung', 'zusatz', 'Zusatzkurs', belegung === 'zusatz')}</div></div>
        </div>
        <p class="abschnitt-fuss">„Nur Q1“: in Q2 abgewählt. „Zusatzkurs“: findet nur in Q2.1 und Q2.2 statt.</p>
      </section>

      <section class="abschnitt">
        <h2 class="abschnitt-titel">Einbringung</h2>
        <div class="gruppe">
          <label class="zelle"><span class="titel">Profilfach</span><input class="schalter" type="checkbox" data-e="profil" ${entwurf.istProfilfach ? 'checked' : ''}></label>
          <label class="zelle"><span class="titel">Immer einbringen (Pflicht)</span><input class="schalter" type="checkbox" data-e="pflicht" ${entwurf.pflicht || entwurf.istProfilfach ? 'checked' : ''} ${entwurf.istProfilfach ? 'disabled' : ''}></label>
        </div>
        <p class="abschnitt-fuss">${entwurf.istProfilfach
          ? `Beim Profilfach werden alle belegten Kurse eingebracht.${profil ? ` ${esc(fachName(profil))} ist dann kein Profilfach mehr.` : ''}`
          : 'Es gibt höchstens ein Profilfach. Alle seine belegten Kurse werden eingebracht.'}</p>
      </section>

      <section class="abschnitt">
        <h2 class="abschnitt-titel">Noten (0–15 Punkte)</h2>
        <div class="gruppe">${noten}</div>
      </section>

      ${belegt[2] ? `<section class="abschnitt">
        <h2 class="abschnitt-titel">Prognose</h2>
        <div class="gruppe">
          <label class="zelle"><span class="titel">Annahme für offene Q2-Noten</span>${punkteFeld({ wert: entwurf.annahmeQ2, prognose: null, label: 'Annahme für offene Q2-Noten, Punkte', daten: { e: 'annahme' }, schmal: true })}</label>
          <label class="zelle"><span class="titel">Quartalsnote Q2.1</span>${punkteFeld({ wert: entwurf.quartalsnote, prognose: null, label: 'Quartalsnote Q2.1, Punkte', daten: { e: 'quartal' }, schmal: true })}</label>
        </div>
        <p class="abschnitt-fuss">Leer lassen, damit die App aus deinen bisherigen Noten hochrechnet.</p>
      </section>` : ''}

      ${istNeu ? '' : `<section class="abschnitt"><div class="gruppe"><button class="zelle gefahr mitte" data-loeschen>Fach löschen</button></div></section>`}`;
    fertigKnopf.disabled = entwurf.name.trim() === '';
  };
  zeichneInhalt();

  // Tippen in Textfelder: nur den Entwurf ändern (nicht neu zeichnen, sonst schließt die Tastatur).
  inhalt.addEventListener('input', (ev) => {
    const feld = ev.target;
    const art = feld.dataset.e;
    if (art === 'name') {
      entwurf.name = feld.value;
      fertigKnopf.disabled = entwurf.name.trim() === '';
    } else if (art === 'note') entwurf.noten[Number(feld.dataset.h)] = liesPunkte(feld);
    else if (art === 'annahme') entwurf.annahmeQ2 = liesPunkte(feld);
    else if (art === 'quartal') entwurf.quartalsnote = liesPunkte(feld);
  });
  // Schalter und Auswahlen: Entwurf ändern und das Sheet neu zeichnen.
  inhalt.addEventListener('change', (ev) => {
    const feld = ev.target;
    if (feld.name === 'art') entwurf.istLK = feld.value === 'lk';
    else if (feld.name === 'belegung') {
      entwurf.istZusatzkurs = feld.value === 'zusatz';
      entwurf.nurQ1 = feld.value === 'q1';
    } else if (feld.dataset.e === 'abifach') entwurf.abifach = Number(feld.value);
    else if (feld.dataset.e === 'profil') {
      entwurf.istProfilfach = feld.checked;
      entwurf.pflicht = feld.checked; // Profilfach setzt Pflicht automatisch
    } else if (feld.dataset.e === 'pflicht') entwurf.pflicht = feld.checked;
    else return;
    haptik();
    zeichneInhalt();
  });
  inhalt.addEventListener('click', async (ev) => {
    if (!ev.target.closest('[data-loeschen]')) return;
    if (await frageLoeschen(original)) {
      schliesse();
      loescheFach(original.id);
    }
  });
  inhalt.addEventListener('keydown', (ev) => {
    if (ev.key === 'Enter' && ev.target.matches('input')) ev.target.blur();
  });

  el.querySelector('[data-abbrechen]').addEventListener('click', schliesse);
  fertigKnopf.addEventListener('click', () => {
    if (entwurf.name.trim() === '') return;
    // Es gibt nur ein Profilfach und jedes Abifach nur einmal: das bearbeitete Fach gewinnt.
    stand.faecher.forEach((f) => {
      if (f.id === entwurf.id) return;
      if (entwurf.istProfilfach && f.istProfilfach) {
        f.istProfilfach = false;
        f.pflicht = false;
      }
      if (entwurf.abifach !== 0 && f.abifach === entwurf.abifach) f.abifach = 0;
    });
    if (istNeu) stand.faecher.push(entwurf);
    else stand.faecher[stand.faecher.indexOf(original)] = entwurf;
    schliesse();
    geaendert({ neuZeichnen: true });
  });
  if (istNeu) el.querySelector('[data-e="name"]').focus();
}

function frageLoeschen(fach) {
  return bestaetige({
    titel: `„${fachName(fach)}“ löschen?`,
    text: 'Alle Noten dieses Fachs werden entfernt. Das lässt sich nicht rückgängig machen.',
    knopf: 'Fach löschen',
  });
}

function loescheFach(id) {
  stand.faecher = stand.faecher.filter((f) => f.id !== id);
  geaendert({ neuZeichnen: true });
}

/** Sheet "Info & Daten": Export, Import, Zurücksetzen, Hinweise. */
function oeffneInfoSheet() {
  const { el, schliesse } = oeffneEbene(
    `<div class="sheet" role="dialog" aria-modal="true" aria-label="Info und Daten">
      <div class="sheet-kopf"><span></span><h2>Info & Daten</h2><button class="rechts" data-fertig>Fertig</button></div>
      <div class="sheet-inhalt">
        <section class="abschnitt">
          <h2 class="abschnitt-titel">Sicherung und Übertragung</h2>
          <div class="gruppe">
            <button class="zelle aktion" data-export>Daten exportieren</button>
            <button class="zelle aktion" data-import>Daten importieren</button>
          </div>
          <p class="abschnitt-fuss">Die Export-Datei enthält alle Fächer, Noten und Einstellungen. Du kannst sie in der iPhone-App und in der Web-App wieder importieren.</p>
          <input type="file" accept="application/json,.json" hidden data-datei>
        </section>
        <section class="abschnitt">
          <div class="gruppe"><button class="zelle gefahr" data-zurueck>Alle Daten löschen</button></div>
        </section>
        <section class="abschnitt">
          <h2 class="abschnitt-titel">Hinweis</h2>
          <div class="gruppe"><div class="zelle" style="display:block">
            <p>Die Berechnung ist vereinfacht nach der APO-GOSt NRW. <b>Verbindlich ist allein die Berechnung deiner Schule.</b></p>
            <p style="margin-top:8px;color:var(--text-2)">Kursive Werte mit ≈ sind Prognosen: zuerst die Quartalsnote (nur Q2.1), dann deine Annahme für Q2, sonst der gerundete Durchschnitt deiner bisherigen Noten im Fach.</p>
          </div></div>
          <p class="abschnitt-fuss">Alle Daten bleiben auf diesem Gerät. Es wird nichts ins Internet übertragen. Abi-Rechner 2027 · Format-Version ${C.SCHEMA_VERSION}</p>
        </section>
      </div>
    </div>`,
  );
  const datei = el.querySelector('[data-datei]');
  el.querySelector('[data-fertig]').addEventListener('click', schliesse);
  el.querySelector('[data-export]').addEventListener('click', exportiereDatei);
  el.querySelector('[data-import]').addEventListener('click', () => datei.click());
  datei.addEventListener('change', async () => {
    const gewaehlt = datei.files?.[0];
    datei.value = '';
    if (gewaehlt && (await importiereDatei(gewaehlt))) schliesse();
  });
  el.querySelector('[data-zurueck]').addEventListener('click', async () => {
    const ok = await bestaetige({
      titel: 'Alle Daten löschen?',
      text: 'Alle Fächer, Noten und Prüfungen werden von diesem Gerät entfernt. Exportiere sie vorher, wenn du sie behalten willst.',
      knopf: 'Zurücksetzen',
    });
    if (!ok) return;
    stand = C.normalisiere(STARTDATEN);
    schliesse();
    geaendert({ neuZeichnen: true });
    zeigeHinweis('Alle Daten gelöscht');
  });
}

// ---------------------------------------------------------------------------
// 5. Export / Import
// ---------------------------------------------------------------------------

async function exportiereDatei() {
  const text = C.exportiere(stand, 'web');
  const name = `abi-rechner-${new Date().toISOString().slice(0, 10)}.json`;
  // Auf dem iPhone: Teilen-Menü ("In Dateien sichern", AirDrop …).
  try {
    const datei = new File([text], name, { type: 'application/json' });
    if (navigator.canShare?.({ files: [datei] })) {
      await navigator.share({ files: [datei], title: 'Abi-Rechner Daten' });
      return;
    }
  } catch (fehler) {
    if (fehler?.name === 'AbortError') return; // Teilen abgebrochen
  }
  // Sonst: normaler Download.
  try {
    const url = URL.createObjectURL(new Blob([text], { type: 'application/json' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = name;
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
    zeigeHinweis('Export gespeichert');
  } catch {
    zeigeHinweis('Export nicht möglich');
  }
}

/** Liest eine Datei ein und ersetzt nach Rückfrage alle Daten. Liefert true bei Erfolg. */
async function importiereDatei(datei) {
  let text;
  try {
    text = await datei.text();
  } catch {
    zeigeHinweis('Die Datei konnte nicht gelesen werden.');
    return false;
  }
  const gelesen = C.importiere(text);
  if (!gelesen.ok) {
    zeigeHinweis(gelesen.fehler);
    return false;
  }
  const anzahl = gelesen.stand.faecher.length;
  const ok = await bestaetige({
    titel: 'Daten überschreiben?',
    text: `Die Datei enthält ${anzahl} ${anzahl === 1 ? 'Fach' : 'Fächer'}. Deine jetzigen Daten werden vollständig ersetzt.`,
    knopf: 'Importieren und ersetzen',
  });
  if (!ok) return false;
  stand = gelesen.stand;
  geaendert({ neuZeichnen: true });
  zeigeHinweis('Import abgeschlossen');
  return true;
}

// ---------------------------------------------------------------------------
// 6. Ereignisse und Start
// ---------------------------------------------------------------------------

/** Schmale Titelleiste einblenden, sobald die große Überschrift weggescrollt ist. */
function aktualisiereLeiste() {
  leiste.classList.toggle('sichtbar', ansicht.scrollTop > 40);
}
ansicht.addEventListener('scroll', aktualisiereLeiste, { passive: true });

document.getElementById('tabbar').addEventListener('click', (ev) => {
  const knopf = ev.target.closest('[data-tab]');
  if (!knopf) return;
  if (knopf.dataset.tab === aktiverTab) {
    ansicht.scrollTo({ top: 0, behavior: 'smooth' }); // wie in iOS: erneutes Tippen scrollt nach oben
    return;
  }
  aktiverTab = knopf.dataset.tab;
  haptik();
  zeichne();
  ansicht.scrollTop = 0;
  aktualisiereLeiste();
});

// Eingaben in Punkte-Felder
ansicht.addEventListener('input', (ev) => {
  const feld = ev.target;
  const art = feld.dataset?.feld;
  if (!art || art === 'ziel') return;
  const wert = liesPunkte(feld);
  if (art === 'note') {
    const fach = stand.faecher.find((f) => f.id === feld.dataset.fach);
    if (fach) fach.noten[Number(feld.dataset.h)] = wert;
  } else if (art === 'quartal') {
    const fach = stand.faecher.find((f) => f.id === feld.dataset.fach);
    if (fach) fach.quartalsnote = wert;
  } else if (art === 'pruefung') {
    stand.pruefungen[Number(feld.dataset.abifach) - 1] = wert;
  }
  haptik();
  geaendert();
});
ansicht.addEventListener('change', (ev) => {
  if (ev.target.dataset?.feld !== 'ziel') return;
  stand.einstellungen.zielschnittZehntel = Number(ev.target.value);
  haptik();
  geaendert();
  ansicht.querySelector('[data-feld="ziel"]')?.focus({ preventScroll: true });
});
// "Fertig" auf der Tastatur schließt die Tastatur.
ansicht.addEventListener('keydown', (ev) => {
  if (ev.key === 'Enter' && ev.target.matches('input')) ev.target.blur();
});
// Beim Antippen eines Felds den Inhalt markieren – so überschreibt man direkt.
document.addEventListener('focusin', (ev) => {
  if (ev.target.matches?.('.punkte')) setTimeout(() => ev.target.select?.(), 0);
});

ansicht.addEventListener('click', async (ev) => {
  const knopf = ev.target.closest('[data-aktion]');
  if (!knopf) return;
  const aktion = knopf.dataset.aktion;
  if (aktion === 'info') oeffneInfoSheet();
  else if (aktion === 'zu-kursen') document.querySelector('[data-tab="kurse"]').click();
  else if (aktion === 'neu') oeffneFachSheet(null);
  else if (aktion === 'bearbeiten') {
    if (schliesseWischen()) return; // offene Wischgeste erst schließen
    oeffneFachSheet(knopf.dataset.fach);
  } else if (aktion === 'loeschen') {
    const fach = stand.faecher.find((f) => f.id === knopf.dataset.fach);
    if (fach && (await frageLoeschen(fach))) loescheFach(fach.id);
    else schliesseWischen();
  }
});

// ----- Wischgeste "nach links wischen = Löschen" in der Kursliste -----
let wisch = null; // die gerade bewegte Zeile
let offen = null; // die Zeile, deren Löschen-Knopf sichtbar ist
const WISCH_BREITE = 92;

function schliesseWischen() {
  if (!offen) return false;
  offen.style.transform = '';
  offen.parentElement.classList.remove('wischt');
  offen = null;
  return true;
}
ansicht.addEventListener('touchstart', (ev) => {
  const inhalt = ev.target.closest('.fach-inhalt');
  if (offen && offen !== inhalt) schliesseWischen();
  if (!inhalt || ev.touches.length !== 1 || ev.target.matches('input')) return;
  wisch = { el: inhalt, x: ev.touches[0].clientX, y: ev.touches[0].clientY, start: offen === inhalt ? -WISCH_BREITE : 0, aktiv: false };
}, { passive: true });
ansicht.addEventListener('touchmove', (ev) => {
  if (!wisch) return;
  const dx = ev.touches[0].clientX - wisch.x;
  const dy = ev.touches[0].clientY - wisch.y;
  if (!wisch.aktiv) {
    if (Math.abs(dy) > 10 && Math.abs(dy) > Math.abs(dx)) { wisch = null; return; } // senkrecht: normales Scrollen
    if (Math.abs(dx) < 10) return;
    wisch.aktiv = true;
    wisch.el.classList.add('zieht');
    wisch.el.parentElement.classList.add('wischt');
  }
  const x = Math.max(-WISCH_BREITE - 24, Math.min(0, wisch.start + dx));
  wisch.el.style.transform = `translateX(${x}px)`;
  wisch.x2 = x;
}, { passive: true });
ansicht.addEventListener('touchend', () => {
  if (!wisch) return;
  const { el, aktiv, x2 } = wisch;
  wisch = null;
  if (!aktiv) return;
  el.classList.remove('zieht');
  if (x2 < -WISCH_BREITE / 2) {
    el.style.transform = `translateX(${-WISCH_BREITE}px)`;
    offen = el;
  } else {
    el.style.transform = '';
    el.parentElement.classList.remove('wischt');
    offen = null;
  }
}, { passive: true });

// ----- Start -----
function starte() {
  const geladen = lade();
  stand = geladen.stand;
  ergebnis = C.berechne(stand);
  letzteBalken = { blockI: ergebnis.blockI, blockII: ergebnis.blockII, gesamt: ergebnis.gesamt };
  zeichne();
  if (geladen.hinweis) zeigeHinweis(geladen.hinweis);

  // Offline-Modus einschalten (nur über https oder localhost möglich).
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(() => { /* ohne Offline-Modus weiter */ });
  }
}
starte();
