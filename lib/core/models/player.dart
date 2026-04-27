import 'package:flutter/material.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.handle,
    required this.level,
    required this.tier,
    required this.badge,
    required this.avatarColor,
    required this.initials,
    required this.city,
    required this.wins,
    required this.games,
    required this.age,
    required this.gender,
    this.email,
    this.bio,
    this.photoPath,
    this.tags = const {},
  });

  final String id;
  final String name;
  final String handle;
  final double level;
  final String tier;
  final String badge;
  final Color avatarColor;
  final String initials;
  final String city;
  final int wins;
  final int games;
  final int age;
  final String gender; // 'M' | 'F'
  final String? email;
  final String? bio;
  final String? photoPath;
  final Map<String, String> tags;

  double get winRate => games > 0 ? wins / games : 0;

  Player copyWith({
    String? id,
    String? name,
    String? handle,
    double? level,
    String? tier,
    String? badge,
    Color? avatarColor,
    String? initials,
    String? city,
    int? wins,
    int? games,
    int? age,
    String? gender,
    String? email,
    String? bio,
    String? photoPath,
    Map<String, String>? tags,
  }) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        handle: handle ?? this.handle,
        level: level ?? this.level,
        tier: tier ?? this.tier,
        badge: badge ?? this.badge,
        avatarColor: avatarColor ?? this.avatarColor,
        initials: initials ?? this.initials,
        city: city ?? this.city,
        wins: wins ?? this.wins,
        games: games ?? this.games,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        photoPath: photoPath ?? this.photoPath,
        tags: tags ?? this.tags,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'handle': handle,
        'level': level,
        'tier': tier,
        'badge': badge,
        'avatarColor': avatarColor.value,
        'initials': initials,
        'city': city,
        'wins': wins,
        'games': games,
        'age': age,
        'gender': gender,
        'email': email,
        'bio': bio,
        'photoPath': photoPath,
        'tags': tags,
      };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        handle: m['handle'] as String,
        level: (m['level'] as num).toDouble(),
        tier: m['tier'] as String,
        badge: m['badge'] as String,
        avatarColor: Color((m['avatarColor'] as num?)?.toInt() ?? 0xFFD5C7FF),
        initials: m['initials'] as String,
        city: m['city'] as String,
        wins: m['wins'] as int,
        games: m['games'] as int,
        age: m['age'] as int,
        gender: m['gender'] as String,
        email: m['email'] as String?,
        bio: m['bio'] as String?,
        photoPath: m['photoPath'] as String?,
        tags: (m['tags'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
      );
}
