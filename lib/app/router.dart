import 'package:go_router/go_router.dart';

import '../features/adapter_profile/presentation/adapter_edit_screen.dart';
import '../features/adapter_profile/presentation/adapter_list_screen.dart';
import '../features/collimation/presentation/camera_screen.dart';
import '../features/collimation/presentation/session_setup_screen.dart';
import '../features/guide/presentation/guide_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/history/presentation/session_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/telescope_profile/presentation/telescope_edit_screen.dart';
import '../features/telescope_profile/presentation/telescope_list_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/setup', builder: (_, _) => const SessionSetupScreen()),
    GoRoute(path: '/collimate', builder: (_, _) => const CameraScreen()),
    GoRoute(path: '/telescopes', builder: (_, _) => const TelescopeListScreen()),
    GoRoute(
      path: '/telescopes/edit',
      builder: (_, state) =>
          TelescopeEditScreen(profileId: state.uri.queryParameters['id']),
    ),
    GoRoute(path: '/adapters', builder: (_, _) => const AdapterListScreen()),
    GoRoute(
      path: '/adapters/edit',
      builder: (_, state) =>
          AdapterEditScreen(profileId: state.uri.queryParameters['id']),
    ),
    GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
    GoRoute(
      path: '/history/session',
      builder: (_, state) =>
          SessionDetailScreen(sessionId: state.uri.queryParameters['id']!),
    ),
    GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
  ],
);
