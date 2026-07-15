-- HomeWk Database Schema
-- Run this in your Supabase SQL Editor

-- 1. Create Tables

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('student', 'admin')) DEFAULT 'student',
    class TEXT, -- e.g. '11', '12'
    section TEXT, -- e.g. 'A', 'B', 'Science'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assignments table
CREATE TABLE IF NOT EXISTS public.assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject TEXT NOT NULL,
    class TEXT NOT NULL,
    section TEXT NOT NULL,
    deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    paper_url TEXT, -- PDF file uploaded to storage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questions table (linked to assignments)
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES public.assignments(id) ON DELETE CASCADE NOT NULL,
    question_text TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('practice', 'homework')),
    created_by TEXT NOT NULL CHECK (created_by IN ('ai', 'admin')) DEFAULT 'ai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Submissions table
CREATE TABLE IF NOT EXISTS public.submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES public.assignments(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    file_url TEXT NOT NULL, -- Submitted homework file URL
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'checked')) DEFAULT 'pending',
    remarks TEXT DEFAULT '',
    CONSTRAINT unique_assignment_student UNIQUE (assignment_id, student_id)
);

-- 2. Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;

-- Helper function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Profiles Policies
CREATE POLICY "Allow public read profiles" ON public.profiles
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow individual insert profile" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow individual update profile" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can do everything with profiles" ON public.profiles
    FOR ALL TO authenticated USING (public.is_admin());


-- 4. Assignments Policies
CREATE POLICY "Students see assignments for their class and section, or Admins see all" ON public.assignments
    FOR SELECT TO authenticated USING (
        public.is_admin() OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE public.profiles.id = auth.uid()
            AND public.profiles.class = public.assignments.class
            AND public.profiles.section = public.assignments.section
        )
    );

CREATE POLICY "Admins can create/edit/delete assignments" ON public.assignments
    FOR ALL TO authenticated USING (public.is_admin());


-- 5. Questions Policies
CREATE POLICY "Students see questions for visible assignments, or Admins see all" ON public.questions
    FOR SELECT TO authenticated USING (
        public.is_admin() OR EXISTS (
            SELECT 1 FROM public.assignments
            WHERE public.assignments.id = public.questions.assignment_id
            AND EXISTS (
                SELECT 1 FROM public.profiles
                WHERE public.profiles.id = auth.uid()
                AND public.profiles.class = public.assignments.class
                AND public.profiles.section = public.assignments.section
            )
        )
    );

CREATE POLICY "Admins can manage questions" ON public.questions
    FOR ALL TO authenticated USING (public.is_admin());


-- 6. Submissions Policies
CREATE POLICY "Students see own submissions, or Admins see all" ON public.submissions
    FOR SELECT TO authenticated USING (
        auth.uid() = student_id OR public.is_admin()
    );

CREATE POLICY "Students can create submissions" ON public.submissions
    FOR INSERT TO authenticated WITH CHECK (
        auth.uid() = student_id
    );

CREATE POLICY "Students can update their own pending submissions" ON public.submissions
    FOR UPDATE TO authenticated USING (
        auth.uid() = student_id AND status = 'pending'
    ) WITH CHECK (
        auth.uid() = student_id AND status = 'pending'
    );

CREATE POLICY "Admins can do everything with submissions" ON public.submissions
    FOR ALL TO authenticated USING (public.is_admin());


-- 7. Setup Storage bucket for HomeWk
-- Note: Create a public bucket called 'homewk-files' in Supabase Storage.
-- Then define storage policies for that bucket.

-- Policy for reading files: public access or authenticated
-- Policy for uploading files: authenticated users can upload to 'homewk-files'
