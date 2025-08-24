import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'screens/auth_wrapper.dart';
import 'services/connectivity_service.dart';
import 'services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // Web configurationm m       mm
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDtu3oY49sezZNu_oIgNVh8uOLRyFaS-3I",
          authDomain: "hope-elearning-52e9b.firebaseapp.com",
          databaseURL: "https://hope-elearning-52e9b-default-rtdb.asia-southeast1.firebasedatabase.app",
          projectId: "hope-elearning-52e9b",
          storageBucket: "hope-elearning-52e9b.firebasestorage.app",
          messagingSenderId: "105306415530",
          appId: "1:105306415530:web:2909b849ca4890693b8bd3",
          measurementId: "G-5M0P8SBPDD",
        ),
      );
    } else {
      // Mobile configuration
      await Firebase.initializeApp();
    }

    // Initialize offline services with error handling
    try {
      ConnectivityService().initialize();
      
      // Note: Sample data will be populated after user authentication
      // to ensure we have the correct teacher ID
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing offline services: $e');
      }
      // Continue with app startup even if offline services fail
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during app initialization: $e');
    }
    // Continue with app startup even if Firebase fails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopes - E-Learning Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
