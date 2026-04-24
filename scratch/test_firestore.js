const admin = require('firebase-admin');
const path = require('path');

const keyFile = path.join(__dirname, '..', 'backend', 'service-account-key.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(require(keyFile)),
    projectId: 'aidrona'
  });

  const db = admin.firestore();
  console.log('Attempting to connect to Firestore...');

  db.collection('test').doc('ping').set({ time: new Date() })
    .then(() => {
      console.log('✅ Connection successful! Firestore is active.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Connection failed:', err.message);
      if (err.message.includes('billing')) {
        console.error('Note: It looks like billing is not enabled for this project.');
      }
      process.exit(1);
    });
} catch (err) {
  console.error('Error during initialization:', err.message);
  process.exit(1);
}
