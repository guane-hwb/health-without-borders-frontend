import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String envFile = String.fromEnvironment('ENV_FILE', defaultValue: '.env');
  await dotenv.load(fileName: envFile, isOptional: true);

  runApp(HealthWithoutBordersApp());
}
