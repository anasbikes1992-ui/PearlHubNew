// PearlHub AI Concierge — Supabase Edge Function
//
// SECURITY FIX: The web app exposed VITE_ANTHROPIC_API_KEY in the browser bundle.
// This Edge Function keeps the API key server-side as a Supabase secret.
//
// Deploy:
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   supabase functions deploy ai-concierge
//
// Usage from Flutter:
//   final response = await Supabase.instance.client.functions.invoke(
//     'ai-concierge',
//     body: { 'query': 'Plan a 3-day trip to Kandy' },
//   );

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const SYSTEM_PROMPT = `You are PearlHub AI Concierge — a friendly, knowledgeable travel assistant for Sri Lanka.

You help users:
- Plan multi-day itineraries
- Find stays, vehicles, and events
- Estimate costs in LKR
- Suggest hidden gems and local experiences

When generating an itinerary, return a JSON object with this structure:
{
  "title": "Trip title",
  "destination": "Main destination",
  "duration": "X days",
  "highlights": ["Day 1: ...", "Day 2: ...", ...],
  "estimatedCost": "LKR XX,000 - XX,000",
  "aiNote": "Additional tips"
}

Always be warm, culturally aware, and practical. Prices should reflect real Sri Lankan costs.
Recommend specific types of stays (boutique hotels, villas, guest houses) and transport options.`

serve(async (req: Request) => {
  // CORS headers
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    // Verify JWT — only authenticated users can use the concierge
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers }
      )
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers }
      )
    }

    // Parse request
    const { query } = await req.json()
    if (!query || typeof query !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Missing "query" field' }),
        { status: 400, headers }
      )
    }

    // Fetch some context about available listings
    const { data: stays } = await supabase
      .from('stays_listings')
      .select('name, location, price_per_night, stay_type')
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .limit(10)

    const { data: vehicles } = await supabase
      .from('vehicles_listings')
      .select('title, location, price_per_day, vehicle_type')
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .limit(10)

    const listingContext = `
Available stays: ${JSON.stringify(stays || [])}
Available vehicles: ${JSON.stringify(vehicles || [])}
`

    // Call Anthropic API (server-side only!)
    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: SYSTEM_PROMPT + '\n\nCurrent PearlHub listings:\n' + listingContext,
        messages: [{ role: 'user', content: query }],
      }),
    })

    if (!anthropicResponse.ok) {
      const errText = await anthropicResponse.text()
      console.error('Anthropic API error:', errText)
      return new Response(
        JSON.stringify({ error: 'AI service temporarily unavailable' }),
        { status: 502, headers }
      )
    }

    const aiResult = await anthropicResponse.json()
    const aiText = aiResult.content?.[0]?.text || 'No response generated.'

    // Try to extract JSON itinerary from the response
    let itinerary = null
    try {
      const jsonMatch = aiText.match(/\{[\s\S]*\}/)
      if (jsonMatch) {
        itinerary = JSON.parse(jsonMatch[0])
      }
    } catch {
      // Not valid JSON — that's fine, return text only
    }

    // Log usage for analytics
    await supabase.from('request_logs').insert({
      user_id: user.id,
      endpoint: 'ai-concierge',
      metadata: { query_length: query.length },
    }).catch(() => {}) // Don't fail on logging errors

    return new Response(
      JSON.stringify({
        reply: aiText,
        itinerary,
      }),
      { status: 200, headers }
    )
  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers }
    )
  }
})
