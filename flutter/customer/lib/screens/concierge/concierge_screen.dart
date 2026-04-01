import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:shared/services/auth_service.dart';

import '../../app/theme.dart';

/// AI Concierge screen — chat UI that calls the ai-concierge Edge Function.
/// Security fix: API key is stored as a Supabase secret, never in client code.
class ConciergeScreen extends ConsumerStatefulWidget {
  const ConciergeScreen({super.key});

  @override
  ConsumerState<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends ConsumerState<ConciergeScreen> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      isAi: true,
      text:
          "Hello! I'm your PearlHub AI Concierge. I can help you plan trips, "
          "find the best stays, vehicles, and events across Sri Lanka. "
          "Just tell me what you're looking for!",
    ));
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isAi: false, text: query));
      _isLoading = true;
    });
    _queryController.clear();
    _scrollToBottom();

    try {
      // Call the ai-concierge Edge Function (not the Anthropic API directly!)
      // This is the critical security fix — API key stays server-side.
      final response = await PearlHubSupabase.client.functions.invoke(
        'ai-concierge',
        body: {'query': query},
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final reply = data['reply'] as String? ?? 'No response';
        final itinerary = data['itinerary'] as Map<String, dynamic>?;

        setState(() {
          _messages.add(_ChatMessage(
            isAi: true,
            text: reply,
            itinerary: itinerary,
          ));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(
            isAi: true,
            text: 'Sorry, I had trouble processing that. Please try again.',
            isError: true,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          isAi: true,
          text: 'Connection error. Please check your internet and try again.',
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 22),
            SizedBox(width: 8),
            Text('AI Concierge'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Plan a trip, find stays, ask anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendQuery(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _isLoading ? null : _sendQuery,
                    backgroundColor: PearlHubColors.primary,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: PearlHubColors.primary,
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isAi
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? PearlHubColors.error.withOpacity(0.1)
                        : message.isAi
                            ? Colors.white
                            : PearlHubColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    border: message.isAi
                        ? Border.all(color: PearlHubColors.border)
                        : null,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isError
                          ? PearlHubColors.error
                          : message.isAi
                              ? PearlHubColors.textPrimary
                              : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Itinerary card
                if (message.itinerary != null) ...[
                  const SizedBox(height: 8),
                  _buildItineraryCard(message.itinerary!),
                ],
              ],
            ),
          ),
          if (!message.isAi) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: PearlHubColors.primary,
            child: const Icon(Icons.auto_awesome,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PearlHubColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Planning your experience...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(Map<String, dynamic> itinerary) {
    final title = itinerary['title'] as String? ?? 'Your Itinerary';
    final highlights = (itinerary['highlights'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final estimatedCost = itinerary['estimatedCost'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: PearlHubColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (highlights.isNotEmpty) ...[
              const Divider(),
              ...highlights.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('  ', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                            child:
                                Text(h, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
            if (estimatedCost != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PearlHubColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Est. Cost: $estimatedCost',
                  style: const TextStyle(
                    color: PearlHubColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isAi;
  final String text;
  final bool isError;
  final Map<String, dynamic>? itinerary;

  _ChatMessage({
    required this.isAi,
    required this.text,
    this.isError = false,
    this.itinerary,
  });
}
