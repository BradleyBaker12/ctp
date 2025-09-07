// Import Firebase scripts for service worker
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"
);

// Initialize Firebase in the service worker context (use real project config)
firebase.initializeApp({
  apiKey: "AIzaSyA6C6DRdzG674nFLiRJYugQ8hRlHUp8T0I",
  authDomain: "ctp-central-database.firebaseapp.com",
  projectId: "ctp-central-database",
  messagingSenderId: "656287296553",
  appId: "1:656287296553:web:75f8a76bd7a63a96408038",
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
