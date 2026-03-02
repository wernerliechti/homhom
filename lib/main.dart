import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/nutrition_provider.dart';
import 'providers/hom_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HomHomApp());
}

class HomHomApp extends StatelessWidget {
  const HomHomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NutritionProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'HomHom',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}