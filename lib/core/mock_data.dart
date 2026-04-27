import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/game.dart';
import 'models/booking.dart';
import 'models/friend.dart';

// ─── Players ─────────────────────────────────────────────────────────────────
// Real users will be added once backend integration ships.
// kPlayers is intentionally empty so the app shows live data only.
const kPlayers = <Player>[];

Player? playerById(String id) {
  try {
    return kPlayers.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

// Default placeholder used until the user finishes sign-up.
const _kDefaultUser = Player(
  id: 'me',
  name: 'You',
  handle: '@you',
  level: 1.0,
  tier: 'rookie',
  badge: 'Rookie',
  avatarColor: Color(0xFFD5C7FF),
  initials: 'YO',
  city: '',
  wins: 0,
  games: 0,
  age: 0,
  gender: 'M',
);

// Mutable: AppController.updateCurrentUser keeps this in sync so legacy
// (non-reactive) reads of kMe still see the latest profile.
Player kMe = _kDefaultUser;

// ─── Games ───────────────────────────────────────────────────────────────────
// Real games will appear once users host them — no seed games.
const kGames = <Game>[];

// ─── Initial store state ──────────────────────────────────────────────────────
const kInitialBookings    = <Booking>[];
const kInitialFriends     = <FriendEntry>[];
const kInitialRequests    = <String, List<JoinRequest>>{};
const kInitialGameChats   = <String, List<ChatMessage>>{};
const kInitialFriendChats = <String, List<ChatMessage>>{};

// Pakistan cities + areas
const kPkCities = [
  'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad',
  'Multan', 'Peshawar', 'Quetta', 'Sialkot', 'Hyderabad', 'Gujranwala',
];

const kPkAreas = <String, List<String>>{
  'Karachi': [
    'DHA Phase 1', 'DHA Phase 2', 'DHA Phase 3', 'DHA Phase 4', 'DHA Phase 5',
    'DHA Phase 6', 'DHA Phase 7', 'DHA Phase 8', 'Clifton', 'Clifton Block 5',
    'Clifton Block 9', 'PECHS', 'Gulshan-e-Iqbal', 'North Nazimabad',
    'Bahria Town', 'Bahria Icon', 'Malir', 'Korangi', 'Saddar', 'Landhi',
  ],
  'Lahore': [
    'DHA Phase 1', 'DHA Phase 2', 'DHA Phase 3', 'DHA Phase 4', 'DHA Phase 5',
    'DHA Phase 6', 'Bahria Town Lahore', 'Gulberg', 'Model Town', 'Garden Town',
    'Johar Town', 'Township', 'Wapda Town', 'Cantt',
  ],
  'Islamabad': [
    'F-6', 'F-7', 'F-8', 'F-10', 'F-11', 'G-8', 'G-9', 'G-11',
    'DHA Islamabad', 'Bahria Town Islamabad', 'Blue Area', 'Margalla Hills',
    'E-11', 'I-8', 'I-10',
  ],
  'Rawalpindi': [
    'Bahria Town Rawalpindi', 'Saddar', 'Cantt', 'Chaklala', 'Westridge',
  ],
  'Faisalabad': ['Canal Road', 'Gulberg', 'Susan Road', 'Madina Town'],
  'Multan': ['Cantt', 'Gulgasht', 'Shah Rukn-e-Alam'],
  'Peshawar': ['University Town', 'Hayatabad', 'Cantt'],
  'Quetta': ['Cantt', 'Satellite Town'],
};
