// scripts/seedSearchLogs.js
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, getDocs, writeBatch, Timestamp } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const queries = ['Room 301', 'Lab 2', 'HOD Office', 'Seminar Hall', 'Canteen', 'Washroom', 'Prof. Sharma', 'Computer Lab', 'Exam Hall'];

function randomInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function pickRandom(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

function timestampDaysAgo(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(randomInt(7, 21), randomInt(0, 59), 0, 0);
  return Timestamp.fromDate(d);
}

async function reseed() {
  console.log('🧹 Clearing old searchLogs...');
  const logsSnap = await getDocs(collection(db, 'searchLogs'));
  const batch1 = writeBatch(db);
  logsSnap.docs.slice(0, 480).forEach(doc => batch1.delete(doc.ref)); // Delete a chunk of old logs
  await batch1.commit();

  console.log('🔍 Fetching real buildings...');
  const bldgSnap = await getDocs(collection(db, 'buildings'));
  const buildings = bldgSnap.docs.map(doc => ({ id: doc.id, name: doc.data().name }));

  if (buildings.length === 0) {
    console.log('❌ No buildings found. Stop.'); return;
  }

  console.log('🌱 Generating new logs...');
  const logs = [];
  const weights = [35, 28, 22, 15, 18, 10]; // Random weights for chart shape
  
  for (let daysAgo = 29; daysAgo >= 0; daysAgo--) {
    buildings.forEach((building, idx) => {
      const w = weights[idx % weights.length];
      const recency = daysAgo < 7 ? 1.4 : 1.0;
      const count = Math.round(randomInt(w * 0.5, w) * recency);
      
      for (let i = 0; i < count; i++) {
        logs.push({
          buildingId: building.id,
          buildingName: building.name, // The KEY FIELD that must match exactly
          query: pickRandom(queries),
          timestamp: timestampDaysAgo(daysAgo),
          platform: 'web'
        });
      }
    });
  }

  console.log(`📝 Writing ${logs.length} documents...`);
  const BATCH = 50;
  for (let i = 0; i < logs.length; i += BATCH) {
    const slice = logs.slice(i, i + BATCH);
    await Promise.all(slice.map(log => addDoc(collection(db, 'searchLogs'), log)));
    process.stdout.write(`  ✓ ${Math.min(i + BATCH, logs.length)} / ${logs.length}\r`);
  }
  
  console.log('\n✅ Reseed complete!');
  process.exit(0);
}

reseed().catch(err => { console.error('Error:', err); process.exit(1); });
