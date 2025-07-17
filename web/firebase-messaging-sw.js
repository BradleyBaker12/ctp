// Import Firebase scripts for service worker
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"
);

// Initialize Firebase in the service worker context
firebase.initializeApp({
  apiKey: "AIzaSyExampleAPIKey1234567890",
  authDomain: "myapp-example.firebaseapp.com",
  projectId: "myapp-example",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message",
    payload
  );
  const notificationTitle = payload.notification?.title || "New Notification";
  const notificationOptions = {
    body: payload.notification?.body,
    icon: payload.notification?.icon,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
