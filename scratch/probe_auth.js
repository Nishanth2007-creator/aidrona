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

async function run() {
  console.log('Testing Firebase Auth connectivity...');
  try {
    const list = await admin.auth().listUsers(1);
    console.log('Auth Success! Users found:', list.users.length);
    process.exit(0);
  } catch (err) {
    console.error('Auth Error:', err.message);
    process.exit(1);
  }
}

run();
