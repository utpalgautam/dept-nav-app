// scripts/addSingleLog.js
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, getDocs, serverTimestamp } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function addSingleLog() {
  console.log('🔍 Fetching one real building...');
  const bldgSnap = await getDocs(collection(db, 'buildings'));
  
  if (bldgSnap.empty) {
    console.log('❌ No buildings found. Cannot add a search log.');
    process.exit(1);
  }

  // Get the first building available
  const firstBuilding = bldgSnap.docs[0];
  
  const logData = {
    buildingId: firstBuilding.id,
    buildingName: firstBuilding.data().name,
    query: 'Test Search Query',
    timestamp: serverTimestamp(),
    platform: 'web'
  };

  console.log(`📝 Adding 1 search log for: ${logData.buildingName}...`);
  await addDoc(collection(db, 'searchLogs'), logData);
  
  console.log('✅ Single search log added successfully!');
  process.exit(0);
}

addSingleLog().catch(err => {
  console.error('❌ Error adding log:', err);
  process.exit(1);
});
