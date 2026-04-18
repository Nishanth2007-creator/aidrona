const cron = require('node-cron');
const {
  getOpenCrisisRequests, updateCrisisRequest,
  getDonorsWithinRadius, createDonorResponse, createNotification,
  getNearestBloodBank,
} = require('../db/firestore');
const { rankDonors } = require('../ai/gemini');

// Runs every 2 minutes
cron.schedule('*/2 * * * *', async () => {
  console.log('[Cron] Checking open crisis requests...');
  try {
    const openRequests = await getOpenCrisisRequests();

    for (const crisis of openRequests) {
      const createdAt = crisis.created_at?.toDate ? crisis.created_at.toDate() : new Date(crisis.created_at);
      const ageMinutes = (Date.now() - createdAt.getTime()) / 60000;

      const lat = crisis.location.latitude;
      const lng = crisis.location.longitude;

      // After 4 min without acceptance → expand radius by 5 km
      if (ageMinutes > 4 && ageMinutes <= 20) {
        const newRadius = (crisis.current_radius_km || 5) + 5;
        await updateCrisisRequest(crisis.id, { current_radius_km: newRadius });
        console.log(`[Cron] Crisis ${crisis.id} radius expanded to ${newRadius} km`);

        // Re-query and notify new donors
        const donors = await getDonorsWithinRadius(lat, lng, newRadius, crisis.blood_type);
        if (donors.length > 0) {
          const ranking = await rankDonors({
            blood_type: crisis.blood_type,
            urgency_score: crisis.severity_score || 7,
            donor_candidates: donors.slice(0, 20),
          });
          for (const donor_id of (ranking.ranked_donor_ids || []).slice(0, 5)) {
            await createDonorResponse({ crisis_id: crisis.id, donor_id });
            await createNotification({
              user_id: donor_id,
              type: 'donor_popup',
              title: 'Emergency Blood Request',
              body: `${crisis.blood_type} blood needed urgently nearby`,
              deep_link: '/donor/incoming',
              crisis_id: crisis.id,
            });
          }
        }
      }

      // After 20 min with no response → escalate to blood bank
      if (ageMinutes > 20) {
        const bank = await getNearestBloodBank(lat, lng, crisis.blood_type);
        await updateCrisisRequest(crisis.id, {
          status: 'escalated_to_bank',
          escalated_bank_id: bank?.id || null,
        });

        if (bank) {
          await createNotification({
            user_id: crisis.requester_id,
            type: 'escalation',
            title: 'Blood Bank Contacted',
            body: `${bank.name} has been automatically alerted for your ${crisis.blood_type} request.`,
            deep_link: '/requests',
          });
          console.log(`[Cron] Crisis ${crisis.id} escalated to blood bank: ${bank.name}`);
        }
      }
    }
  } catch (err) {
    console.error('[Cron] Error in radius expansion job:', err);
  }
});

console.log('[Cron] Radius expansion job started (every 2 minutes)');
