-- ============================================================
-- LiftLog — Supabase Schema
-- Esegui questo file nel SQL Editor del tuo progetto Supabase
-- ============================================================

-- ── EXTENSIONS ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── TABLES ───────────────────────────────────────────────────

CREATE TABLE public.users (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email               TEXT NOT NULL,
  full_name           TEXT NOT NULL DEFAULT '',
  role                TEXT NOT NULL DEFAULT 'athlete'
                        CHECK (role IN ('athlete', 'pt', 'admin')),
  theme               TEXT NOT NULL DEFAULT 'system'
                        CHECK (theme IN ('dark', 'light', 'system')),
  language            TEXT NOT NULL DEFAULT 'en'
                        CHECK (language IN ('it', 'en')),
  subscription_status TEXT NOT NULL DEFAULT 'trial'
                        CHECK (subscription_status IN ('trial', 'active', 'expired')),
  trial_end_date      TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.pt_clients (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pt_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  UNIQUE(pt_id, client_id)
);

CREATE TABLE public.exercises (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  category      TEXT NOT NULL
                  CHECK (category IN ('bodyweight', 'weights', 'powerlifting', 'crossfit')),
  muscle_groups TEXT[] NOT NULL DEFAULT '{}',
  equipment     TEXT NOT NULL DEFAULT '',
  is_custom     BOOLEAN NOT NULL DEFAULT FALSE,
  is_global     BOOLEAN NOT NULL DEFAULT TRUE,
  created_by    UUID REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE TABLE public.workout_plans (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  goal        TEXT NOT NULL
                CHECK (goal IN ('strength', 'hypertrophy', 'endurance', 'weight_loss', 'mixed')),
  created_by  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.plan_exercises (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id     UUID NOT NULL REFERENCES public.workout_plans(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  sets        INT NOT NULL DEFAULT 3,
  reps        INT NOT NULL DEFAULT 10,
  rest_seconds INT NOT NULL DEFAULT 90,
  sort_order  INT NOT NULL DEFAULT 0,
  notes       TEXT NOT NULL DEFAULT ''
);

CREATE TABLE public.sessions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_id        UUID REFERENCES public.workout_plans(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  started_at     TIMESTAMPTZ,
  ended_at       TIMESTAMPTZ,
  notes          TEXT NOT NULL DEFAULT ''
);

CREATE TABLE public.session_sets (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id   UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  exercise_id  UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  set_number   INT NOT NULL,
  reps_done    INT NOT NULL DEFAULT 0,
  weight_kg    DECIMAL(6,2) NOT NULL DEFAULT 0,
  is_bodyweight BOOLEAN NOT NULL DEFAULT FALSE,
  completed    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE public.notification_settings (
  user_id        UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  enabled        BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_time  TEXT NOT NULL DEFAULT '08:00',
  custom_message TEXT NOT NULL DEFAULT ''
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX ON public.sessions(user_id, scheduled_date);
CREATE INDEX ON public.session_sets(session_id);
CREATE INDEX ON public.plan_exercises(plan_id, sort_order);
CREATE INDEX ON public.exercises(is_global, category);

-- ── ROW LEVEL SECURITY ────────────────────────────────────────
ALTER TABLE public.users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pt_clients          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_exercises      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_sets        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- users
CREATE POLICY "users: own row" ON public.users
  FOR ALL USING (auth.uid() = id);

-- pt_clients
CREATE POLICY "pt_clients: pt manages own" ON public.pt_clients
  FOR ALL USING (auth.uid() = pt_id);

CREATE POLICY "pt_clients: client can read own" ON public.pt_clients
  FOR SELECT USING (auth.uid() = client_id);

-- exercises
CREATE POLICY "exercises: global readable" ON public.exercises
  FOR SELECT USING (is_global = TRUE);

CREATE POLICY "exercises: custom by creator" ON public.exercises
  FOR ALL USING (auth.uid() = created_by);

-- workout_plans
CREATE POLICY "plans: creator or assignee" ON public.workout_plans
  FOR SELECT USING (auth.uid() = created_by OR auth.uid() = assigned_to);

CREATE POLICY "plans: creator manages" ON public.workout_plans
  FOR ALL USING (auth.uid() = created_by);

-- plan_exercises
CREATE POLICY "plan_exercises: via plan access" ON public.plan_exercises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id
        AND (wp.created_by = auth.uid() OR wp.assigned_to = auth.uid())
    )
  );

CREATE POLICY "plan_exercises: creator manages" ON public.plan_exercises
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_id AND wp.created_by = auth.uid()
    )
  );

-- sessions
CREATE POLICY "sessions: owner only" ON public.sessions
  FOR ALL USING (auth.uid() = user_id);

-- session_sets
CREATE POLICY "session_sets: via session owner" ON public.session_sets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.sessions s
      WHERE s.id = session_id AND s.user_id = auth.uid()
    )
  );

-- notification_settings
CREATE POLICY "notification_settings: owner only" ON public.notification_settings
  FOR ALL USING (auth.uid() = user_id);

-- ── TRIGGER: auto-create user profile on signup ───────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, subscription_status, trial_end_date)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'trial',
    NOW() + INTERVAL '30 days'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── SEED: global exercises ────────────────────────────────────
INSERT INTO public.exercises (name, category, muscle_groups, equipment, is_custom, is_global) VALUES
-- BODYWEIGHT
('Push-up',             'bodyweight', ARRAY['Chest','Triceps','Shoulders'],          'None',             FALSE, TRUE),
('Pull-up',             'bodyweight', ARRAY['Back','Biceps'],                        'Pull-up bar',      FALSE, TRUE),
('Squat',               'bodyweight', ARRAY['Quads','Glutes','Hamstrings'],           'None',             FALSE, TRUE),
('Dip',                 'bodyweight', ARRAY['Chest','Triceps','Shoulders'],           'Dip bars',         FALSE, TRUE),
('Lunge',               'bodyweight', ARRAY['Quads','Glutes','Hamstrings'],           'None',             FALSE, TRUE),
('Plank',               'bodyweight', ARRAY['Core','Shoulders'],                      'None',             FALSE, TRUE),
('Burpee',              'bodyweight', ARRAY['Full Body'],                             'None',             FALSE, TRUE),
('Mountain Climber',    'bodyweight', ARRAY['Core','Shoulders','Quads'],              'None',             FALSE, TRUE),
('Jump Squat',          'bodyweight', ARRAY['Quads','Glutes','Calves'],               'None',             FALSE, TRUE),
('Pike Push-up',        'bodyweight', ARRAY['Shoulders','Triceps'],                   'None',             FALSE, TRUE),
('Chin-up',             'bodyweight', ARRAY['Biceps','Back'],                         'Pull-up bar',      FALSE, TRUE),
('Tricep Dip (bench)',  'bodyweight', ARRAY['Triceps','Chest'],                       'Bench',            FALSE, TRUE),
('Glute Bridge',        'bodyweight', ARRAY['Glutes','Hamstrings','Core'],            'None',             FALSE, TRUE),
('Hollow Body Hold',    'bodyweight', ARRAY['Core'],                                  'None',             FALSE, TRUE),
('Pistol Squat',        'bodyweight', ARRAY['Quads','Glutes','Balance'],              'None',             FALSE, TRUE),
-- WEIGHTS
('Bench Press',              'weights', ARRAY['Chest','Triceps','Shoulders'],         'Barbell, Bench',          FALSE, TRUE),
('Incline Dumbbell Press',   'weights', ARRAY['Upper Chest','Shoulders','Triceps'],   'Dumbbells, Incline Bench',FALSE, TRUE),
('Dumbbell Shoulder Press',  'weights', ARRAY['Shoulders','Triceps'],                 'Dumbbells',               FALSE, TRUE),
('Lateral Raise',            'weights', ARRAY['Lateral Deltoid'],                     'Dumbbells',               FALSE, TRUE),
('Barbell Row',              'weights', ARRAY['Back','Biceps','Rear Deltoid'],        'Barbell',                 FALSE, TRUE),
('Seated Cable Row',         'weights', ARRAY['Back','Biceps'],                       'Cable machine',           FALSE, TRUE),
('Lat Pulldown',             'weights', ARRAY['Back','Biceps'],                       'Cable machine',           FALSE, TRUE),
('Dumbbell Curl',            'weights', ARRAY['Biceps'],                              'Dumbbells',               FALSE, TRUE),
('Skull Crusher',            'weights', ARRAY['Triceps'],                             'EZ-bar, Bench',           FALSE, TRUE),
('Goblet Squat',             'weights', ARRAY['Quads','Glutes','Core'],               'Kettlebell or Dumbbell',  FALSE, TRUE),
('Romanian Deadlift',        'weights', ARRAY['Hamstrings','Glutes','Lower Back'],    'Barbell or Dumbbells',    FALSE, TRUE),
('Leg Press',                'weights', ARRAY['Quads','Glutes','Hamstrings'],         'Leg press machine',       FALSE, TRUE),
('Leg Curl',                 'weights', ARRAY['Hamstrings'],                          'Leg curl machine',        FALSE, TRUE),
('Leg Extension',            'weights', ARRAY['Quads'],                               'Leg extension machine',   FALSE, TRUE),
('Calf Raise',               'weights', ARRAY['Calves'],                              'Machine or Barbell',      FALSE, TRUE),
('Face Pull',                'weights', ARRAY['Rear Deltoid','Rotator Cuff'],         'Cable machine',           FALSE, TRUE),
('Cable Fly',                'weights', ARRAY['Chest'],                               'Cable machine',           FALSE, TRUE),
('Hammer Curl',              'weights', ARRAY['Biceps','Brachialis'],                 'Dumbbells',               FALSE, TRUE),
('Tricep Pushdown',          'weights', ARRAY['Triceps'],                             'Cable machine',           FALSE, TRUE),
-- POWERLIFTING
('Back Squat',               'powerlifting', ARRAY['Quads','Glutes','Core','Back'],      'Barbell, Squat rack', FALSE, TRUE),
('Conventional Deadlift',    'powerlifting', ARRAY['Hamstrings','Glutes','Back','Traps'],'Barbell',             FALSE, TRUE),
('Sumo Deadlift',            'powerlifting', ARRAY['Glutes','Adductors','Quads','Back'], 'Barbell',             FALSE, TRUE),
('Paused Squat',             'powerlifting', ARRAY['Quads','Glutes','Core'],             'Barbell, Squat rack', FALSE, TRUE),
('Paused Bench Press',       'powerlifting', ARRAY['Chest','Triceps','Shoulders'],       'Barbell, Bench',      FALSE, TRUE),
('Overhead Press',           'powerlifting', ARRAY['Shoulders','Triceps','Core'],        'Barbell',             FALSE, TRUE),
('Front Squat',              'powerlifting', ARRAY['Quads','Core','Upper Back'],         'Barbell, Squat rack', FALSE, TRUE),
('Romanian Deadlift (BB)',   'powerlifting', ARRAY['Hamstrings','Glutes','Lower Back'],  'Barbell',             FALSE, TRUE),
('Good Morning',             'powerlifting', ARRAY['Lower Back','Hamstrings','Glutes'],  'Barbell',             FALSE, TRUE),
('Box Squat',                'powerlifting', ARRAY['Quads','Glutes','Hamstrings'],       'Barbell, Box',        FALSE, TRUE),
('Rack Pull',                'powerlifting', ARRAY['Traps','Back','Glutes'],             'Barbell, Power rack', FALSE, TRUE),
('Close Grip Bench Press',   'powerlifting', ARRAY['Triceps','Chest'],                   'Barbell, Bench',      FALSE, TRUE),
('Pendlay Row',              'powerlifting', ARRAY['Back','Biceps','Rear Deltoid'],      'Barbell',             FALSE, TRUE),
-- CROSSFIT
('Thruster',                 'crossfit', ARRAY['Quads','Shoulders','Triceps','Core'],    'Barbell or Dumbbells',FALSE, TRUE),
('Power Clean',              'crossfit', ARRAY['Full Body','Hamstrings','Traps'],        'Barbell',             FALSE, TRUE),
('Kettlebell Swing',         'crossfit', ARRAY['Glutes','Hamstrings','Core','Shoulders'],'Kettlebell',          FALSE, TRUE),
('Box Jump',                 'crossfit', ARRAY['Quads','Glutes','Calves'],               'Box',                 FALSE, TRUE),
('Double Under',             'crossfit', ARRAY['Calves','Coordination'],                 'Jump rope',           FALSE, TRUE),
('Toes to Bar',              'crossfit', ARRAY['Core','Hip Flexors','Lats'],             'Pull-up bar',         FALSE, TRUE),
('Muscle-up',                'crossfit', ARRAY['Back','Chest','Triceps','Biceps'],       'Rings or Pull-up bar',FALSE, TRUE),
('Wall Ball',                'crossfit', ARRAY['Quads','Shoulders','Core'],              'Medicine ball',       FALSE, TRUE),
('Rope Climb',               'crossfit', ARRAY['Back','Biceps','Core'],                  'Rope',                FALSE, TRUE),
('Handstand Push-up',        'crossfit', ARRAY['Shoulders','Triceps','Core'],            'Wall',                FALSE, TRUE),
('Snatch',                   'crossfit', ARRAY['Full Body','Shoulders','Hips'],          'Barbell',             FALSE, TRUE),
('Clean and Jerk',           'crossfit', ARRAY['Full Body'],                             'Barbell',             FALSE, TRUE),
('GHD Sit-up',               'crossfit', ARRAY['Core','Hip Flexors'],                   'GHD machine',         FALSE, TRUE),
('Rowing (Ergometer)',        'crossfit', ARRAY['Back','Legs','Core','Arms'],            'Rowing machine',      FALSE, TRUE);
