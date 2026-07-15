import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import generateQuestionsHandler from './api/generate-questions.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

// Body parsing middleware with limits for base64 file uploads
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files from root directory
app.use(express.static(__dirname));

// Map the serverless Vercel function to our local dev server
app.post('/api/generate-questions', generateQuestionsHandler);
app.post('/api/generate-questions.js', generateQuestionsHandler);

// Fallback to index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[HomeWk] Server is running on port ${PORT}`);
  console.log(`[HomeWk] Local development URL: http://localhost:${PORT}`);
});
