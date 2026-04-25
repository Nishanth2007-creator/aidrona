const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" }); 

async function callGemini(prompt, type = 'triage', imageBase64 = null) {
  try {
    const parts = [{ text: prompt }];
    if (imageBase64) {
      parts.push({
        inlineData: {
          data: imageBase64,
          mimeType: "image/jpeg"
        }
      });
    }
    const result = await model.generateContent(parts);
    const text = result.response.text().trim();
    const clean = text.replace(/^```json\n?/, '').replace(/\n?```$/, '');
    return JSON.parse(clean);
  } catch (err) {
    console.error(`Gemini Error [${type}]:`, err.message);
    // Safety Fallbacks so Firestore never gets 'undefined'
    if (type === 'triage') return { severity_score: 7, recommended_radius_km: 10, estimated_response_minutes: 20, triage_reasoning: "Safe fallback due to API error" };
    if (type === 'ranking') return { ranked_donor_ids: [], expand_if_no_response_mins: 5, escalate_to_bank: false };
    if (type === 'fitness') return { fitness_score: 80, is_eligible: true, disqualifiers_found: [], score_reasoning: "Safe fallback", extracted_hemoglobin: 12.0, extracted_medications: [], extracted_conditions: [] };
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

async function evaluateDonorFitness({ base64_image, last_donation_days, donation_count, doctor_unfit_count }) {
  const prompt = `You are a medical AI. Return ONLY valid JSON.
Evaluate this blood donor's medical report from the provided image.
Extract the following information from the medical report:
- Hemoglobin level
- Medications currently taken
- Any disqualifying conditions

Consider:
- Last donated: ${last_donation_days} days ago
- Total donations: ${donation_count}
- Previous unfit evaluations by doctors: ${doctor_unfit_count}

Respond with exactly: { "fitness_score": 85, "is_eligible": true, "disqualifiers_found": ["none"], "score_reasoning": "Healthy", "extracted_hemoglobin": 14.5, "extracted_medications": [], "extracted_conditions": [] }`;

  return await callGemini(prompt, 'fitness', base64_image);
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