enum ChatMessageType { user, bot, system }
enum ChatbotIntent { greeting, help, task_management, service_finder, budget_info, appointment_booking, emergency, general }

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;
  final ChatbotIntent? intent;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.intent,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'intent': intent?.name,
        'metadata': metadata,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        text: map['text'] as String,
        type: ChatMessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => ChatMessageType.user,
        ),
        timestamp: DateTime.parse(map['timestamp'] as String),
        intent: map['intent'] != null
            ? ChatbotIntent.values.firstWhere(
                (e) => e.name == map['intent'],
                orElse: () => ChatbotIntent.general,
              )
            : null,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  ChatMessage copyWith({
    String? id,
    String? text,
    ChatMessageType? type,
    DateTime? timestamp,
    ChatbotIntent? intent,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      intent: intent ?? this.intent,
      metadata: metadata ?? this.metadata,
    );
  }
}
