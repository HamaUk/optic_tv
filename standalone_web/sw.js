// Service Worker for Optic TV PWA
const CACHE_NAME = 'optic-tv-v1';
const urlsToCache = [
  '/index.html',
  '/manifest.json',
  'https://cdn.jsdelivr.net/npm/hls.js@latest',
  'https://cdn.jsdelivr.net/npm/video.js@8.6.1/dist/video.min.js',
  'https://cdn.jsdelivr.net/npm/video.js@8.6.1/dist/video-js.min.css'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll(urlsToCache);
      })
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  // Only handle GET requests
  if (event.request.method !== 'GET') return;

  // IMPORTANT FIX: Do NOT intercept cross-origin requests (like HLS streams, .ts files, PocketBase APIs)
  // Intercepting them in the SW strips credentials and breaks CORS!
  const url = new URL(event.request.url);
  if (!url.origin.includes(self.location.hostname) && !urlsToCache.includes(event.request.url)) {
    return; // Let the browser natively handle these requests
  }

  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Cache hit - return response
        if (response) {
          return response;
        }

        return fetch(event.request).then((response) => {
          // Check if valid response
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          // Clone the response
          const responseToCache = response.clone();
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseToCache);
            });

          return response;
        }).catch(err => {
           console.error('[SW] Fetch failed for', event.request.url, err);
           throw err; // Let it fail cleanly rather than returning an invalid promise
        });
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Background sync for offline support
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-channels') {
    event.waitUntil(syncChannels());
  }
});

async function syncChannels() {
  // Sync channels when back online
  try {
    const response = await fetch('/api/sync');
    if (response.ok) {
      console.log('Channels synced successfully');
    }
  } catch (error) {
    console.error('Sync failed:', error);
  }
}

// Push notification support
self.addEventListener('push', (event) => {
  const options = {
    body: event.data ? event.data.text() : 'New channel available!',
    icon: 'data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 100 100\'><rect width=\'100\' height=\'100\' rx=\'20\' fill=\'%230f172a\'/><text x=\'50\' y=\'65\' font-size=\'50\' text-anchor=\'middle\' fill=\'%2338bdf8\'>📺</text></svg>',
    badge: 'data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 100 100\'><rect width=\'100\' height=\'100\' rx=\'20\' fill=\'%230f172a\'/><text x=\'50\' y=\'65\' font-size=\'50\' text-anchor=\'middle\' fill=\'%2338bdf8\'>📺</text></svg>',
    vibrate: [200, 100, 200],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    }
  };

  event.waitUntil(
    self.registration.showNotification('Optic TV', options)
  );
});
