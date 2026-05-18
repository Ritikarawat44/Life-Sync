import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class BillService {
  final CollectionReference _col =
  FirebaseFirestore.instance.collection('bills');
  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }return user.uid;
  }
  Future<void> addBill({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String category,
    required int reminderDays,
    required String repeat,
    required String upiId, // ✅ NEW
  }) async {
    try {
      await _col.add({
        'title': title,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'category': category,
        'isPaid': false,
        'reminderDays': reminderDays,
        'repeat': repeat,
        'userId': userId,
        'createdAt': Timestamp.now(),
        'upiId': upiId, // ✅ NEW
      });
    } catch (e) {
      print("Add bill error: $e");
    }
  }
  Stream<QuerySnapshot> getBills() {
    try {
      return _col
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print("Get bills error: $e");
      return const Stream.empty();
    }
  }
  Future<void> togglePaid(String id, bool value) async {
    try {
      await _col.doc(id).update({'isPaid': value});
    } catch (e) {
      print("Toggle error: $e");
    }
  }

  // ✅ DELETE BILL
  Future<void> deleteBill(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      print("Delete error: $e");
    }
  }

  // ✅ UPDATE BILL (OPTIONAL: ADD UPI UPDATE TOO)
  Future<void> updateBill(
      String id,
      String title,
      double amount,
      DateTime dueDate,
      String category,
      String repeat, {
        String? upiId, // optional update
      }) async {
    try {
      Map<String, dynamic> data = {
        'title': title,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'category': category,
        'repeat': repeat,
      };

      if (upiId != null && upiId.isNotEmpty) {
        data['upiId'] = upiId;
      }

      await _col.doc(id).update(data);
    } catch (e) {
      print("Update error: $e");
    }
  }
}