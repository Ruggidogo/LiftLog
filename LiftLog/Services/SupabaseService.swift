import Foundation
import Supabase

/*
 SUPABASE DATABASE SCHEMA
 ========================

 -- users
 CREATE TABLE users (
   id UUID PRIMARY KEY REFERENCES auth.users,
   email TEXT NOT NULL,
   full_name TEXT NOT NULL,
   role TEXT NOT NULL CHECK (role IN ('athlete','pt','admin')),
   theme TEXT NOT NULL DEFAULT 'system' CHECK (theme IN ('dark','light','system')),
   language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('it','en')),
   subscription_status TEXT NOT NULL DEFAULT 'trial' CHECK (subscription_status IN ('trial','active','expired')),
   trial_end_date TIMESTAMPTZ,
   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
 );

 -- pt_clients
 CREATE TABLE pt_clients (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   pt_id UUID NOT NULL REFERENCES users(id),
   client_id UUID NOT NULL REFERENCES users(id),
   UNIQUE(pt_id, client_id)
 );

 -- exercises
 CREATE TABLE exercises (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   name TEXT NOT NULL,
   category TEXT NOT NULL CHECK (category IN ('bodyweight','weights','powerlifting','crossfit')),
   muscle_groups TEXT[] NOT NULL DEFAULT '{}',
   equipment TEXT NOT NULL DEFAULT '',
   is_custom BOOLEAN NOT NULL DEFAULT false,
   is_global BOOLEAN NOT NULL DEFAULT true,
   created_by UUID REFERENCES users(id)
 );

 -- workout_plans
 CREATE TABLE workout_plans (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   name TEXT NOT NULL,
   goal TEXT NOT NULL CHECK (goal IN ('strength','hypertrophy','endurance','weight_loss','mixed')),
   created_by UUID NOT NULL REFERENCES users(id),
   assigned_to UUID REFERENCES users(id),
   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
 );

 -- plan_exercises
 CREATE TABLE plan_exercises (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
   exercise_id UUID NOT NULL REFERENCES exercises(id),
   sets INT NOT NULL DEFAULT 3,
   reps INT NOT NULL DEFAULT 10,
   rest_seconds INT NOT NULL DEFAULT 90,
   sort_order INT NOT NULL DEFAULT 0,
   notes TEXT NOT NULL DEFAULT ''
 );

 -- sessions
 CREATE TABLE sessions (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   user_id UUID NOT NULL REFERENCES users(id),
   plan_id UUID REFERENCES workout_plans(id),
   scheduled_date DATE NOT NULL,
   started_at TIMESTAMPTZ,
   ended_at TIMESTAMPTZ,
   notes TEXT NOT NULL DEFAULT ''
 );

 -- session_sets
 CREATE TABLE session_sets (
   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
   exercise_id UUID NOT NULL REFERENCES exercises(id),
   set_number INT NOT NULL,
   reps_done INT NOT NULL DEFAULT 0,
   weight_kg DECIMAL(6,2) NOT NULL DEFAULT 0,
   is_bodyweight BOOLEAN NOT NULL DEFAULT false,
   completed BOOLEAN NOT NULL DEFAULT false
 );

 -- notification_settings
 CREATE TABLE notification_settings (
   user_id UUID PRIMARY KEY REFERENCES users(id),
   enabled BOOLEAN NOT NULL DEFAULT true,
   reminder_time TIME NOT NULL DEFAULT '08:00:00',
   custom_message TEXT NOT NULL DEFAULT ''
 );

 ROW LEVEL SECURITY (RLS):
 - Enable RLS on all tables.
 - users: users can only read/update their own row.
 - pt_clients: pt can manage their own rows; clients can read rows referencing them.
 - exercises: global exercises readable by all; custom exercises readable by creator.
 - workout_plans: readable by creator and assigned_to.
 - plan_exercises: readable if user can read the parent plan.
 - sessions: only the owner can read/write.
 - session_sets: only accessible via parent session owner.
 - notification_settings: only the owner.

 STRIPE WEBHOOK:
 - Event: checkout.session.completed → set subscription_status = 'active' for user matching metadata.user_id
 - Event: customer.subscription.deleted → set subscription_status = 'expired'
 - Deploy as Supabase Edge Function at /functions/v1/stripe-webhook
 */

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Constants.Supabase.url)!,
            supabaseKey: Constants.Supabase.anonKey
        )
    }
}
