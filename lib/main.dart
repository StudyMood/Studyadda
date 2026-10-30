import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/catalog_provider.dart';
import 'providers/media_provider.dart';
import 'providers/study_progress_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/unlock_screen.dart';
import 'services/crypto_service.dart';
import 'services/media_storage_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final mediaStorageService = MediaStorageService();
  await mediaStorageService.init();

  final cryptoService = CryptoService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<CryptoService>.value(value: cryptoService),
        Provider<MediaStorageService>.value(value: mediaStorageService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider<StudyProgressProvider>(
          create: (_) => StudyProgressProvider(storageService),
        ),
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(cryptoService, storageService),
        ),
        ChangeNotifierProvider<MediaProvider>(
          create: (_) => MediaProvider(mediaStorageService),
        ),
      ],
      child: const StudyHubApp(),
    ),
  );
}

class StudyHubApp extends StatelessWidget {
  const StudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Study Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<CatalogProvider>(
        builder: (context, catalog, _) {
          if (!catalog.isUnlocked) {
            return const UnlockScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
