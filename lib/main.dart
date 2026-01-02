import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // NEW
import 'providers/user_provider.dart';   // NEW
import 'screens/auth/welcome_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // (Your existing Firebase.initializeApp code here...)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBNsbj7mbFSSrxKim0BbQdoxX1qhes2v5w",
        appId: "1:1006588050340:android:48eea5d71cc30de2b51f31",
        messagingSenderId: "1006588050340",
        projectId: "exhibitionapp-b97aa",
        storageBucket: "exhibitionapp-b97aa.firebasestorage.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const ExhibitionApp(),
    ),
  );
}

class ExhibitionApp extends StatelessWidget {
  const ExhibitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exhibition Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WelcomeScreen(),
    );
  }
}