class Game {
  const Game({
    required this.id,
    required this.club,
    required this.area,
    required this.when,
    required this.time,
    required this.duration,
    required this.level,
    required this.levelKey,
    required this.price,
    required this.spots,
    required this.total,
    required this.hostId,
    required this.playerIds,
    required this.vibe,
    required this.court,
    required this.weather,
    this.hot = false,
    this.totalCost,
    this.address,
    this.pinLat,
    this.pinLng,
    this.autoApprove = false,
  });

  final String id;
  final String club;
  final String area;
  final String when;
  final String time;
  final String duration;
  final String level;
  final String levelKey;
  final int price;
  final int spots;
  final int total;
  final String hostId;
  final List<String> playerIds;
  final String vibe;
  final String court;
  final String weather;
  final bool hot;
  final int? totalCost;
  final String? address;
  final double? pinLat;
  final double? pinLng;
  final bool autoApprove;

  Game copyWith({
    String? id, String? club, String? area, String? when, String? time,
    String? duration, String? level, String? levelKey, int? price,
    int? spots, int? total, String? hostId, List<String>? playerIds,
    String? vibe, String? court, String? weather, bool? hot,
    int? totalCost, String? address, double? pinLat, double? pinLng,
    bool? autoApprove,
  }) =>
      Game(
        id: id ?? this.id,
        club: club ?? this.club,
        area: area ?? this.area,
        when: when ?? this.when,
        time: time ?? this.time,
        duration: duration ?? this.duration,
        level: level ?? this.level,
        levelKey: levelKey ?? this.levelKey,
        price: price ?? this.price,
        spots: spots ?? this.spots,
        total: total ?? this.total,
        hostId: hostId ?? this.hostId,
        playerIds: playerIds ?? this.playerIds,
        vibe: vibe ?? this.vibe,
        court: court ?? this.court,
        weather: weather ?? this.weather,
        hot: hot ?? this.hot,
        totalCost: totalCost ?? this.totalCost,
        address: address ?? this.address,
        pinLat: pinLat ?? this.pinLat,
        pinLng: pinLng ?? this.pinLng,
        autoApprove: autoApprove ?? this.autoApprove,
      );

  Map<String, dynamic> toMap() => {
        'id': id, 'club': club, 'area': area, 'when': when, 'time': time,
        'duration': duration, 'level': level, 'levelKey': levelKey,
        'price': price, 'spots': spots, 'total': total,
        'hostId': hostId, 'playerIds': playerIds, 'vibe': vibe,
        'court': court, 'weather': weather, 'hot': hot,
        'totalCost': totalCost, 'address': address,
        'pinLat': pinLat, 'pinLng': pinLng, 'autoApprove': autoApprove,
      };

  factory Game.fromMap(Map<String, dynamic> m) => Game(
        id: m['id'] ?? '',
        club: m['club'] ?? '',
        area: m['area'] ?? '',
        when: m['when'] ?? '',
        time: m['time'] ?? '',
        duration: m['duration'] ?? '',
        level: m['level'] ?? '',
        levelKey: m['levelKey'] ?? 'regular',
        price: m['price'] ?? 0,
        spots: m['spots'] ?? 0,
        total: m['total'] ?? 4,
        hostId: m['hostId'] ?? '',
        playerIds: List<String>.from(m['playerIds'] ?? []),
        vibe: m['vibe'] ?? '',
        court: m['court'] ?? '',
        weather: m['weather'] ?? '',
        hot: m['hot'] ?? false,
        totalCost: m['totalCost'],
        address: m['address'],
        pinLat: (m['pinLat'] as num?)?.toDouble(),
        pinLng: (m['pinLng'] as num?)?.toDouble(),
        autoApprove: m['autoApprove'] ?? false,
      );
}
