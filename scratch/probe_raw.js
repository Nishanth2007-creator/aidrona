const { Firestore } = require('@google-cloud/firestore');
const path = require('path');

const keyFile = path.join(__dirname, '..', 'backend', 'service-account-key.json');
const serviceAccount = require(keyFile);

const db = new Firestore({
  projectId: serviceAccount.project_id,
  keyFilename: keyFile,
});

async function run() {
  console.log('Testing raw @google-cloud/firestore...');
  try {
    const collections = await db.listCollections();
    console.log('Collections:', collections.length);
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    console.error('Full Error:', JSON.stringify(err, null, 2));
    process.exit(1);
  }
}

run();
