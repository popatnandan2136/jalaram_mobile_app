import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/shop_provider.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShopProvider()),
      ],
      child: const NpDigitalApp(),
    ),
  );
}


class NpDigitalApp extends StatelessWidget {
  const NpDigitalApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NP Digital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
