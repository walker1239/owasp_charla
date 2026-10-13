import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/integrity.dart';
import 'core/logger.dart';
import 'core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [fix/M7] Comprobación anti-root/jailbreak y anti-instrumentación.
  if (await Integrity.isRootedOrJailbroken() ||
      await Integrity.isInstrumented()) {
    Log.info('ADVERTENCIA: entorno comprometido (root/jailbreak o Frida).');
  }

  final api = await ApiClient.create();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(api)..bootstrap(),
      child: const VulnBankApp(),
    ),
  );
}
