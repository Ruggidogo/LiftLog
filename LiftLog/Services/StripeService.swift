import Foundation
import SafariServices
import UIKit

/*
 STRIPE INTEGRATION FLOW
 =======================

 1. TRIAL ONBOARDING
    - On new user registration: set trial_end_date = NOW() + 30 days, subscription_status = 'trial'
    - This is done inside AuthService.createUserProfile()

 2. PAYWALL TRIGGER
    - On each app launch, AuthService.checkAndUpdateSubscription() compares trial_end_date to NOW()
    - If expired and status is 'trial', updates subscription_status = 'expired' in Supabase
    - ContentView shows PaywallView when authState == .paywall

 3. CHECKOUT FLOW
    - PaywallView calls StripeService.openCheckout(userId:)
    - Opens Stripe Checkout page in SFSafariViewController
    - Checkout URL must include metadata: { user_id: "<uuid>" }
    - Example Stripe Checkout URL: https://buy.stripe.com/YOUR_LINK?client_reference_id=<userId>

 4. WEBHOOK (Supabase Edge Function)
    Deploy at: /functions/v1/stripe-webhook
    Handle events:
      - checkout.session.completed:
          const userId = event.data.object.client_reference_id
          UPDATE users SET subscription_status = 'active' WHERE id = userId
      - customer.subscription.deleted:
          UPDATE users SET subscription_status = 'expired' WHERE id = userId

    Edge Function code (Deno):
    ```typescript
    import { serve } from "https://deno.land/std/http/server.ts"
    import Stripe from "https://esm.sh/stripe"
    import { createClient } from "https://esm.sh/@supabase/supabase-js"

    serve(async (req) => {
      const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY"))
      const sig = req.headers.get("stripe-signature")
      const body = await req.text()
      const event = stripe.webhooks.constructEvent(body, sig, Deno.env.get("STRIPE_WEBHOOK_SECRET"))
      const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))

      if (event.type === "checkout.session.completed") {
        const userId = event.data.object.client_reference_id
        await supabase.from("users").update({ subscription_status: "active" }).eq("id", userId)
      } else if (event.type === "customer.subscription.deleted") {
        const userId = event.data.object.metadata.user_id
        await supabase.from("users").update({ subscription_status: "expired" }).eq("id", userId)
      }
      return new Response(JSON.stringify({ received: true }), { status: 200 })
    })
    ```

 5. MANAGE SUBSCRIPTION
    - ProfileView calls StripeService.openCustomerPortal()
    - Opens Stripe Customer Portal in SFSafariViewController

 6. APP RESUME
    - When SFSafariViewController is dismissed, app re-checks subscription status
    - AuthViewModel.checkSession() refreshes user data from Supabase
 */

final class StripeService {
    static let shared = StripeService()

    private init() {}

    @MainActor
    func openCheckout(userId: UUID) {
        var urlString = Constants.Stripe.checkoutURL
        urlString += "?client_reference_id=\(userId.uuidString)"
        guard let url = URL(string: urlString) else { return }
        openSafari(url: url)
    }

    @MainActor
    func openCustomerPortal() {
        guard let url = URL(string: Constants.Stripe.customerPortalURL) else { return }
        openSafari(url: url)
    }

    @MainActor
    private func openSafari(url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let safari = SFSafariViewController(url: url)
        root.present(safari, animated: true)
    }
}
