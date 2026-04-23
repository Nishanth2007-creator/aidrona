require('dotenv').config({ path: './backend/.env' });
const { triageBloodRequest } = require('../backend/ai/gemini');

async function testAI() {
  console.log('Testing NEW FREE TIER Gemini AI connectivity...');
  try {
    const result = await triageBloodRequest({
      blood_type: 'O+',
      urgency: 'critical',
      location: { lat: 12.9716, lng: 77.5946 },
      time_of_day: '19:00'
    });
    console.log('AI Result:', JSON.stringify(result, null, 2));
    if (result.triage_reasoning && result.triage_reasoning.includes('(Mock Fallback)')) {
      console.log('⚠️ AI is STILL in MOCK MODE.');
    } else if (Object.keys(result).length === 0) {
      console.log('❌ AI returned empty result.');
    } else {
      console.log('✅ AI IS WORKING PERFECTLY ON THE FREE TIER!');
    }
  } catch (err) {
    console.error('❌ Script error:', err.message);
  }
}

testAI();
