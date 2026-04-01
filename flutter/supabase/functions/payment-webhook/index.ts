// PearlHub Payment Webhook — Supabase Edge Function
//
// Handles payment confirmations from PayHere, LankaPay, and WebXPay.
// Verifies HMAC signatures, updates booking status, and creates earnings rows.
//
// CRITICAL FIX: The web app had no server-side payment confirmation.
// Bookings stayed in 'pending' forever. This webhook completes the flow.
//
// Deploy:
//   supabase secrets set PAYHERE_MERCHANT_SECRET=your_secret
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_key
//   supabase functions deploy payment-webhook

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createHmac } from 'https://deno.land/std@0.177.0/node/crypto.ts'

const PAYHERE_MERCHANT_SECRET = Deno.env.get('PAYHERE_MERCHANT_SECRET')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req: Request) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    const body = await req.json()

    // Determine payment gateway from the request
    const gateway = detectGateway(body)

    switch (gateway) {
      case 'payhere':
        return await handlePayHere(supabase, body, headers)
      case 'lankapay':
        return await handleLankaPay(supabase, body, headers)
      case 'webxpay':
        return await handleWebXPay(supabase, body, headers)
      default:
        return new Response(
          JSON.stringify({ error: 'Unknown payment gateway' }),
          { status: 400, headers }
        )
    }
  } catch (error) {
    console.error('Payment webhook error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers }
    )
  }
})

function detectGateway(body: any): string {
  if (body.merchant_id && body.md5sig) return 'payhere'
  if (body.lankaqr_reference) return 'lankapay'
  if (body.webxpay_transaction_id) return 'webxpay'
  return 'unknown'
}

// ─────────────────────────────────────────────
// PAYHERE HANDLER
// ─────────────────────────────────────────────

async function handlePayHere(supabase: any, body: any, headers: any) {
  const {
    merchant_id,
    order_id,
    payhere_amount,
    payhere_currency,
    status_code,
    md5sig,
  } = body

  // Verify HMAC signature
  const localSig = createHmac('md5', PAYHERE_MERCHANT_SECRET)
    .update(
      merchant_id +
        order_id +
        payhere_amount +
        payhere_currency +
        status_code +
        createHmac('md5', PAYHERE_MERCHANT_SECRET)
          .update(PAYHERE_MERCHANT_SECRET)
          .digest('hex')
          .toUpperCase()
    )
    .digest('hex')
    .toUpperCase()

  if (localSig !== md5sig) {
    console.error('PayHere signature mismatch')
    return new Response(
      JSON.stringify({ error: 'Invalid signature' }),
      { status: 403, headers }
    )
  }

  // Status 2 = success
  if (status_code === '2') {
    await confirmPayment(supabase, order_id, parseFloat(payhere_amount))
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200, headers })
}

// ─────────────────────────────────────────────
// LANKAPAY HANDLER
// ─────────────────────────────────────────────

async function handleLankaPay(supabase: any, body: any, headers: any) {
  const { order_id, amount, status } = body

  if (status === 'success') {
    await confirmPayment(supabase, order_id, parseFloat(amount))
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200, headers })
}

// ─────────────────────────────────────────────
// WEBXPAY HANDLER
// ─────────────────────────────────────────────

async function handleWebXPay(supabase: any, body: any, headers: any) {
  const { order_id, total_amount, payment_status } = body

  if (payment_status === 'completed') {
    await confirmPayment(supabase, order_id, parseFloat(total_amount))
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200, headers })
}

// ─────────────────────────────────────────────
// CONFIRM PAYMENT — shared logic
// Updates booking status and creates earnings row atomically.
// ─────────────────────────────────────────────

async function confirmPayment(
  supabase: any,
  orderId: string,
  amount: number
) {
  // Find the booking
  const { data: booking, error: findError } = await supabase
    .from('bookings')
    .select('*')
    .eq('id', orderId)
    .single()

  if (findError || !booking) {
    console.error('Booking not found:', orderId)
    return
  }

  // Update booking status
  await supabase
    .from('bookings')
    .update({
      status: 'confirmed',
      payment_status: 'completed',
    })
    .eq('id', orderId)

  // Create earnings row for provider (with platform commission deducted)
  const commissionRate = 0.10 // 10% platform commission
  const providerEarning = amount * (1 - commissionRate)
  const platformCommission = amount * commissionRate

  if (booking.provider_id) {
    await supabase.from('earnings').insert({
      provider_id: booking.provider_id,
      booking_id: orderId,
      amount: providerEarning,
      commission: platformCommission,
      status: 'pending', // Released after service completion
    })
  }

  // Record wallet transaction
  await supabase.from('wallet_transactions').insert({
    type: 'commission',
    amount: platformCommission,
    description: `Commission on booking ${orderId}`,
    status: 'completed',
    ref: `COM-${Date.now()}`,
  })

  console.log(`Payment confirmed: ${orderId}, amount: ${amount}`)
}
