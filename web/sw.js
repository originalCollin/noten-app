// sw.js – Service Worker: sorgt dafür, dass die Web-App auch ohne Internet funktioniert.
// Beim ersten Besuch werden alle Dateien gespeichert. Danach wird sofort aus dem
// Speicher geantwortet und im Hintergrund nach einer neueren Version geschaut.
// Wichtig: Bei Änderungen an der App die VERSION erhöhen.

const VERSION = 'abi-rechner-v1';
const DATEIEN = [
  './',
  './index.html',
  './styles.css',
  './app.js',
  './calc.js',
  './storage.js',
  './startdaten.js',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(VERSION).then((cache) => cache.addAll(DATEIEN)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  // Alte Versionen aufräumen.
  event.waitUntil(
    caches.keys()
      .then((namen) => Promise.all(namen.filter((n) => n !== VERSION).map((n) => caches.delete(n))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const anfrage = event.request;
  if (anfrage.method !== 'GET' || new URL(anfrage.url).origin !== self.location.origin) return;
  event.respondWith(
    caches.open(VERSION).then(async (cache) => {
      const gespeichert = await cache.match(anfrage, { ignoreSearch: true });
      const frisch = fetch(anfrage)
        .then((antwort) => {
          if (antwort.ok) cache.put(anfrage, antwort.clone());
          return antwort;
        })
        .catch(() => null);
      if (gespeichert) {
        event.waitUntil(frisch);
        return gespeichert;
      }
      const antwort = await frisch;
      if (antwort) return antwort;
      // Offline und nicht gespeichert: bei Seitenaufrufen die Startseite liefern.
      if (anfrage.mode === 'navigate') return (await cache.match('./index.html')) || Response.error();
      return Response.error();
    }),
  );
});
