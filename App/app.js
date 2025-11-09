// Progressive Web App Registration and Installation
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js')
      .then((registration) => {
        console.log('ServiceWorker registration successful');
        
        // Check for updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              // New service worker available, show update notification
              if (confirm('A new version of Fillora is available. Would you like to update?')) {
                newWorker.postMessage({ action: 'skipWaiting' });
                window.location.reload();
              }
            }
          });
        });
      })
      .catch((error) => {
        console.log('ServiceWorker registration failed:', error);
      });
  });

  // Listen for messages from service worker
  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data && event.data.action === 'skipWaiting') {
      window.location.reload();
    }
  });
}

// Install prompt handling
let deferredPrompt;
const installButton = document.getElementById('install-button');

window.addEventListener('beforeinstallprompt', (e) => {
  // Prevent Chrome 67 and earlier from automatically showing the prompt
  e.preventDefault();
  // Stash the event so it can be triggered later
  deferredPrompt = e;
  
  // Show install button if it exists
  if (installButton) {
    installButton.style.display = 'block';
    installButton.addEventListener('click', () => {
      // Show the install prompt
      deferredPrompt.prompt();
      // Wait for the user to respond to the prompt
      deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === 'accepted') {
          console.log('User accepted the install prompt');
        } else {
          console.log('User dismissed the install prompt');
        }
        deferredPrompt = null;
        if (installButton) {
          installButton.style.display = 'none';
        }
      });
    });
  }
});

// Handle successful installation
window.addEventListener('appinstalled', (evt) => {
  console.log('App installed successfully');
  if (installButton) {
    installButton.style.display = 'none';
  }
});

// Check if app is already installed
if (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone) {
  document.body.classList.add('standalone');
  console.log('Running as standalone app');
}

