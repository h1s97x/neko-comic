import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'stores/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app store
  final appStore = AppStore();
  await appStore.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AppStore>.value(value: appStore),
      ],
      child: const NekoComicApp(),
    ),
  );
}
