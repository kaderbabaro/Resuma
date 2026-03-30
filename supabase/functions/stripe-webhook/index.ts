import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// 🔧 Tes Price IDs Stripe
const PRICE_TO_PLAN: Record<string, string> = {
  "price_number": "basic",
  "price_number": "basic",
  "price_number": "pro",
  "price_number": "pro",
};

// ── Vérifie la signature Stripe sans SDK ────────────────────────────────────
async function verifySignature(
  payload: string,
  sigHeader: string,
  secret: string
): Promise<boolean> {
  try {
    const parts = sigHeader.split(",");
    const tPart = parts.find((p) => p.startsWith("t="));
    // ✅ Récupère TOUTES les signatures v1=
    const v1Parts = parts.filter((p) => p.startsWith("v1="));

    if (!tPart || v1Parts.length === 0) {
      console.error("❌ Missing t= or v1= in signature header");
      return false;
    }

    const timestamp = tPart.substring(2);

    // ✅ Vérifie que le timestamp n'est pas trop vieux (5 min max)
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - parseInt(timestamp)) > 300) {
      console.error("❌ Timestamp too old:", timestamp);
      return false;
    }

    const signedPayload = `${timestamp}.${payload}`;

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const sig = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(signedPayload)
    );

    const expected = Array.from(new Uint8Array(sig))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // ✅ Vérifie si expected correspond à AU MOINS UNE des signatures v1=
    return v1Parts.some((p) => p.substring(3) === expected);

  } catch (e) {
    console.error("Signature verification error:", e);
    return false;
  }
}

serve(async (req) => {
  const body = await req.text();
  const sigHeader = req.headers.get("stripe-signature") ?? "";
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";

  // ── Debug logs ─────────────────────────────────────────────────────────────
  console.log("🔑 Secret length:", webhookSecret.length);
  console.log("📝 Sig header:", sigHeader.substring(0, 80));
  console.log("📦 Body length:", body.length);

  // ── Vérifie signature ──────────────────────────────────────────────────────
  if (webhookSecret) {
    const valid = await verifySignature(body, sigHeader, webhookSecret);
    if (!valid) {
      console.error("❌ Invalid Stripe signature");
      return new Response("Invalid signature", { status: 401 });
    }
  } else {
    console.warn("⚠️ No webhook secret set — skipping verification");
  }

  // ── Parse event ────────────────────────────────────────────────────────────
  let event: Record<string, unknown>;
  try {
    event = JSON.parse(body);
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  console.log("📨 Event type:", event.type);

  if (event.type === "checkout.session.completed") {
    const data = event.data as Record<string, unknown>;
    const session = data.object as Record<string, unknown>;

    const customerDetails = session.customer_details as Record<string, unknown> | null;
    const email = customerDetails?.email as string | null;

    if (!email) {
      console.error("❌ No email in session");
      return new Response("No email", { status: 400 });
    }

    // ── Fetch line items via REST API Stripe ──────────────────────────────
    const sessionId = session.id as string;
    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY")!;
    let plan = "basic";

    try {
      const res = await fetch(
        `https://api.stripe.com/v1/checkout/sessions/${sessionId}/line_items`,
        { headers: { Authorization: `Bearer ${stripeKey}` } }
      );
      const lineItems = await res.json();
      const priceId = lineItems?.data?.[0]?.price?.id as string | undefined;

      if (priceId && PRICE_TO_PLAN[priceId]) {
        plan = PRICE_TO_PLAN[priceId];
      }
      console.log(`💳 Price: ${priceId} → Plan: ${plan}`);
    } catch (e) {
      console.error("❌ Line items fetch error:", e);
    }

    // ── Insert dans stripe_payments ────────────────────────────────────────
    const { error } = await supabase.from("stripe_payments").insert({
      email,
      plan,
      status: "paid",
      activated: false,
      stripe_session_id: sessionId,
      created_at: new Date().toISOString(),
    });

    if (error) {
      console.error("❌ DB insert error:", error);
      return new Response("DB error", { status: 500 });
    }

    console.log(`✅ Payment recorded: ${email} → ${plan}`);
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
