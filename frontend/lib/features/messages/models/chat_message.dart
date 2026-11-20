class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  final String messageId;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String).toLocal(),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toLocal(),
    );
  }
}
