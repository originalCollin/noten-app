// Startdaten der Web-App: meine Noten laut Schullaufbahnbescheinigung Q1.2 (17.07.2026).
// Hinweis: Ist das Repository öffentlich, kann jeder diese Datei lesen.
const N = null;
const fach = (id, name, o = {}) => ({
  id, name, istLK: !!o.lk, abifach: o.af ?? 0, istZusatzkurs: !!o.zk, nurQ1: !!o.q1,
  pflicht: !!o.profil, istProfilfach: !!o.profil, noten: o.n ?? [N, N, N, N], annahmeQ2: o.an ?? N, quartalsnote: N,
});

export const STARTDATEN = {
  format: 'abi-rechner-nrw',
  schemaVersion: 1,
  einstellungen: { zielschnittZehntel: 13 },
  pruefungen: [N, N, N, N],
  faecher: [
    fach('mathematik', 'Mathematik', { lk: 1, af: 1, n: [12, 13, N, N] }),
    fach('geographie', 'Geographie', { lk: 1, af: 2, n: [12, 14, N, N] }),
    fach('deutsch', 'Deutsch', { af: 3, n: [12, 13, N, N] }),
    fach('englisch', 'Englisch', { af: 4, n: [13, 13, N, N] }),
    fach('sport', 'Sport', { n: [13, 13, N, N] }),
    fach('russisch', 'Russisch ab EF', { profil: 1, n: [11, 9, N, N] }),
    fach('vokalpraktisch', 'Vokalpraktischer GK', { q1: 1, n: [14, 15, N, N] }),
    fach('philosophie', 'Philosophie', { n: [13, 12, N, N] }),
    fach('sozialwissenschaften', 'Sozialwissenschaften', { n: [15, 14, N, N], an: 14 }),
    fach('biologie', 'Biologie', { n: [14, 14, N, N] }),
    fach('geschichte', 'Geschichte', { zk: 1 }),
  ],
};
