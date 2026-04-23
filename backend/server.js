require('dotenv').config({ path: __dirname + '/.env' });
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const homeRoutes = require('./routes/home');
const requestRoutes = require('./routes/request');
const responseRoutes = require('./routes/response');
const medicalRoutes = require('./routes/medical');
const donorRoutes = require('./routes/donor');
const escalateRoutes = require('./routes/escalate');
const adminRoutes = require('./routes/admin');
const notificationRoutes = require('./routes/notifications');

// Start background cron job
require('./jobs/radiusExpansion');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api', homeRoutes);
app.use('/api/request', requestRoutes);
app.use('/api/response', responseRoutes);
app.use('/api/medical', medicalRoutes);
app.use('/api/donor', donorRoutes);
app.use('/api/escalate', escalateRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'aidrona-backend' }));

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`AiDrona backend running on port ${PORT}`));
