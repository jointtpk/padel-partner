// Booking status: 'pending' | 'confirmed' | 'hosting' | 'declined'
class Booking {
  const Booking({required this.gameId, required this.status});
  final String gameId;
  final String status;
  Booking copyWith({String? gameId, String? status}) =>
      Booking(gameId: gameId ?? this.gameId, status: status ?? this.status);
  Map<String, dynamic> toMap() => {'gameId': gameId, 'status': status};
  factory Booking.fromMap(Map<String, dynamic> m) =>
      Booking(gameId: m['gameId'] ?? '', status: m['status'] ?? 'pending');
}

// Join request from another player to host's game
class JoinRequest {
  const JoinRequest({
    required this.userId,
    required this.when,
    this.note = '',
  });
  final String userId;
  final String when;
  final String note;
  Map<String, dynamic> toMap() =>
      {'userId': userId, 'when': when, 'note': note};
  factory JoinRequest.fromMap(Map<String, dynamic> m) => JoinRequest(
        userId: m['userId'] ?? '',
        when: m['when'] ?? '',
        note: m['note'] ?? '',
      );
}

// Chat message
class ChatMessage {
  const ChatMessage({
    required this.from,
    required this.text,
    required this.t,
  });
  final String from; // userId or 'me'
  final String text;
  final String t; // display time
  Map<String, dynamic> toMap() => {'from': from, 'text': text, 't': t};
  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        from: m['from'] ?? '',
        text: m['text'] ?? '',
        t: m['t'] ?? '',
      );
}
