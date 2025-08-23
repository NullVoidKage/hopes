import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Web configuration
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
