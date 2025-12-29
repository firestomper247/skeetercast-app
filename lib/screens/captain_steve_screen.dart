import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/captain_steve_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class CaptainSteveScreen extends StatefulWidget {
  const CaptainSteveScreen({super.key});

  @override
  State<CaptainSteveScreen> createState() => _CaptainSteveScreenState();
}

class _CaptainSteveScreenState extends State<CaptainSteveScreen> {
  final CaptainSteveService _steveService = CaptainSteveService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _questionsRemaining;
  int? _dailyRemaining;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      content: "Ahoy! I'm Captain Steve, your AI fishing and weather guide for North Carolina waters. Ask me about fishing conditions, best spots, weather forecasts, or anything about the coast!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if logged in
    if (!authService.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    // Check tier access (Pro required for chat)
    final tier = authService.tier?.toLowerCase() ?? 'free';
    if (tier == 'free') {
      _showUpgradePrompt();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Build conversation history (last 6 messages)
      final history = _messages
          .take(_messages.length > 6 ? 6 : _messages.length)
          .map((m) => {
                'role': m.isUser ? 'user' : 'steve',
                'content': m.content,
              })
          .toList();

      final response = await _steveService.chat(text, history: history);

      if (mounted) {
        if (response != null && response['success'] == true) {
          setState(() {
            _messages.add(ChatMessage(
              content: response['response'] ?? "I couldn't process that request.",
              isUser: false,
            ));
            _questionsRemaining = response['questions_remaining'];
            _dailyRemaining = response['daily_remaining'];
            _isLoading = false;
          });
        } else if (response != null && response['requires_upgrade'] == true) {
          setState(() {
            _messages.add(ChatMessage(
              content: response['error'] ?? "You need to upgrade to continue chatting.",
              isUser: false,
              isError: true,
            ));
            _isLoading = false;
          });
        } else if (response != null && response['limit_reached'] != null) {
          setState(() {
            _messages.add(ChatMessage(
              content: response['error'] ?? "You've reached your question limit.",
              isUser: false,
              isError: true,
            ));
            _isLoading = false;
          });
        } else {
          setState(() {
            _messages.add(ChatMessage(
              content: "Sorry, I had trouble responding. Please try again.",
              isUser: false,
              isError: true,
            ));
            _isLoading = false;
          });
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: "Connection error. Please check your internet and try again.",
            isUser: false,
            isError: true,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'Please sign in to chat with Captain Steve.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showUpgradePrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Captain Steve AI Chat is available for Plus, Premium, and Pro members. Upgrade now to unlock unlimited fishing advice!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sailing, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Captain Steve'),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_questionsRemaining != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_questionsRemaining left',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                  return _buildTypingIndicator(theme);
                }
                return _buildMessageBubble(_messages[index], theme);
              },
            ),
          ),

          // Login/upgrade banner for unauthenticated/free users
          if (!authService.isLoggedIn)
            _buildBanner(
              theme,
              'Sign in to chat with Captain Steve',
              Icons.login,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            )
          else if ((authService.tier?.toLowerCase() ?? 'free') == 'free')
            _buildBanner(
              theme,
              'Upgrade to unlock Captain Steve',
              Icons.star,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),

          // Message input
          _buildInputArea(theme, authService),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 16,
              child: const Icon(Icons.sailing, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : message.isError
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : message.isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              radius: 16,
              child: Icon(Icons.person, size: 18,
                         color: theme.colorScheme.onSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 16,
            child: const Icon(Icons.sailing, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(theme, 0),
                const SizedBox(width: 4),
                _buildDot(theme, 1),
                const SizedBox(width: 4),
                _buildDot(theme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ThemeData theme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildBanner(
    ThemeData theme,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                 size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, AuthService authService) {
    final canChat = authService.isLoggedIn &&
        (authService.tier?.toLowerCase() ?? 'free') != 'free';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canChat && !_isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: canChat
                      ? 'Ask Captain Steve...'
                      : 'Sign in & upgrade to chat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: canChat && !_isLoading ? _sendMessage : null,
              elevation: 0,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.isError = false,
  });
}
