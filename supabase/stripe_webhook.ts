// Supabase Edge Function — stripe-webhook
// Deploy con: supabase functions deploy stripe-webhook
//
// Variabili d'ambiente da impostare in Supabase Dashboard > Edge Functions > Secrets:
//   STRIPE_SECRET_KEY      → sk_live_...
//   STRIPE_WEBHOOK_SECRET  → whsec_...
//   SUPABASE_URL           → https://xxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY → service_role key (NON la anon key)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@13.0.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  const body = await req.text();

  const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
    apiVersion: "2023-10-16",
    httpClient: Stripe.createFetchHttpClient(),
  });

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature!,
      Deno.env.get("STRIPE_WEBHOOK_SECRET")!
    );
  } catch (err) {
    return new Response(`Webhook signature failed: ${err.message}`, { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      // client_reference_id viene impostato dall'app iOS come userId
      const userId = session.client_reference_id;
      if (userId) {
        await supabase
          .from("users")
          .update({ subscription_status: "active" })
          .eq("id", userId);
      }
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      const userId = subscription.metadata?.user_id;
      if (userId) {
        await supabase
          .from("users")
          .update({ subscription_status: "expired" })
          .eq("id", userId);
      }
      break;
    }

    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription;
      const userId = subscription.metadata?.user_id;
      if (userId) {
        const status = subscription.status === "active" ? "active" : "expired";
        await supabase
          .from("users")
          .update({ subscription_status: status })
          .eq("id", userId);
      }
      break;
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
    status: 200,
  });
});
