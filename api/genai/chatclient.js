const DEFAULT_MODEL = "gpt-4o-mini";

function normalizeEnvValue(name) {
  const value = process.env[name];

  if (!value) {
    return "";
  }

  const trimmed = value.trim();
  const prefix = `${name}=`;

  return trimmed.startsWith(prefix) ? trimmed.slice(prefix.length).trim() : trimmed;
}

function getOpenAiApiKey() {
  const key = normalizeEnvValue("OPENAI_API_KEY") || normalizeEnvValue("SPRING_AI_OPENAI_API_KEY");
  const normalizedKey = key.toLowerCase();

  if (!key || normalizedKey === "demo" || normalizedKey === "your_api_key_here") {
    return "";
  }

  return key;
}

function getPrompt(body) {
  if (typeof body === "string") {
    return body;
  }

  if (body && typeof body.message === "string") {
    return body.message;
  }

  if (body && typeof body.query === "string") {
    return body.query;
  }

  return "";
}

function sendText(res, status, message) {
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.status(status).send(message);
}

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return sendText(res, 405, "Method not allowed");
  }

  const prompt = getPrompt(req.body).trim();

  if (!prompt) {
    return sendText(res, 400, "Please enter a message.");
  }

  const apiKey = getOpenAiApiKey();

  if (!apiKey) {
    return sendText(res, 500, "OpenAI API key is not configured on Vercel. Add OPENAI_API_KEY and redeploy.");
  }

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: normalizeEnvValue("OPENAI_MODEL") || DEFAULT_MODEL,
        messages: [
          {
            role: "system",
            content: "You are a friendly assistant for Spring Animal Clinic. Help users with owners, pets, visits, and veterinarians. If you do not know an answer, say so briefly and ask a helpful follow-up question.",
          },
          {
            role: "user",
            content: prompt,
          },
        ],
      }),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errorMessage = data.error && data.error.message ? data.error.message : "OpenAI request failed.";
      return sendText(res, response.status, errorMessage);
    }

    const answer = data.choices && data.choices[0] && data.choices[0].message
      ? data.choices[0].message.content
      : "";

    return sendText(res, 200, answer || "I could not generate a response. Please try again.");
  } catch (error) {
    console.error("OpenAI chat request failed", error);
    return sendText(res, 502, "Chat service is currently unavailable. Please try again.");
  }
};
