# HomeWk — Class 11-12 Homework & AI Practice Portal

HomeWk is a full-stack educational web application designed for students and teachers of Class 11-12. It provides a centralized hub where teachers can create assignments and publish homework, leveraging the Gemini 3.5 Flash model to analyze previous years' question papers (PDFs) and generate matching curriculum-focused worksheets. Students can download files, access interactive study modules, complete assigned practice drills, and upload their completed answer sheets directly into cloud storage.

---

## 🚀 Setup Instructions

Follow these exact steps to set up and deploy your own production-ready instance of HomeWk:

### 1. Create a Supabase Project
1. Go to [Supabase](https://supabase.com/) and sign in with your account.
2. Click **New Project**, select your organization, choose a project name (e.g., `HomeWk`), set a secure Database Password, and choose a region close to your users.
3. Once provisioned, navigate to **Project Settings** -> **API** to obtain your:
   - **Project URL**
   - **Anon Key** (API Key)

### 2. Configure Your Frontend Credentials
1. In your local project tree, open the `/supabase-config.js` file.
2. Replace the placeholders with your actual Supabase Project details:
   ```javascript
   window.SUPABASE_URL = "https://your-project-id.supabase.co";
   window.SUPABASE_ANON_KEY = "your-anon-key-here";
   ```

### 3. Initialize the Database Schema
1. In the Supabase Dashboard, click on the **SQL Editor** tab in the sidebar navigation.
2. Click **New Query**.
3. Open the `schema.sql` file in this repository, copy its entire contents, paste them into the SQL editor, and click **Run**.
4. This will create all required tables (`profiles`, `assignments`, `questions`, `submissions`) and set up granular **Row Level Security (RLS) Policies** ensuring secure client-side access.

### 4. Enable Email Authentication
1. Go to **Authentication** -> **Providers** -> **Email**.
2. Make sure the Email provider is **Enabled**.
3. Under Email Auth Settings, you can disable "Confirm Email" if you want to bypass email confirmation checks for immediate local testing.

### 5. Configure Cloud Storage for Uploads
Since students upload completed homework files and teachers upload source PDF papers, you must configure a public storage bucket:
1. Go to **Storage** -> **New Bucket**.
2. Name the bucket exactly: `homewk-files`
3. Toggle the switch to make it a **Public Bucket** (so URLs can be viewed/downloaded securely).
4. Add custom Storage Policies to allow authenticated uploads:
   - Click on the `homewk-files` bucket, select **Policies**, and add an `INSERT`/`UPLOAD` policy allowing authenticated users to upload documents.
   - Set another policy to allow public or authenticated `SELECT`/`READ` access.

### 6. Create Your First Admin/Teacher User
1. Open the HomeWk application UI.
2. Switch to the **Create Account** tab.
3. Choose the **Teacher / Admin** role option.
4. Input your email and password, and click **Create Account**.
5. Once created, this user will automatically have their profile flagged with the `role: "admin"` status inside the public database.

### 7. Get a Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/) and click **Get API Key**.
2. Create a free API Key.

### 8. Set Up Environment Variables (Vercel or Local Node)
To make secure server-side AI generations, set up your secrets:

#### For Vercel Deployment:
1. Go to your project dashboard on Vercel.
2. Navigate to **Settings** -> **Environment Variables**.
3. Add a new variable:
   - **Key**: `GEMINI_API_KEY`
   - **Value**: *[Your Google AI Studio API Key]*

#### For Local Development:
1. Create a `.env` file at the root of your project:
   ```env
   GEMINI_API_KEY="your-gemini-api-key"
   ```
2. Your Express dev server will automatically load this variable to handle matching requests at `/api/generate-questions`.

---

## 🛠️ Technology Stack & Architecture

- **Frontend**: Lightweight vanilla `HTML5` + `JavaScript` using ES6 modular architecture, styled beautifully using **Tailwind CSS**, and utilizing high-fidelity vector icons via **Lucide**.
- **Backend Serverless API**: A Vercel-compatible Node.js function inside `api/generate-questions.js` which utilizes the modern `@google/genai` SDK to execute structured multimodal analysis on uploaded PDFs.
- **Database & Auth**: **Supabase PostgreSQL** with Row Level Security (RLS) keeping teacher records and student submissions strictly segmented.
