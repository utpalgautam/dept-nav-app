const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

const firebaseConfig = {
    apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
    projectId: "dept-nav-app",
    authDomain: "dept-nav-app.firebaseapp.com",
    databaseURL: "https://dept-nav-app.firebaseio.com",
    storageBucket: "dept-nav-app.firebasestorage.app",
    messagingSenderId: "816397169014",
    appId: "1:816397169014:web:8024b5c3efd682ee048a57"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const collectionsToCheck = ['buildings', 'faculty', 'halls', 'labs', 'users', 'locations', 'searchLogs'];

async function checkAll() {
    for (const collName of collectionsToCheck) {
        console.log(`\n=== Collection: ${collName} ===`);
        try {
            const snapshot = await getDocs(collection(db, collName));
            console.log(`Count: ${snapshot.size}`);
            snapshot.forEach(docSnap => {
                console.log(`Document [${docSnap.id}]:`, JSON.stringify(docSnap.data(), null, 2));
            });
        } catch (err) {
            console.error(`Error checking '${collName}':`, err.message);
        }
    }
}

checkAll();
