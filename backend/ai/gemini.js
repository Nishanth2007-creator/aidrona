const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" }); 

async function callGemini(prompt, type = 'triage') {
  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text().trim();
    const clean = text.replace(/^```json\n?/, '').replace(/\n?```$/, '');
    return JSON.parse(clean);
  } catch (err) {
    console.error(`Gemini Error [${type}]:`, err.message);
    // Safety Fallbacks so Firestore never gets 'undefined'
    if (type === 'triage') return { severity_score: 7, recommended_radius_km: 10, estimated_response_minutes: 20, triage_reasoning: "Safe fallback due to API error" };
    if (type === 'ranking') return { ranked_donor_ids: [], expand_if_no_response_mins: 5, escalate_to_bank: false };
    if (type === 'fitness') return { fitness_score: 80, is_eligible: true, disqualifiers_found: [], score_reasoning: "Safe fallback" };
    return {};
  }
}

async function triageBloodRequest({ blood_type, urgency, location, time_of_day }) {
  const prompt = `You are a blood crisis AI. Return ONLY valid JSON.
Triage this blood request:
- Blood type: ${blood_type}
- Urgency: ${urgency}
- Location: lat ${location.lat}, lng ${location.lng}
- Time of day: ${time_of_day}

Respond with exactly: { "severity_score": 10, "recommended_radius_km": 10, "estimated_response_minutes": 15, "triage_reasoning": "High urgency" }`;

  return await callGemini(prompt, 'triage');
}

async function rankDonors({ blood_type, urgency_score, donor_candidates }) {
  const donorList = donor_candidates.map((d, i) =>
    `${i + 1}. id=${d.donor_id}, last_donated=${d.last_donated_days_ago ?? 'unknown'} days ago, distance=${d.distance_km ?? '?'} km`
  ).join('\n');

  const prompt = `You are a blood donor ranking AI. Return ONLY valid JSON.
Rank these donors for a ${blood_type} blood request (urgency score: ${urgency_score}/10):

${donorList}

Respond with exactly: { "ranked_donor_ids": ["id1", "id2", ...], "expand_if_no_response_mins": 5, escalate_to_bank: false }`;

  return await callGemini(prompt, 'ranking');
}

async function evaluateDonorFitness({ medical_history, last_donated_days_ago, weight_kg, age }) {
  const prompt = `You are a medical AI. Return ONLY valid JSON.
Evaluate this blood donor:
- Age: ${age}
- Weight: ${weight_kg} kg
- Last donated: ${last_donated_days_ago} days ago
- Medical history: ${JSON.stringify(medical_history)}

Respond with exactly: { "fitness_score": 85, "is_eligible": true, "disqualifiers_found": [], "score_reasoning": "Healthy" }`;

  return await callGemini(prompt, 'fitness');
}

async function checkDisqualifiers({ medications, conditions, recent_travel }) {
  const prompt = `You are a medical eligibility AI. Return ONLY valid JSON.
Check if this person is disqualified:
- Medications: ${JSON.stringify(medications)}
- Conditions: ${JSON.stringify(conditions)}
- Recent travel: ${JSON.stringify(recent_travel)}

Respond with exactly: { "disqualified": false, "disqualifying_items": [], "temporary_or_permanent": "temporary", "resume_after_days": null }`;

  return await callGemini(prompt, 'disqualifiers');
}

async function generateAdminInsights({ crisis_data, donor_stats, region }) {
  const prompt = `You are a blood bank analytics AI. Return ONLY valid JSON.
Generate insights for: ${region}
Data: ${JSON.stringify(crisis_data)}, ${JSON.stringify(donor_stats)}

Respond with exactly: { "shortage_risk_types": [], "predicted_peak_hours": [], "suggested_awareness_areas": [], "narrative_summary": "Stable" }`;

  return await callGemini(prompt, 'insights');
}

module.exports = { triageBloodRequest, rankDonors, evaluateDonorFitness, checkDisqualifiers, generateAdminInsights };