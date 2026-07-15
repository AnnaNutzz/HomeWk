import { GoogleGenAI, Type } from "@google/genai";

export default async function handler(req, res) {
  // Set CORS headers for Vercel deployment
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { pdfBase64, count } = req.body || {};
    if (!pdfBase64) {
      return res.status(400).json({ error: 'Missing pdfBase64 in request body' });
    }

    const numQuestions = parseInt(count) || 3;

    // Remove base64 data URI prefix if present
    const base64Data = pdfBase64.replace(/^data:application\/pdf;base64,/, '');

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'GEMINI_API_KEY is not set on the server. Please configure it in your Vercel or local environment variables.' 
      });
    }

    const ai = new GoogleGenAI({
      apiKey,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      }
    });

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: [
        {
          inlineData: {
            mimeType: "application/pdf",
            data: base64Data
          }
        },
        {
          text: `You are an expert high-school educator for grade 11 and 12 CBSE/state board exams.
Analyze the attached question paper PDF to understand the subjects, syllabus, difficulty, style, and question patterns.
Generate exactly ${numQuestions} new "practice" questions and exactly ${numQuestions} new "homework" questions in a highly similar style and of equal difficulty.
Each question should be completely original, challenging, and suitable for high-school senior standard.
Return the output in the requested JSON structure.`
        }
      ],
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.ARRAY,
          description: "An array of generated questions matching the PDF's subject and syllabus depth.",
          items: {
            type: Type.OBJECT,
            properties: {
              question_text: {
                type: Type.STRING,
                description: "The full text of the question, including parts or formatting if relevant."
              },
              type: {
                type: Type.STRING,
                description: "The classification: 'practice' or 'homework'."
              }
            },
            required: ["question_text", "type"]
          }
        }
      }
    });

    const resultText = response.text;
    const questions = JSON.parse(resultText);

    return res.status(200).json({ questions });
  } catch (error) {
    console.error("Error in generate-questions API:", error);
    return res.status(500).json({ 
      error: error.message || 'Internal Server Error' 
    });
  }
}
