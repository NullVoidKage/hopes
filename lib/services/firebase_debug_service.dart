import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseDebugService {
  static Future<Map<String, dynamic>> testConnections() async {
    final results = <String, dynamic>{};
    
    try {
      // Test Authentication
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      results['auth'] = {
        'status': 'success',
        'currentUser': currentUser?.uid ?? 'no_user',
        'email': currentUser?.email ?? 'no_email',
      };
    } catch (e) {
      results['auth'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    try {
      // Test Storage
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('test_connection.txt');
      results['storage'] = {
        'status': 'success',
        'bucket': storage.app.options.storageBucket,
        'ref': ref.fullPath,
      };
    } catch (e) {
      results['storage'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    try {
      // Test Realtime Database
      final database = FirebaseDatabase.instance;
      final ref = database.ref().child('test_connection');
      results['database'] = {
        'status': 'success',
        'url': database.app.options.databaseURL,
        'ref': ref.path,
      };
    } catch (e) {
      results['database'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    return results;
  }

  static Future<Map<String, dynamic>> testStoragePermissions() async {
    final results = <String, dynamic>{};
    
    try {
      final storage = FirebaseStorage.instance;
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        results['storage_permissions'] = {
          'status': 'error',
          'error': 'No authenticated user',
        };
        return results;
      }

      // Test write permission
      final testRef = storage.ref().child('test_permissions/${currentUser.uid}/test.txt');
      final testData = 'Hello Firebase Storage!';
      
      try {
        await testRef.putData(Uint8List.fromList(testData.codeUnits));
        results['storage_write'] = {
          'status': 'success',
          'message': 'Write permission granted',
        };
        
        // Clean up test file
        await testRef.delete();
        results['storage_delete'] = {
          'status': 'success',
          'message': 'Delete permission granted',
        };
      } catch (e) {
        results['storage_write'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
      
    } catch (e) {
      results['storage_permissions'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    return results;
  }

  static Future<Map<String, dynamic>> testDatabasePermissions() async {
    final results = <String, dynamic>{};
    
    try {
      final database = FirebaseDatabase.instance;
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        results['database_permissions'] = {
          'status': 'error',
          'error': 'No authenticated user',
        };
        return results;
      }

      // Test write permission
      final testRef = database.ref().child('test_permissions/${currentUser.uid}');
      
      try {
        await testRef.set({
          'test': 'Hello Firebase Database!',
          'timestamp': ServerValue.timestamp,
        });
        results['database_write'] = {
          'status': 'success',
          'message': 'Write permission granted',
        };
        
        // Test read permission
        final snapshot = await testRef.get();
        if (snapshot.exists) {
          results['database_read'] = {
            'status': 'success',
            'message': 'Read permission granted',
            'data': snapshot.value,
          };
        }
        
        // Clean up test data
        await testRef.remove();
        results['database_delete'] = {
          'status': 'success',
          'message': 'Delete permission granted',
        };
      } catch (e) {
        results['database_write'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
      
    } catch (e) {
      results['database_permissions'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    return results;
  }

  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    results['connections'] = await testConnections();
    results['storage_permissions'] = await testStoragePermissions();
    results['database_permissions'] = await testDatabasePermissions();
    
    return results;
  }
}
