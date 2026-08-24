import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app.dart';
import 'src/core/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String envFile = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env',
  );
  await dotenv.load(fileName: envFile, isOptional: true);

  // Initialise SQLite — required for Flutter Web (sqflite_common_ffi_web).
  // No-op on mobile.
  await LocalDatabase.init();

  runApp(const HealthWithoutBordersApp());
}
