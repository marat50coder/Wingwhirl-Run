import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive, full-screen experience.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Splash supports both orientations; the game locks to landscape later.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WingwhirlApp());
}
