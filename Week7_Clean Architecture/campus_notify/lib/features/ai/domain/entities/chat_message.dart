enum MessageSender { user, ai }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;
}

