import Foundation

enum Constants {
    enum Supabase {
        static let url = "https://zpxwpmmlnhvgihsqjhdd.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpweHdwbW1sbmh2Z2loc3FqaGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4NDU5NjQsImV4cCI6MjA5ODQyMTk2NH0.pd_a8xBCVOSu90VuPmT7n0WBQ7aoNyawNsRqBGEBh8A"
    }

    enum Stripe {
        static let publishableKey = "pk_live_YOUR_STRIPE_KEY"
        static let checkoutURL = "https://buy.stripe.com/YOUR_CHECKOUT_LINK"
        static let customerPortalURL = "https://billing.stripe.com/p/login/YOUR_PORTAL_LINK"
        static let monthlyPrice = "€4.99"
    }

    enum Trial {
        static let durationDays: Int = 30
    }

    enum Notifications {
        static let defaultReminderHour: Int = 8
        static let defaultReminderMinute: Int = 0
        static let inactivityDays: Int = 5
    }

    enum Tables {
        static let users = "users"
        static let ptClients = "pt_clients"
        static let exercises = "exercises"
        static let workoutPlans = "workout_plans"
        static let planExercises = "plan_exercises"
        static let sessions = "sessions"
        static let sessionSets = "session_sets"
        static let notificationSettings = "notification_settings"
    }
}
