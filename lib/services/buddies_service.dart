import 'api_service.dart';
import 'api_config.dart';

/// Service for Fishing Buddies (friends & messaging)
class BuddiesService {
  final ApiService _api = ApiService();

  // ==================== FRIENDS ====================

  /// Get list of friends
  Future<List<Friend>> getFriends() async {
    try {
      final response = await _api.get(ApiConfig.friends);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['friends'] as List)
            .map((f) => Friend.fromJson(f))
            .toList();
      }
    } catch (e) {
      // Error fetching friends
    }
    return [];
  }

  /// Get pending friend requests (incoming and outgoing)
  Future<PendingRequests> getPendingRequests() async {
    try {
      final response = await _api.get(ApiConfig.friendsPending);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PendingRequests.fromJson(response.data);
      }
    } catch (e) {
      // Error fetching requests
    }
    return PendingRequests(incoming: [], outgoing: []);
  }

  /// Send friend request by username
  Future<ApiResult> sendFriendRequest(String username) async {
    try {
      final response = await _api.post(
        ApiConfig.friendsRequest,
        data: {'username': username},
      );
      return ApiResult(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Unknown error',
      );
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to send request');
    }
  }

  /// Accept a friend request
  Future<bool> acceptRequest(int requestId) async {
    try {
      final response = await _api.post(ApiConfig.friendsAccept(requestId));
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Reject a friend request
  Future<bool> rejectRequest(int requestId) async {
    try {
      final response = await _api.post(ApiConfig.friendsReject(requestId));
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(int friendId) async {
    try {
      final response = await _api.delete(ApiConfig.friendsDelete(friendId));
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ==================== MESSAGES ====================

  /// Get messages with a friend
  Future<List<Message>> getMessages(int friendId) async {
    try {
      final response = await _api.get(ApiConfig.messages(friendId));
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList();
      }
    } catch (e) {
      // Error fetching messages
    }
    return [];
  }

  /// Send a text message
  Future<bool> sendMessage(int friendId, String content) async {
    try {
      final response = await _api.post(
        ApiConfig.messages(friendId),
        data: {'content': content, 'type': 'text'},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Share location with a friend
  Future<bool> shareLocation(int friendId, double lat, double lon) async {
    try {
      final response = await _api.post(
        ApiConfig.messagesLocation(friendId),
        data: {'lat': lat, 'lon': lon},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Send a hookup alert (Fish On!)
  Future<bool> sendHookupAlert(int friendId, double lat, double lon, {String species = 'Fish'}) async {
    try {
      final response = await _api.post(
        ApiConfig.messagesHookup(friendId),
        data: {'lat': lat, 'lon': lon, 'species': species},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get(ApiConfig.messagesUnread);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['unread_count'] ?? 0;
      }
    } catch (e) {
      // Error fetching unread count
    }
    return 0;
  }
}

// ==================== MODELS ====================

class Friend {
  final int friendshipId;
  final int userId;
  final String username;
  final String? boatName;
  final String? email;

  Friend({
    required this.friendshipId,
    required this.userId,
    required this.username,
    this.boatName,
    this.email,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendshipId: json['friendship_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      boatName: json['boat_name'],
      email: json['email'],
    );
  }
}

class FriendRequest {
  final int requestId;
  final String username;
  final String? boatName;
  final String? email;

  FriendRequest({
    required this.requestId,
    required this.username,
    this.boatName,
    this.email,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['request_id'] ?? 0,
      username: json['username'] ?? '',
      boatName: json['boat_name'],
      email: json['email'],
    );
  }
}

class PendingRequests {
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  PendingRequests({required this.incoming, required this.outgoing});

  factory PendingRequests.fromJson(Map<String, dynamic> json) {
    return PendingRequests(
      incoming: (json['incoming'] as List? ?? [])
          .map((r) => FriendRequest.fromJson(r))
          .toList(),
      outgoing: (json['outgoing'] as List? ?? [])
          .map((r) => FriendRequest.fromJson(r))
          .toList(),
    );
  }
}

class Message {
  final int id;
  final String content;
  final String type; // 'text', 'location', 'hookup_alert'
  final bool isMine;
  final double? lat;
  final double? lon;
  final String? species;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMine,
    this.lat,
    this.lon,
    this.species,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      isMine: json['is_mine'] ?? false,
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      species: json['species'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ApiResult {
  final bool success;
  final String message;

  ApiResult({required this.success, required this.message});
}
