import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/game.dart';
import 'models/booking.dart';
import 'models/friend.dart';

// ─── Players ─────────────────────────────────────────────────────────────────
// Real users will be added once backend integration ships.
// kPlayers is intentionally empty so the app shows live data only.
const kPlayers = <Player>[];

/// Snapshots of remote players (e.g. join-request authors from other devices).
/// Populated by `GameSyncService` listeners; consumed transparently by
/// `playerById` so existing UI code keeps working without changes.
final Map<String, Player> kRemotePlayers = {};

void registerRemotePlayer(Player p) {
  kRemotePlayers[p.id] = p;
}

Player? playerById(String id) {
  if (id == kMe.id) return kMe;
  try {
    return kPlayers.firstWhere((p) => p.id == id);
  } catch (_) {
    return kRemotePlayers[id];
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
const kGames = <Game>[
  Game(id: 'g1', club: 'Padel Up Karachi',   area: 'DHA Phase 8',    when: 'Today', time: '6:30 PM',  duration: '90 min',  level: 'Pro',     levelKey: 'pro',     price: 1200, spots: 1, total: 4, hostId: 'me', playerIds: ['me'], vibe: 'Competitive',        court: 'Court 2 · Indoor',   weather: 'Indoor',      hot: true),
  Game(id: 'g2', club: 'The Padel Club',      area: 'Clifton',        when: 'Today', time: '9:00 PM',  duration: '60 min',  level: 'Regular', levelKey: 'regular', price: 900,  spots: 2, total: 4, hostId: 'me', playerIds: ['me'],  vibe: 'Social',             court: 'Court 1 · Outdoor',  weather: '28°C · Clear',hot: false),
  Game(id: 'g3', club: 'Bahria Padel Arena',  area: 'Bahria Town',    when: 'Tomorrow', time: '7:00 AM',  duration: '90 min',  level: 'Regular', levelKey: 'regular', price: 800,  spots: 1, total: 4, hostId: 'me', playerIds: ['me'],  vibe: 'Practice',           court: 'Court 4 · Outdoor',  weather: '24°C · Cloudy', hot: false),
  Game(id: 'g4', club: 'Smash Padel',         area: 'DHA Phase 6',    when: 'Saturday', time: '5:00 PM',  duration: '90 min',  level: 'Elite',   levelKey: 'elite',   price: 1400, spots: 3, total: 4, hostId: 'me', playerIds: ['me'],             vibe: 'Competitive',        court: 'Court 1 · Indoor',   weather: 'Indoor',      hot: true),
  Game(id: 'g5', club: 'Padel Up Karachi',    area: 'DHA Phase 8',    when: 'Sunday', time: '11:00 AM', duration: '60 min',  level: 'Rookie', levelKey: 'rookie',  price: 700,  spots: 2, total: 4, hostId: 'me', playerIds: ['me'],        vibe: 'Beginner-friendly',  court: 'Court 3 · Indoor',   weather: 'Indoor',      hot: false),
];

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
