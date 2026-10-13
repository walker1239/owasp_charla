import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await ApiClient.create();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(api)..bootstrap(),
      child: const VulnBankApp(),
    ),
  );
}
