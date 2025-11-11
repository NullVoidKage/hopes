// Firebase Cloud Messaging Service Worker for Web Push Notifications
// This file must be in the web/ directory root

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
const firebaseConfig = {
  apiKey: "AIzaSyDtu3oY49sezZNu_oIgNVh8uOLRyFaS-3I",
  authDomain: "hope-elearning-52e9b.firebaseapp.com",
  databaseURL: "https://hope-elearning-52e9b-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "hope-elearning-52e9b",
  storageBucket: "hope-elearning-52e9b.firebasestorage.app",
  messagingSenderId: "105306415530",
  appId: "1:105306415530:web:2909b849ca4890693b8bd3",
  measurementId: "G-5M0P8SBPDD"
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

