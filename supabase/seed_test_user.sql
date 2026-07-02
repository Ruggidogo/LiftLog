-- ============================================================
-- Seed test user: ruggeroartini03@gmail.com / testtest
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Create auth user (replace <UUID> with a real UUID if needed)
-- NOTE: You need to create the user via Supabase Dashboard > Authentication > Users > "Add user"
--   Email: ruggeroartini03@gmail.com
--   Password: testtest
--   Auto Confirm User: ✅
-- Then run the SQL below to add test workout data.

-- 2. After creating the auth user, get their UUID from the Users table and replace below:
DO $$
DECLARE
  test_user_id UUID;
  plan_id UUID := gen_random_uuid();
  session1_id UUID := gen_random_uuid();
  session2_id UUID := gen_random_uuid();
  session3_id UUID := gen_random_uuid();
  ex_squat UUID;
  ex_bench UUID;
  ex_deadlift UUID;
  ex_press UUID;
BEGIN
  -- Get the test user's ID
  SELECT id INTO test_user_id FROM auth.users WHERE email = 'ruggeroartini03@gmail.com';

  IF test_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found. Please create the auth user first via Supabase Dashboard.';
  END IF;

  -- Update user profile to have a nice name and active subscription
  UPDATE public.users
  SET full_name = 'Ruggero Artini',
      role = 'athlete',
      subscription_status = 'active'
  WHERE id = test_user_id;

  -- Get exercise IDs
  SELECT id INTO ex_squat FROM public.exercises WHERE name = 'Back Squat' LIMIT 1;
  SELECT id INTO ex_bench FROM public.exercises WHERE name = 'Bench Press' LIMIT 1;
  SELECT id INTO ex_deadlift FROM public.exercises WHERE name = 'Conventional Deadlift' LIMIT 1;
  SELECT id INTO ex_press FROM public.exercises WHERE name = 'Overhead Press' LIMIT 1;

  -- Create a workout plan
  INSERT INTO public.workout_plans (id, name, goal, created_by)
  VALUES (plan_id, 'Powerlifting Base', 'strength', test_user_id);

  -- Add exercises to plan
  INSERT INTO public.plan_exercises (plan_id, exercise_id, sets, reps, rest_seconds, sort_order)
  VALUES
    (plan_id, ex_squat,    4, 5, 180, 0),
    (plan_id, ex_bench,    4, 5, 180, 1),
    (plan_id, ex_deadlift, 3, 3, 240, 2),
    (plan_id, ex_press,    3, 8, 120, 3);

  -- Create past sessions (last 3 weeks)
  INSERT INTO public.sessions (id, user_id, plan_id, scheduled_date, started_at, ended_at, notes)
  VALUES
    (session1_id, test_user_id, plan_id, CURRENT_DATE - 14, NOW() - INTERVAL '14 days 1 hour', NOW() - INTERVAL '14 days', 'Felt strong today'),
    (session2_id, test_user_id, plan_id, CURRENT_DATE - 7,  NOW() - INTERVAL '7 days 1 hour',  NOW() - INTERVAL '7 days',  'PR on squat!'),
    (session3_id, test_user_id, plan_id, CURRENT_DATE,      NOW() - INTERVAL '1 hour',          NOW(),                     'Great session');

  -- Add sets for session 1
  INSERT INTO public.session_sets (session_id, exercise_id, set_number, reps_done, weight_kg, is_bodyweight, completed)
  VALUES
    (session1_id, ex_squat, 1, 5, 100, false, true),
    (session1_id, ex_squat, 2, 5, 100, false, true),
    (session1_id, ex_squat, 3, 5, 100, false, true),
    (session1_id, ex_bench, 1, 5, 80,  false, true),
    (session1_id, ex_bench, 2, 5, 80,  false, true),
    (session1_id, ex_deadlift, 1, 3, 140, false, true);

  -- Add sets for session 2
  INSERT INTO public.session_sets (session_id, exercise_id, set_number, reps_done, weight_kg, is_bodyweight, completed)
  VALUES
    (session2_id, ex_squat, 1, 5, 105, false, true),
    (session2_id, ex_squat, 2, 5, 105, false, true),
    (session2_id, ex_squat, 3, 5, 105, false, true),
    (session2_id, ex_squat, 4, 5, 105, false, true),
    (session2_id, ex_bench, 1, 5, 82.5, false, true),
    (session2_id, ex_bench, 2, 5, 82.5, false, true),
    (session2_id, ex_deadlift, 1, 3, 145, false, true),
    (session2_id, ex_deadlift, 2, 3, 145, false, true);

  -- Add sets for session 3 (today)
  INSERT INTO public.session_sets (session_id, exercise_id, set_number, reps_done, weight_kg, is_bodyweight, completed)
  VALUES
    (session3_id, ex_squat, 1, 5, 110, false, true),
    (session3_id, ex_squat, 2, 5, 110, false, true),
    (session3_id, ex_squat, 3, 5, 110, false, true),
    (session3_id, ex_squat, 4, 5, 110, false, true),
    (session3_id, ex_bench, 1, 5, 85, false, true),
    (session3_id, ex_bench, 2, 5, 85, false, true),
    (session3_id, ex_bench, 3, 5, 85, false, true),
    (session3_id, ex_deadlift, 1, 3, 150, false, true),
    (session3_id, ex_deadlift, 2, 3, 150, false, true),
    (session3_id, ex_deadlift, 3, 3, 150, false, true);

  -- Notification settings
  INSERT INTO public.notification_settings (user_id, enabled, reminder_time, custom_message)
  VALUES (test_user_id, true, '08:00', 'Time to train! 💪')
  ON CONFLICT (user_id) DO NOTHING;

  RAISE NOTICE 'Test data seeded successfully for user %', test_user_id;
END $$;
