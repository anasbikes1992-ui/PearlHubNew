<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EventsListing;
use App\Models\StaysListing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AiConciergeController extends Controller
{
    public function query(Request $request)
    {
        $data = $request->validate([
            'message' => 'required|string|max:2000',
            'context' => 'nullable|array',
        ]);

        $apiKey = config('services.anthropic.api_key');

        if (!$apiKey) {
            return response()->json([
                'response' => $this->fallbackResponse($data['message']),
                'source' => 'fallback',
            ]);
        }

        $listingContext = $this->gatherContext($data['message']);

        $response = Http::withHeaders([
            'x-api-key' => $apiKey,
            'anthropic-version' => '2023-06-01',
            'content-type' => 'application/json',
        ])->post('https://api.anthropic.com/v1/messages', [
            'model' => 'claude-haiku-4-5-20251001',
            'max_tokens' => 1024,
            'system' => "You are PearlHub's AI Concierge for Sri Lanka tourism. Help users discover stays, vehicles, events, and local experiences. Be friendly and knowledgeable about Sri Lankan culture, cuisine, and attractions. Available listings context: {$listingContext}",
            'messages' => [
                ['role' => 'user', 'content' => $data['message']],
            ],
        ]);

        if ($response->successful()) {
            $content = $response->json('content.0.text', 'I can help you explore Sri Lanka!');
            return response()->json([
                'response' => $content,
                'source' => 'ai',
            ]);
        }

        return response()->json([
            'response' => $this->fallbackResponse($data['message']),
            'source' => 'fallback',
        ]);
    }

    private function gatherContext(string $message): string
    {
        $stays = StaysListing::approved()->active()->limit(5)->get(['title', 'location', 'price_per_night']);
        $events = EventsListing::where('moderation_status', 'approved')->where('active', true)->limit(5)->get(['title', 'location', 'event_date']);

        return json_encode(['top_stays' => $stays, 'upcoming_events' => $events]);
    }

    private function fallbackResponse(string $message): string
    {
        $lower = strtolower($message);

        if (str_contains($lower, 'stay') || str_contains($lower, 'hotel')) {
            return "We have wonderful stays across Sri Lanka! Check our Stays section for hotels, villas, and guest houses in popular destinations like Colombo, Kandy, Galle, and Ella.";
        }
        if (str_contains($lower, 'taxi') || str_contains($lower, 'ride')) {
            return "Our PearlRide taxi service covers all of Sri Lanka with 13 vehicle categories. Book a ride from the Taxi section!";
        }
        if (str_contains($lower, 'event') || str_contains($lower, 'activity')) {
            return "Discover cultural festivals, adventure activities, food tours, and wellness retreats across Sri Lanka in our Events section!";
        }

        return "Welcome to PearlHub! I can help you discover the best of Sri Lanka - stays, vehicles, events, properties, and local businesses. What are you looking for?";
    }
}
