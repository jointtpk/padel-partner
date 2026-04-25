import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/game.dart';
import 'models/booking.dart';
import 'models/friend.dart';

// ─── Players ─────────────────────────────────────────────────────────────────
const kPlayers = <Player>[
  Player(id: 'u1', name: 'Zara A.',    handle: '@zaraplays',  level: 3.8, tier: 'pro',     badge: 'Pro',     avatarColor: Color(0xFFF4B1FF), initials: 'ZA', city: 'Clifton',     wins: 47, games: 112, age: 27, gender: 'F'),
  Player(id: 'u2', name: 'Hassan M.',  handle: '@hasspadel', level: 4.6, tier: 'elite',   badge: 'Elite',   avatarColor: Color(0xFFB9E6FF), initials: 'HM', city: 'DHA Phase 6', wins: 63, games: 98,  age: 31, gender: 'M'),
  Player(id: 'u3', name: 'Ayesha K.',  handle: '@ayekay',    level: 3.2, tier: 'regular', badge: 'Regular', avatarColor: Color(0xFFFFD56B), initials: 'AK', city: 'Bahria Town', wins: 28, games: 80,  age: 24, gender: 'F'),
  Player(id: 'u4', name: 'Omar R.',    handle: '@omarr',     level: 4.1, tier: 'pro',     badge: 'Pro',     avatarColor: Color(0xFFC6FF9C), initials: 'OR', city: 'DHA Phase 8', wins: 54, games: 91,  age: 34, gender: 'M'),
  Player(id: 'u5', name: 'Sara I.',    handle: '@saraislam', level: 2.0, tier: 'amateur', badge: 'Amateur', avatarColor: Color(0xFFFFC0B5), initials: 'SI', city: 'PECHS',       wins: 11, games: 38,  age: 22, gender: 'F'),
  Player(id: 'u6', name: 'Bilal J.',   handle: '@bilalj',    level: 1.2, tier: 'rookie',  badge: 'Rookie',  avatarColor: Color(0xFFD5C7FF), initials: 'BJ', city: 'Clifton',     wins: 4,  games: 16,  age: 19, gender: 'M'),
];

Player? playerById(String id) {
  try {
    return kPlayers.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

// ignore: prefer_const_declarations
final kMe = kPlayers[0]; // current user = u1 (Zara A.)

// ─── Games ───────────────────────────────────────────────────────────────────
const kGames = <Game>[
  Game(id: 'g1', club: 'Padel Up Karachi',   area: 'DHA Phase 8',    when: 'Today', time: '6:30 PM',  duration: '90 min',  level: 'Pro',     levelKey: 'pro',     price: 1200, spots: 1, total: 4, hostId: 'u2', playerIds: ['u2','u4','u1'], vibe: 'Competitive',        court: 'Court 2 · Indoor',   weather: 'Indoor',      hot: true),
  Game(id: 'g2', club: 'The Padel Club',      area: 'Clifton',        when: 'Today', time: '9:00 PM',  duration: '60 min',  level: 'Regular', levelKey: 'regular', price: 900,  spots: 2, total: 4, hostId: 'u1', playerIds: ['u1','u6'],       vibe: 'Social',             court: 'Court 1 · Outdoor',  weather: '28°C · Clear',hot: false),
  Game(id: 'g3', club: 'Bahria Padel Arena',  area: 'Bahria Town',    when: 'Tmrw',  time: '7:00 AM',  duration: '90 min',  level: 'Regular', levelKey: 'regular', price: 800,  spots: 1, total: 4, hostId: 'u3', playerIds: ['u3','u5','u6'],  vibe: 'Practice',           court: 'Court 4 · Outdoor',  weather: '24°C · Cloudy', hot: false),
  Game(id: 'g4', club: 'Smash Padel',         area: 'DHA Phase 6',    when: 'Sat',   time: '5:00 PM',  duration: '90 min',  level: 'Elite',   levelKey: 'elite',   price: 1400, spots: 3, total: 4, hostId: 'u4', playerIds: ['u4'],             vibe: 'Competitive',        court: 'Court 1 · Indoor',   weather: 'Indoor',      hot: true),
  Game(id: 'g5', club: 'Padel Up Karachi',    area: 'DHA Phase 8',    when: 'Sun',   time: '11:00 AM', duration: '60 min',  level: 'Rookie+', levelKey: 'rookie',  price: 700,  spots: 2, total: 4, hostId: 'u5', playerIds: ['u5','u1'],        vibe: 'Beginner-friendly',  court: 'Court 3 · Indoor',   weather: 'Indoor',      hot: false),
];

// ─── Initial store state ──────────────────────────────────────────────────────
final kInitialBookings = <Booking>[
  const Booking(gameId: 'g1', status: 'confirmed'),
];

final kInitialFriends = <FriendEntry>[
  const FriendEntry(userId: 'u2', status: 'friends'),
  const FriendEntry(userId: 'u4', status: 'friends'),
  const FriendEntry(userId: 'u3', status: 'pending_in'),
  const FriendEntry(userId: 'u6', status: 'pending_out'),
];

final kInitialRequests = <String, List<JoinRequest>>{
  'g4': [
    const JoinRequest(userId: 'u3', when: '2h ago', note: 'Keen, 4.0 level, can bring balls'),
    const JoinRequest(userId: 'u6', when: '30m ago', note: 'Down for Saturday!'),
  ],
  'g2': [
    const JoinRequest(userId: 'u5', when: '45m ago', note: 'First time — promise I can rally'),
  ],
};

final kInitialGameChats = <String, List<ChatMessage>>{
  'g1': [
    const ChatMessage(from: 'u2', text: 'yo team — bringing two extra paddles if anyone needs 🎾', t: '7:14 PM'),
    const ChatMessage(from: 'me', text: 'perfect, mine is cracked lol', t: '7:16 PM'),
    const ChatMessage(from: 'u4', text: 'parking is painful at padel up btw, come 15 min early', t: '7:18 PM'),
  ],
};

final kInitialFriendChats = <String, List<ChatMessage>>{
  'u2': [
    const ChatMessage(from: 'u2', text: 'bro that volley yesterday 🔥', t: 'Yesterday'),
    const ChatMessage(from: 'me', text: 'haha lucky swing', t: 'Yesterday'),
  ],
  'u4': [
    const ChatMessage(from: 'me', text: 'sunday 5pm still on?', t: '2d'),
    const ChatMessage(from: 'u4', text: '100% booked court 3', t: '2d'),
  ],
};

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
