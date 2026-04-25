import 'package:get/get.dart';
import 'routes.dart';
import '../screens/sign_up/sign_up_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/browse/browse_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/host/host_screen.dart';
import '../screens/requests/requests_screen.dart';
import '../screens/join/join_screen.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/match_finished/match_finished_screen.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage>[
    GetPage(name: Routes.signUp,       page: () => const SignUpScreen()),
    GetPage(name: Routes.home,         page: () => const HomeScreen()),
    GetPage(name: Routes.browse,       page: () => const BrowseScreen()),
    GetPage(name: Routes.detail,       page: () => const DetailScreen()),
    GetPage(name: Routes.host,         page: () => const HostScreen()),
    GetPage(name: Routes.requests,     page: () => const RequestsScreen()),
    GetPage(name: Routes.join,         page: () => const JoinScreen()),
    GetPage(name: Routes.inbox,        page: () => const InboxScreen()),
    GetPage(name: Routes.chat,         page: () => const ChatScreen()),
    GetPage(name: Routes.friends,      page: () => const FriendsScreen()),
    GetPage(name: Routes.profile,      page: () => const ProfileScreen()),
    GetPage(name: Routes.subscription, page: () => const SubscriptionScreen()),
    GetPage(name: Routes.matchFinished,page: () => const MatchFinishedScreen()),
  ];
}
