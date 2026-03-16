class ChatModel {
  ChatModel({
    required this.id,
    required this.assetId,
    required this.senderType,
    required this.message,
    required this.sessionId,
    this.createdAt,
  });

  final String id;
  final String assetId;
  final String senderType;
  final String message;
  final String sessionId;
  final String? createdAt;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString() ?? '',
      assetId: json['asset_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? '-',
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}
