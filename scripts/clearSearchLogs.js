// scripts/clearSearchLogs.js
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, writeBatch } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function clearLogs() {
  console.log('🧹 Clearing all searchLogs...');
  const logsSnap = await getDocs(collection(db, 'searchLogs'));
  const total = logsSnap.size;

  if (total === 0) {
    console.log('✅ Collection is already empty.');
    process.exit(0);
  }

  // Firestore batches only accept 500 operations. We'll process in chunks of 500.
  const CHUNK_SIZE = 500;
  let deletedCount = 0;

  for (let i = 0; i < total; i += CHUNK_SIZE) {
    const batch = writeBatch(db);
    const chunk = logsSnap.docs.slice(i, i + CHUNK_SIZE);
    
    chunk.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    deletedCount += chunk.length;
    process.stdout.write(`  ✓ Deleted ${deletedCount} / ${total}\r`);
  }

  console.log('\n✅ Successfully removed all searchLog documents!');
  process.exit(0);
}

clearLogs().catch(err => {
  console.error('❌ Error clearing logs:', err);
  process.exit(1);
});
