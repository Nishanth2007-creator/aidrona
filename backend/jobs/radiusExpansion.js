const cron = require('node-cron');
const {
  getOpenCrisisRequests, updateCrisisRequest,
  getDonorsWithinRadius, createDonorResponse, createNotification,
  getNearestBloodBank, getDonorResponsesByCrisis,
} = require('../db/firestore');

let isJobRunning = false;

// Runs every 2 minutes
cron.schedule('*/2 * * * *', async () => {
  if (isJobRunning) {
    console.log('[Cron] Job already in progress, skipping...');
    return;
  }
  isJobRunning = true;
  console.log('[Cron] Checking open crisis requests at', new Date().toISOString());
  try {
    const openRequests = await getOpenCrisisRequests();

    for (const crisis of openRequests) {
      const createdAt = crisis.created_at?.toDate ? crisis.created_at.toDate() : new Date(crisis.created_at);
      const ageMinutes = (Date.now() - createdAt.getTime()) / 60000;

      const lat = crisis.location.latitude;
      const lng = crisis.location.longitude;

      // After 4 min without acceptance → expand radius by 5 km
      if (ageMinutes > 4) {
        const currentRadius = crisis.current_radius_km || 5;

        if (currentRadius < 20) {
          const newRadius = currentRadius + 5;
          await updateCrisisRequest(crisis.id, { current_radius_km: newRadius });
          console.log(`[Cron] Crisis ${crisis.id} radius expanded to ${newRadius} km`);

          // Re-query and notify new donors
          const donors = await getDonorsWithinRadius(lat, lng, newRadius, crisis.blood_type);
          if (donors.length > 0) {
            const sortedDonors = donors
              .sort((a, b) => (a.distance_km || 0) - (b.distance_km || 0))
              .slice(0, 10);

            const existingResponses = await getDonorResponsesByCrisis(crisis.id);
            const alreadyNotified = new Set(existingResponses.map((r) => r.donor_id));

            let notifiedCount = 0;
            for (const donor of sortedDonors) {
              if (alreadyNotified.has(donor.donor_id)) continue;
              if (notifiedCount >= 5) break;

              await createDonorResponse({ crisis_id: crisis.id, donor_id: donor.donor_id });
              await createNotification({
                user_id: donor.donor_id,
                type: 'donor_popup',
                title: 'Emergency Blood Request',
                body: `${crisis.blood_type} blood needed urgently nearby`,
                deep_link: '/donor/incoming',
                crisis_id: crisis.id,
              });
              notifiedCount++;
            }
          }
        } else if (ageMinutes > 15 && crisis.status === 'open') {
          // If radius is already 20km and still no donor after 15 mins (allowing some time at 20km)
          // or just close it if it reaches 20km and another cron cycle passes.
          // The user said: "if the request radius gone above 20 km tell no able to find donor and close the request"
          
          await updateCrisisRequest(crisis.id, { status: 'closed_no_donor' });
          await createNotification({
            user_id: crisis.requester_id,
            type: 'request_closed',
            title: 'No Donors Found',
            body: `We were unable to find a ${crisis.blood_type} donor within 20km. The request has been closed.`,
            deep_link: '/requests',
            crisis_id: crisis.id,
          });
          console.log(`[Cron] Crisis ${crisis.id} closed: no donors found within 20km`);
        }
      }
    }
  } catch (err) {
    console.error('[Cron] Error in radius expansion job:', err);
  } finally {
    isJobRunning = false;
  }
});

console.log('[Cron] Radius expansion job started (every 2 minutes)');
