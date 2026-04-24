const admin = require('firebase-admin');
const path = require('path');

// Go up one level from scratch to root, then into backend
const keyFile = path.join(__dirname, '..', 'backend', 'service-account-key.json');
console.log('Probing with key:', keyFile);

try {
  const serviceAccount = require(keyFile);
  console.log('Service Account Project ID:', serviceAccount.project_id);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });

  const db = admin.firestore();
  console.log('Attempting to list collections...');
  db.listCollections()
    .then(collections => {
      console.log('Successfully connected!');
      console.log('Collections count:', collections.length);
      collections.forEach(c => console.log('Found collection:', c.id));
      process.exit(0);
    })
    .catch(err => {
      console.error('Connection failed with error:', err);
      process.exit(1);
    });
} catch (e) {
  console.error('Failed to load key or initialize:', e);
  process.exit(1);
}
