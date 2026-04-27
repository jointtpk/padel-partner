import 'package:get/get.dart';
import '../../core/models/booking.dart';
import '../../core/models/friend.dart';
import '../../core/models/game.dart';
import '../../core/models/player.dart';
import '../../core/mock_data.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  final currentUser  = Rx<Player>(kPlayers[0]);
  final bookings     = <Booking>[].obs;
  final friends      = <FriendEntry>[].obs;
  final requests     = <String, List<JoinRequest>>{}.obs;
  final gameChats    = <String, List<ChatMessage>>{}.obs;
  final friendChats  = <String, List<ChatMessage>>{}.obs;
  final hostedGames  = <Game>[].obs;
  final subscription = const Subscription(plan: 'trial', daysLeft: 23).obs;

  void updateCurrentUser({
    String? name,
    String? handle,
    String? email,
    String? bio,
    String? photoPath,
    String? city,
    int? age,
    String? gender,
    Map<String, String>? tags,
  }) {
    final cur = currentUser.value;
    final newName = name ?? cur.name;
    currentUser.value = cur.copyWith(
      name: newName,
      handle: handle ?? cur.handle,
      email: email ?? cur.email,
      bio: bio ?? cur.bio,
      photoPath: photoPath ?? cur.photoPath,
      city: city ?? cur.city,
      age: age ?? cur.age,
      gender: gender ?? cur.gender,
      tags: tags ?? cur.tags,
      initials: _initialsOf(newName),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Match phase for demo: 'upcoming' | 'reminder_30' | 'reminder_15' | 'finished'
  final matchPhase = 'upcoming'.obs;

  @override
  void onInit() {
    super.onInit();
    bookings.addAll(kInitialBookings);
    friends.addAll(kInitialFriends);
    requests.addAll(kInitialRequests);
    gameChats.addAll(kInitialGameChats);
    friendChats.addAll(kInitialFriendChats);
  }

  // ─── Friends ───────────────────────────────────────────────────────────────
  String getFriendStatus(String uid) =>
      friends.firstWhereOrNull((f) => f.userId == uid)?.status ?? 'none';

  bool isFriend(String uid) => getFriendStatus(uid) == 'friends';

  void addFriend(String uid) {
    final cur = getFriendStatus(uid);
    if (cur == 'none') {
      friends.add(FriendEntry(userId: uid, status: 'pending_out'));
    } else if (cur == 'pending_in') {
      final i = friends.indexWhere((f) => f.userId == uid);
      if (i >= 0) friends[i] = friends[i].copyWith(status: 'friends');
    }
  }

  void approveFriend(String uid) {
    final i = friends.indexWhere((f) => f.userId == uid);
    if (i >= 0) friends[i] = friends[i].copyWith(status: 'friends');
  }

  int get pendingFriendRequests =>
      friends.where((f) => f.status == 'pending_in').length;

  // ─── Bookings ─────────────────────────────────────────────────────────────
  String getBookingStatus(String gameId) =>
      bookings.firstWhereOrNull((b) => b.gameId == gameId)?.status ?? 'none';

  void requestJoin(String gameId) {
    bookings.removeWhere((b) => b.gameId == gameId);
    bookings.add(Booking(gameId: gameId, status: 'pending'));
  }

  // ─── Requests ─────────────────────────────────────────────────────────────
  int get totalPendingRequests =>
      requests.values.fold(0, (sum, list) => sum + list.length);

  void approveJoin(String gameId, String uid) {
    requests[gameId] = (requests[gameId] ?? [])
        .where((r) => r.userId != uid)
        .toList();
    requests.refresh();
    // Mark booking confirmed for the user (in a real app, update Firestore)
    final idx = bookings.indexWhere((b) => b.gameId == gameId);
    if (idx >= 0) bookings[idx] = bookings[idx].copyWith(status: 'confirmed');
  }

  void declineJoin(String gameId, String uid) {
    requests[gameId] = (requests[gameId] ?? [])
        .where((r) => r.userId != uid)
        .toList();
    requests.refresh();
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────
  void sendGameMessage(String gameId, String text) {
    final list = List<ChatMessage>.from(gameChats[gameId] ?? []);
    list.add(ChatMessage(from: 'me', text: text, t: _nowTime()));
    gameChats[gameId] = list;
    gameChats.refresh();
  }

  void sendFriendMessage(String uid, String text) {
    final list = List<ChatMessage>.from(friendChats[uid] ?? []);
    list.add(ChatMessage(from: 'me', text: text, t: _nowTime()));
    friendChats[uid] = list;
    friendChats.refresh();
  }

  // ─── Host games ───────────────────────────────────────────────────────────
  void addHostedGame(Game game) {
    hostedGames.add(game);
    bookings.add(Booking(gameId: game.id, status: 'hosting'));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  List<Game> get myUpcomingGames {
    final booked = bookings
        .where((b) => b.status == 'confirmed')
        .map((b) {
          final g = kGames.firstWhereOrNull((g) => g.id == b.gameId) ??
              hostedGames.firstWhereOrNull((g) => g.id == b.gameId);
          return g != null ? (game: g, status: b.status) : null;
        })
        .whereType<({Game game, String status})>()
        .toList();

    final hosted = hostedGames
        .map((g) => (game: g, status: 'hosting'))
        .toList();

    return [
      ...booked.map((e) => e.game),
      ...hosted.map((e) => e.game),
    ];
  }
}
