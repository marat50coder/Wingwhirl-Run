import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'hatchway/config/era_hatch_config.dart';
import 'hatchway/hatch_coordinator.dart';
import 'hatchway/infra/airway_probe.dart';
import 'hatchway/infra/egg_signal_hub.dart';
import 'hatchway/infra/flight_attribution.dart';
import 'hatchway/infra/hatch_exchange.dart';
import 'hatchway/infra/nest_vault.dart';
import 'hatchway/infra/roost_agent.dart';

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

  // ── Gray-flow services (white part = the fishing game) ───────────────────
  // These must be built before runApp and are the ONLY thing the white game
  // depends on: the boot/splash screen asks the coordinator which route to
  // take (organic → game, attributed → WebView portal).
  final vault = NestVault();
  final agent = RoostAgent();
  await Future.wait<void>(<Future<void>>[
    vault.initialize(),
    agent.prepare(),
  ]);

  var productionServicesReady = false;
  if (EraHatchConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
    } catch (error) {
      assert(() {
        debugPrint('[WWR.BOOT] Firebase.initializeApp failed: $error');
        return true;
      }());
    }
    if (productionServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        // App Check must never block FCM / gray routing.
        assert(() {
          debugPrint('[WWR.BOOT] AppCheck skipped: $error');
          return true;
        }());
      }
    }
  }

  final probe = AirwayProbe();
  final notifications = EggSignalHub(vault, enabled: productionServicesReady);
  final attribution = FlightAttribution(agent);
  final coordinator = HatchCoordinator(
    vault: vault,
    probe: probe,
    attribution: attribution,
    exchange: HatchExchange(agent, vault),
    notifications: notifications,
    agent: agent,
    runtimeEnabled: EraHatchConfig.grayCredentialsReady,
  );

  runApp(WingwhirlApp(hatchCoordinator: coordinator));
}
