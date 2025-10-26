import 'package:firebase_database/firebase_database.dart';
import '../models/student_approval.dart';

class StudentApprovalService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create a new student approval request
  Future<String> createApprovalRequest(StudentApproval approval) async {
    try {
      final approvalRef = _database.child('student_approvals').push();
      final approvalId = approvalRef.key!;
      
      final approvalData = approval.copyWith(id: approvalId).toMap();
      await approvalRef.set(approvalData);
      
      return approvalId;
    } catch (e) {
      throw Exception('Failed to create approval request: ${e.toString()}');
    }
  }

  // Get all pending approval requests
  Future<List<StudentApproval>> getPendingApprovals() async {
    try {
      final snapshot = await _database
          .child('student_approvals')
          .orderByChild('status')
          .equalTo('pending')
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final Map<String, dynamic> approvalData = Map<String, dynamic>.from(entry.value);
          return StudentApproval.fromMap(approvalData);
        }).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get pending approvals: ${e.toString()}');
    }
  }

  // Get all approvals for a specific teacher
  Future<List<StudentApproval>> getApprovalsByTeacher(String teacherId) async {
    try {
      final snapshot = await _database
          .child('student_approvals')
          .orderByChild('teacherId')
          .equalTo(teacherId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final Map<String, dynamic> approvalData = Map<String, dynamic>.from(entry.value);
          return StudentApproval.fromMap(approvalData);
        }).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get teacher approvals: ${e.toString()}');
    }
  }

  // Get approval by student ID
  Future<StudentApproval?> getApprovalByStudentId(String studentId) async {
    try {
      final snapshot = await _database
          .child('student_approvals')
          .orderByChild('studentId')
          .equalTo(studentId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final entry = data.entries.first;
        final Map<String, dynamic> approvalData = Map<String, dynamic>.from(entry.value);
        return StudentApproval.fromMap(approvalData);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get student approval: ${e.toString()}');
    }
  }

  // Approve a student
  Future<void> approveStudent(String approvalId, String teacherId, String teacherName, {String? notes}) async {
    try {
      final approvalRef = _database.child('student_approvals').child(approvalId);
      
      await approvalRef.update({
        'status': 'approved',
        'teacherId': teacherId,
        'teacherName': teacherName,
        'reviewedAt': ServerValue.timestamp,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to approve student: ${e.toString()}');
    }
  }

  // Reject a student
  Future<void> rejectStudent(String approvalId, String teacherId, String teacherName, String rejectionReason) async {
    try {
      final approvalRef = _database.child('student_approvals').child(approvalId);
      
      await approvalRef.update({
        'status': 'rejected',
        'teacherId': teacherId,
        'teacherName': teacherName,
        'reviewedAt': ServerValue.timestamp,
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw Exception('Failed to reject student: ${e.toString()}');
    }
  }

  // Check if student is approved
  Future<bool> isStudentApproved(String studentId) async {
    try {
      final approval = await getApprovalByStudentId(studentId);
      return approval?.isApproved ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get approval statistics
  Future<Map<String, int>> getApprovalStatistics() async {
    try {
      final snapshot = await _database.child('student_approvals').get();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int grade7 = 0;

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        
        for (final entry in data.entries) {
          final Map<String, dynamic> approvalData = Map<String, dynamic>.from(entry.value);
          final approval = StudentApproval.fromMap(approvalData);
          
          switch (approval.status) {
            case 'pending':
              pending++;
              break;
            case 'approved':
              approved++;
              break;
            case 'rejected':
              rejected++;
              break;
          }
          
          if (approval.isGrade7) {
            grade7++;
          }
        }
      }
      
      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'grade7': grade7,
        'total': pending + approved + rejected,
      };
    } catch (e) {
      throw Exception('Failed to get approval statistics: ${e.toString()}');
    }
  }

  // Delete an approval request
  Future<void> deleteApproval(String approvalId) async {
    try {
      await _database.child('student_approvals').child(approvalId).remove();
    } catch (e) {
      throw Exception('Failed to delete approval: ${e.toString()}');
    }
  }

  // Update approval notes
  Future<void> updateApprovalNotes(String approvalId, String notes) async {
    try {
      await _database.child('student_approvals').child(approvalId).update({
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to update approval notes: ${e.toString()}');
    }
  }
}
