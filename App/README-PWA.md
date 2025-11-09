# Fillora.in - Mobile Application (PWA)

Fillora.in is now a Progressive Web App (PWA) that can be installed on mobile devices and used like a native app.

## Features

- ✅ **Installable** - Add to home screen on iOS and Android
- ✅ **Offline Support** - Works offline with service worker caching
- ✅ **App-like Experience** - Standalone mode without browser UI
- ✅ **Fast Loading** - Cached resources for instant loading
- ✅ **Mobile Optimized** - Touch-friendly interface with proper viewport settings

## Installation Instructions

### Android (Chrome/Edge)

1. Open the app in Chrome or Edge browser
2. Tap the menu (three dots) in the top right
3. Select "Add to Home screen" or "Install app"
4. Confirm installation
5. The app will appear on your home screen

### iOS (Safari)

1. Open the app in Safari browser
2. Tap the Share button (square with arrow)
3. Scroll down and tap "Add to Home Screen"
4. Customize the name if desired
5. Tap "Add"
6. The app will appear on your home screen

## Development

### Required Files

- `manifest.json` - App manifest with metadata and icons
- `service-worker.js` - Service worker for offline functionality
- `app.js` - PWA registration and installation handling

### App Icons

You'll need to create two icon files:
- `icon-192.png` (192x192 pixels)
- `icon-512.png` (512x512 pixels)

These should be placed in the root directory. For now, the app will work without them, but icons are recommended for a complete experience.

### Testing

1. Serve the app over HTTPS (required for PWA)
2. Open browser DevTools > Application tab
3. Check "Service Workers" and "Manifest" sections
4. Test offline functionality by going offline in DevTools

### Updating the Service Worker

When you update the service worker:
1. Change the `CACHE_NAME` version in `service-worker.js`
2. The new version will be installed on next visit
3. Users will see a prompt to update (if `app.js` is included)

## Browser Support

- ✅ Chrome (Android & Desktop)
- ✅ Edge (Android & Desktop)
- ✅ Safari (iOS)
- ✅ Samsung Internet
- ✅ Firefox (with limitations)

## Notes

- Service workers require HTTPS (or localhost for development)
- The app works offline for cached pages
- Notifications are supported but require user permission
- The app uses `standalone` display mode for a native-like experience

