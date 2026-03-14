import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/nutrition_provider.dart';
import 'providers/hom_provider.dart';
import 'providers/firebase_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }
  
  runApp(const HomHomApp());
}

class HomHomApp extends StatelessWidget {
  const HomHomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FirebaseProvider()..initialize(),
        ),
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