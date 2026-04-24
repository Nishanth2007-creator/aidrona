const admin = require('firebase-admin');
const path = require('path');

const keyFile = path.join(__dirname, '..', 'backend', 'service-account-key.json');
const serviceAccount = require(keyFile);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'aidrona'
  });
}

const db = admin.firestore('default'); // NO PARENTHESES

async function run() {
  console.log('Testing Write to Firestore with databaseId "default"...');
  try {
    const res = await db.collection('test').doc('hello').set({ world: true });
    console.log('Write Success:', res.writeTime);
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

run();
