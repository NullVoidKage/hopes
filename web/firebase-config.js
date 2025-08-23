// Firebase configuration for Flutter Web
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import { getAnalytics } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-analytics.js';
import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
import { getStorage } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js';
import { getDatabase } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-database.js';
import { getMessaging } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging.js';

const firebaseConfig = {
  apiKey: "AIzaSyDtu3oY49sezZNu_oIgNVh8uOLRyFaS-3I",
  authDomain: "hope-elearning-52e9b.firebaseapp.com",
  databaseURL: "https://hope-elearning-52e9b-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "hope-elearning-52e9b",
  storageBucket: "hope-elearning-52e9b.appspot.com",
  messagingSenderId: "105306415530",
  appId: "1:105306415530:web:2909b849ca4890693b8bd3",
  measurementId: "G-5M0P8SBPDD"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);
const firestore = getFirestore(app);
const storage = getStorage(app);
const database = getDatabase(app);
const messaging = getMessaging(app);

// Export for use in other modules
export { app, analytics, auth, firestore, storage, database, messaging };

// Make available globally for Flutter
if (typeof window !== 'undefined') {
  window.firebase = {
    app: app,
    auth: auth,
    firestore: firestore,
    storage: storage,
    database: database,
    messaging: messaging,
    analytics: analytics
  };
}
