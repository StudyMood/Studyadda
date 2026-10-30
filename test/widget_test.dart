import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_hub/providers/catalog_provider.dart';
import 'package:study_hub/providers/study_progress_provider.dart';
import 'package:study_hub/providers/theme_provider.dart';
import 'package:study_hub/screens/unlock_screen.dart';
import 'package:study_hub/services/crypto_service.dart';
import 'package:study_hub/services/storage_service.dart';
import 'package:study_hub/utils/app_theme.dart';

void main() {
  testWidgets('StudyHubApp launches into UnlockScreen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final crypto = CryptoService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<CryptoService>.value(value: crypto),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(storage)),
          ChangeNotifierProvider<StudyProgressProvider>(create: (_) => StudyProgressProvider(storage)),
          ChangeNotifierProvider<CatalogProvider>(create: (_) => CatalogProvider(crypto, storage)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const UnlockScreen(),
        ),
      ),
    );

    expect(find.text('Study Hub'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unlock Study Hub'), findsOneWidget);
  });
}
