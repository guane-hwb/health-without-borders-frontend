// lib/src/core/routes/app_routes.dart

import 'package:flutter/material.dart';

import '../../features/admin/presentation/brigade_stats_screen.dart';
import '../../features/admin/presentation/manage_organizations_screen.dart';
import '../../features/admin/presentation/manage_users_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/nfc/presentation/loss_of_wristband_screen.dart';
import '../../features/nfc/presentation/read_nfc_screen.dart';
import '../../features/nfc/presentation/register/register_nfc_screen.dart';
import '../../features/sync/presentation/sync_queue_screen.dart';
import '../di/app_scope.dart';

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
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        final authRepo = AppScope.of(context).authRepository;
        return _buildGuardedScreen(context, settings.name, authRepo);
      },
    );
  }

  static Widget _buildGuardedScreen(
    BuildContext context,
    String? routeName,
    AuthRepository authRepo,
  ) {
    if (routeName == login) {
      return const LoginScreen();
    }

    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      return const LoginScreen();
    }

    final role = currentUser.role;

    switch (routeName) {
      case home:
        return const HomeScreen();

      case readNfc:
        if (role.canReadPatients || role.canScanNfc) {
          return const ReadNfcScreen();
        }
        return _forbiddenScreen();

      case registerNfc:
        if (role.canRegisterPatient) {
          return const RegisterNfcScreen();
        }
        return _forbiddenScreen();

      case lossWristband:
        if (role.canSearchPatient) {
          return const LossOfWristbandScreen();
        }
        return _forbiddenScreen();

      case syncQueue:
        if (role.canSyncPatient) {
          return const SyncQueueScreen();
        }
        return _forbiddenScreen();

      case manageOrgs:
        if (role.isSuperadmin) {
          return const ManageOrganizationsScreen();
        }
        return _forbiddenScreen();

      case manageUsers:
        if (role.canManageUsers) {
          return const ManageUsersScreen();
        }
        return _forbiddenScreen();

      case brigadeStats:
        if (role.isSuperadmin) {
          return const BrigadeStatsScreen();
        }
        return _forbiddenScreen();

      case brigadeStatsOrg:
        if (role.canViewAnalytics) {
          return const BrigadeStatsScreen(scopeToOwnOrganization: true);
        }
        return _forbiddenScreen();

      default:
        return const HomeScreen();
    }
  }

  static Widget _forbiddenScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Restringido')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_maybe_rounded, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'No tienes permisos suficientes para acceder a esta sección.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
