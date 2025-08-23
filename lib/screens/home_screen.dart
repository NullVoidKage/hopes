import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Hopes'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut().catchError((error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: ${error.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User Avatar
            if (authService.userPhotoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(authService.userPhotoURL!),
              )
            else
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF667eea),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // App Icon
            const Icon(
              Icons.school,
              size: 100,
              color: Color(0xFF667eea),
            ),
            
            const SizedBox(height: 24),
            
            // Welcome message
            const Text(
              'Welcome to Hopes!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // User name
            if (authService.userDisplayName != null)
              Text(
                'Hello, ${authService.userDisplayName}!',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // User email
            if (authService.userEmail != null)
              Text(
                authService.userEmail!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            
            const SizedBox(height: 16),
            
            const Text(
              'You are successfully signed in.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
