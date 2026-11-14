class ConversationParticipant {
  const ConversationParticipant({
    required this.userId,
    required this.firstName,
    this.lastName = '',
  });

  final String userId;
  final String firstName;
  final String lastName;

  String get displayName =>
      [firstName, lastName].where((part) => part.trim().isNotEmpty).join(' ');

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String? ?? 'GoBison rider',
      lastName: json['lastName'] as String? ?? '',
    );
  }
}

class Conversation {
  const Conversation({
    required this.conversationId,
    required this.participant,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String conversationId;
  final ConversationParticipant participant;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      participant: ConversationParticipant.fromJson(
        json['participant'] as Map<String, dynamic>,
      ),
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? ''),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return Conversation(
      conversationId: conversationId,
      participant: participant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
