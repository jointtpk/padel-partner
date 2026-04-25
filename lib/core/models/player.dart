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

  double get winRate => games > 0 ? wins / games : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'handle': handle,
        'level': level,
        'tier': tier,
        'badge': badge,
        'initials': initials,
        'city': city,
        'wins': wins,
        'games': games,
        'age': age,
        'gender': gender,
      };
}
