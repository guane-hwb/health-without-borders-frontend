// lib/src/core/routes/app_routes.dart

import 'package:flutter/material.dart';

import '../../features/admin/presentation/brigade_stats_screen.dart';
import '../../features/admin/presentation/manage_organizations_screen.dart';
import '../../features/admin/presentation/manage_users_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/nfc/presentation/loss_of_wristband_screen.dart';
import '../../features/nfc/presentation/read_nfc_screen.dart';
import '../../features/nfc/presentation/register/register_nfc_screen.dart';
import '../../features/sync/presentation/sync_queue_screen.dart';

abstract class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String manageOrgs = '/admin/manage-orgs';
  static const String manageUsers = '/admin/manage-users';
  static const String brigadeStats = '/admin/brigade-stats';
  static const String brigadeStatsOrg = '/admin/brigade-stats-org';
  static const String readNfc = '/nfc/read';
  static const String registerNfc = '/nfc/register';
  static const String lossWristband = '/nfc/loss-wristband';
  static const String syncQueue = '/sync/queue';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case manageOrgs:
        return MaterialPageRoute<void>(
          builder: (_) => const ManageOrganizationsScreen(),
          settings: settings,
        );
      case manageUsers:
        return MaterialPageRoute<void>(
          builder: (_) => const ManageUsersScreen(),
          settings: settings,
        );
      case brigadeStats:
        return MaterialPageRoute<void>(
          builder: (_) => const BrigadeStatsScreen(),
          settings: settings,
        );
      case brigadeStatsOrg:
        return MaterialPageRoute<void>(
          builder: (_) =>
              const BrigadeStatsScreen(scopeToOwnOrganization: true),
          settings: settings,
        );
      case readNfc:
        return MaterialPageRoute<void>(
          builder: (_) => const ReadNfcScreen(),
          settings: settings,
        );
      case registerNfc:
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterNfcScreen(),
          settings: settings,
        );
      case lossWristband:
        return MaterialPageRoute<void>(
          builder: (_) => const LossOfWristbandScreen(),
          settings: settings,
        );
      case syncQueue:
        return MaterialPageRoute<void>(
          builder: (_) => const SyncQueueScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
