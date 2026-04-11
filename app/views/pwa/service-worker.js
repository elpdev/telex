const CACHE_NAME = "telex-v1";
const CACHED_ASSETS = [
  "/favicon/favicon-96x96.png",
  "/favicon/favicon.ico",
  "/favicon/apple-touch-icon.png",
  "/favicon/web-app-manifest-192x192.png",
  "/favicon/web-app-manifest-512x512.png",
  "/favicon/site.webmanifest",
];

// Cache static assets on install
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_ASSETS)),
  );
  self.skipWaiting();
});

// Clean up old caches on activate
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key !== CACHE_NAME)
            .map((key) => caches.delete(key)),
        ),
      ),
  );
  self.clients.claim();
});

// Network-first strategy for HTML, cache-first for static assets
self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle same-origin requests
  if (url.origin !== self.location.origin) return;

  // HTML pages: network-first, fall back to cache
  if (request.headers.get("Accept")?.includes("text/html")) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() => caches.match(request)),
    );
    return;
  }

  // Static assets: cache-first, fall back to network
  if (request.url.match(/\.(js|css|png|jpg|svg|ico|woff2?)$/)) {
    event.respondWith(
      caches.match(request).then((cached) => {
        return (
          cached ||
          fetch(request).then((response) => {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
            return response;
          })
        );
      }),
    );
    return;
  }
});
