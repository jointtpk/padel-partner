// status: 'friends' | 'pending_in' | 'pending_out' | 'none'
class FriendEntry {
  const FriendEntry({required this.userId, required this.status});
  final String userId;
  final String status;
  FriendEntry copyWith({String? userId, String? status}) =>
      FriendEntry(userId: userId ?? this.userId, status: status ?? this.status);
  Map<String, dynamic> toMap() => {'userId': userId, 'status': status};
  factory FriendEntry.fromMap(Map<String, dynamic> m) =>
      FriendEntry(userId: m['userId'] ?? '', status: m['status'] ?? 'none');
}

class Subscription {
  const Subscription({required this.plan, required this.daysLeft});
  final String plan; // 'trial' | 'free' | 'pro'
  final int daysLeft;
  Subscription copyWith({String? plan, int? daysLeft}) =>
      Subscription(plan: plan ?? this.plan, daysLeft: daysLeft ?? this.daysLeft);
  Map<String, dynamic> toMap() => {'plan': plan, 'daysLeft': daysLeft};
  factory Subscription.fromMap(Map<String, dynamic> m) =>
      Subscription(plan: m['plan'] ?? 'trial', daysLeft: m['daysLeft'] ?? 0);
}
