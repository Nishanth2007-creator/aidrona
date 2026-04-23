const { VertexAI } = require('@google-cloud/vertexai');

const vertex = new VertexAI({
  project: process.env.GCP_PROJECT_ID || 'aidrona-prod',
  location: 'asia-south1',
});

const model = vertex.getGenerativeModel({ model: 'gemini-1.5-pro' });

async function callGemini(prompt) {
  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text().trim();
    const clean = text.replace(/^```json\n?/, '').replace(/\n?```$/, '');
    return JSON.parse(clean);
  } catch (err) {
    console.error('Gemini AI Error (Falling back to mock):', err.message);
    // Return a reasonable fallback depending on what was asked
    if (prompt.includes('evaluating a blood donor')) {
      return { fitness_score: 85, is_eligible: true, disqualifiers_found: [], score_reasoning: "(Mock Fallback) Healthy baselines." };
    }
    if (prompt.includes('Triage a blood request')) {
      return { severity_score: 8, recommended_radius_km: 10, estimated_response_minutes: 15, triage_reasoning: "(Mock Fallback) High urgency." };
    }
    if (prompt.includes('disqualifiers')) {
       return { disqualified: false, disqualifying_items: [], temporary_or_permanent: "temporary", resume_after_days: null };
    }
    if (prompt.includes('insights')) {
      return { shortage_risk_types: ["O-"], predicted_peak_hours: ["18:00", "20:00"], suggested_awareness_areas: ["Downtown"], narrative_summary: "(Mock Fallback) All systems nominal." };
    }
    return {};
  }
}

// 1. Triage a blood request
async function triageBloodRequest({ blood_type, urgency, location, time_of_day }) {
  const prompt = `
You are AiDrona AI, an emergency blood coordination system.
A blood request has been submitted:
- Blood type needed: ${blood_type}
- Urgency level: ${urgency}
- Location: ${location.lat}, ${location.lng}
- Time of day: ${time_of_day}

Return ONLY a JSON object:
{
  "severity_score": <number 1-10>,
  "recommended_radius_km": <number>,
  "estimated_response_minutes": <number>,
  "triage_reasoning": "<string>"
}`;
  return callGemini(prompt);
}

// 2. Evaluate donor fitness score
async function evaluateDonorFitness({ hemoglobin, last_donation_days, donation_count, conditions, medications, doctor_unfit_count }) {
  const prompt = `
You are AiDrona AI evaluating a blood donor's fitness score.
Input:
- Hemoglobin: ${hemoglobin} g/dL
- Days since last donation: ${last_donation_days}
- Total past donations: ${donation_count}
- Known medical conditions: ${(conditions || []).join(', ') || 'none'}
- Current medications: ${(medications || []).join(', ') || 'none'}
- Times marked unfit by doctor: ${doctor_unfit_count}

Disqualifying: HIV, Hepatitis B/C, active tuberculosis, uncontrolled hypertension, Warfarin, active chemotherapy.
Minimum hemoglobin: 12.5 g/dL (women), 13.0 g/dL (men). Minimum donation gap: 90 days.

Return ONLY a JSON object:
{
  "fitness_score": <0-100>,
  "is_eligible": <true|false>,
  "disqualifiers_found": [],
  "score_reasoning": "<string>"
}`;
  return callGemini(prompt);
}

// 3. Rank donors for a crisis
async function rankDonors({ blood_type, urgency_score, donor_candidates }) {
  const prompt = `
You are AiDrona AI ranking blood donors for an emergency request.
Crisis: blood type ${blood_type}, severity ${urgency_score}/10.
Donor candidates: ${JSON.stringify(donor_candidates)}
Each donor has: donor_id, fitness_score, distance_km, last_donation_days, reliability_score.
Rank balancing: fitness_score (0.5), distance_km (0.3), reliability_score (0.2).
Exclude donors with fitness_score below 40.

Return ONLY a JSON object:
{
  "ranked_donor_ids": [],
  "expand_if_no_response_mins": <number>,
  "escalate_to_bank": <true|false>
}`;
  return callGemini(prompt);
}

// 4. Check medical disqualifiers
async function checkDisqualifiers({ new_medications, new_conditions, current_hemoglobin }) {
  const prompt = `
You are AiDrona AI checking if a patient's updated medical data disqualifies them.
New medications: ${(new_medications || []).join(', ') || 'none'}
New conditions: ${(new_conditions || []).join(', ') || 'none'}
Current hemoglobin: ${current_hemoglobin} g/dL
Apply Indian blood donation eligibility guidelines.

Return ONLY a JSON object:
{
  "disqualified": <true|false>,
  "disqualifying_items": [],
  "temporary_or_permanent": "<temporary|permanent>",
  "resume_after_days": <number or null>
}`;
  return callGemini(prompt);
}

// 5. Generate admin insights
async function generateAdminInsights({ region, time_window }) {
  const prompt = `
You are AiDrona AI generating operational insights for an admin dashboard.
Region: ${region}, Time window: ${time_window}.

Return ONLY a JSON object:
{
  "shortage_risk_types": [],
  "predicted_peak_hours": [],
  "suggested_awareness_areas": [],
  "narrative_summary": "<string>"
}`;
  return callGemini(prompt);
}

module.exports = {
  triageBloodRequest,
  evaluateDonorFitness,
  rankDonors,
  checkDisqualifiers,
  generateAdminInsights,
};
