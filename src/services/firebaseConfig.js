// src/services/firebaseConfig.js
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
  databaseURL: "https://dept-nav-app.firebaseio.com",
  storageBucket: "dept-nav-app.appspot.com",
  messagingSenderId: "816397169014",
  appId: "1:816397169014:web:8024b5c3efd682ee048a57"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
