import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/buddies_service.dart';
import '../services/auth_service.dart';

class BuddiesScreen extends StatefulWidget {
  const BuddiesScreen({super.key});

  @override
  State<BuddiesScreen> createState() => _BuddiesScreenState();
}

class _BuddiesScreenState extends State<BuddiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BuddiesService _service = BuddiesService();

  List<Friend> _friends = [];
  PendingRequests _pendingRequests = PendingRequests(incoming: [], outgoing: []);
  bool _loading = true;
  String? _error;

  // Add friend
  final _usernameController = TextEditingController();
  bool _sendingRequest = false;

  // Chat state
  Friend? _selectedFriend;
  List<Message> _messages = [];
  final _messageController = TextEditingController();
  Timer? _messagePollingTimer;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initService();
    _getLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _messageController.dispose();
    _messagePollingTimer?.cancel();
    super.dispose();
  }

  void _initService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isLoggedIn) {
      _loadData();
    } else {
      setState(() {
        _loading = false;
        _error = 'Please log in to use Fishing Buddies';
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      // Location not available
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _service.getFriends(),
        _service.getPendingRequests(),
      ]);

      setState(() {
        _friends = results[0] as List<Friend>;
        _pendingRequests = results[1] as PendingRequests;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load data';
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_usernameController.text.trim().isEmpty) return;

    setState(() => _sendingRequest = true);

    final result = await _service.sendFriendRequest(_usernameController.text.trim());

    setState(() => _sendingRequest = false);

    if (result.success) {
      _usernameController.clear();
      _tabController.animateTo(0); // Go to friends tab
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _acceptRequest(int requestId) async {
    final success = await _service.acceptRequest(requestId);
    if (success) {
      _loadData();
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    await _service.rejectRequest(requestId);
    _loadData();
  }

  void _openChat(Friend friend) {
    setState(() => _selectedFriend = friend);
    _loadMessages();
    _startMessagePolling();
  }

  void _closeChat() {
    _messagePollingTimer?.cancel();
    setState(() {
      _selectedFriend = null;
      _messages = [];
    });
  }

  Future<void> _loadMessages() async {
    if (_selectedFriend == null) return;

    final messages = await _service.getMessages(_selectedFriend!.userId);
    setState(() => _messages = messages);
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages();
    });
  }

  Future<void> _sendMessage() async {
    if (_selectedFriend == null) return;
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    await _service.sendMessage(_selectedFriend!.userId, content);
    _loadMessages();
  }

  Future<void> _shareLocation() async {
    if (_selectedFriend == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    await _service.shareLocation(
      _selectedFriend!.userId,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    _loadMessages();
  }

  Future<void> _sendHookupAlert() async {
    if (_selectedFriend == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    await _service.sendHookupAlert(
      _selectedFriend!.userId,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    _loadMessages();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fish On! Alert sent!'), backgroundColor: Colors.orange),
      );
    }
  }

  void _openMaps(double lat, double lon) async {
    final url = Uri.parse('https://maps.google.com/?q=$lat,$lon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If in chat view, show chat screen
    if (_selectedFriend != null) {
      return _buildChatScreen(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Buddies'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Buddies'),
            const Tab(text: '+ Add'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_pendingRequests.incoming.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.incoming.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView(theme)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(theme),
                    _buildAddTab(theme),
                    _buildRequestsTab(theme),
                  ],
                ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(ThemeData theme) {
    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text('No fishing buddies yet!', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Add friends by their username to message them while fishing.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.person_add),
                label: const Text('Add a Buddy'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  friend.username[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: friend.boatName != null ? Text(friend.boatName!) : null,
              trailing: ElevatedButton(
                onPressed: () => _openChat(friend),
                child: const Text('Message'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add a Fishing Buddy',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter their username to send a friend request:',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username...',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendFriendRequest(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sendingRequest ? null : _sendFriendRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _sendingRequest
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Friend Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(ThemeData theme) {
    final hasIncoming = _pendingRequests.incoming.isNotEmpty;
    final hasOutgoing = _pendingRequests.outgoing.isNotEmpty;

    if (!hasIncoming && !hasOutgoing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No pending requests', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasIncoming) ...[
            Text(
              'INCOMING REQUESTS',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ..._pendingRequests.incoming.map((req) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            req.username[0].toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (req.boatName != null)
                                Text(req.boatName!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptRequest(req.requestId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Accept'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectRequest(req.requestId),
                            child: const Text('Decline'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          ],
          if (hasOutgoing) ...[
            if (hasIncoming) const SizedBox(height: 24),
            Text(
              'SENT REQUESTS',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ..._pendingRequests.outgoing.map((req) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  child: Text(req.username[0].toUpperCase()),
                ),
                title: Text('Waiting for ${req.username} to accept'),
                subtitle: const Text('Pending...', style: TextStyle(color: Colors.orange)),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildChatScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeChat,
        ),
        title: Text(_selectedFriend!.username),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hello!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return _buildMessageBubble(theme, message);
                    },
                  ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Location button
                  IconButton(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.location_on),
                    tooltip: 'Share Location',
                  ),
                  // Hookup alert button
                  IconButton(
                    onPressed: _sendHookupAlert,
                    icon: const Text('🎣', style: TextStyle(fontSize: 24)),
                    tooltip: 'Fish On!',
                    style: IconButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.2)),
                  ),
                  const SizedBox(width: 8),
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, Message message) {
    final isHookup = message.type == 'hookup_alert';
    final isLocation = message.type == 'location';

    if (isHookup) {
      return Align(
        alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('🎣', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (message.lat != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${message.lat!.toStringAsFixed(4)}°N, ${message.lon!.abs().toStringAsFixed(4)}°W',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (!message.isMine) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openMaps(message.lat!, message.lon!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[800],
                    ),
                    child: const Text('Navigate Here'),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    if (isLocation) {
      return Align(
        alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Location Shared', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              if (message.lat != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${message.lat!.toStringAsFixed(4)}°N, ${message.lon!.abs().toStringAsFixed(4)}°W',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (!message.isMine) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openMaps(message.lat!, message.lon!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E40AF),
                    ),
                    child: const Text('Open in Maps'),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    // Regular text message
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isMine ? theme.colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMine ? 16 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
