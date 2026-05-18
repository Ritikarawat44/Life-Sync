import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class FirestoreService {
  final CollectionReference docs =
  FirebaseFirestore.instance.collection('documents');
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String get userId {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    return currentUser!.uid;}
  Future<void> addDocument(
      String name,
      DateTime dueDate,
      String category,
      String imageUrl,
      ) async {
    await docs.add({
      'name': name,
      'dueDate': Timestamp.fromDate(dueDate),
      'category': category,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': Timestamp.now(),
      'isPaid': false,
    });
  }
  Stream<QuerySnapshot> getDocuments() {
    if (currentUser == null) {
      return const Stream.empty();
    }return docs
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  Future<void> deleteDocument(String id) async {
    try {
      await docs.doc(id).delete();
    } catch (e) {
      print("Delete error: $e");
    }
  }
  Future<void> updateDocument(
      String id,
      String name,
      DateTime dueDate,
      String category, {
        String? imageUrl,
      }) async {
    try {
      Map<String, dynamic> updatedData = {
        'name': name,
        'dueDate': Timestamp.fromDate(dueDate),
        'category': category,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) {
        updatedData['imageUrl'] = imageUrl;
      }
      await docs.doc(id).update(updatedData);
    } catch (e) {
      print("Update error: $e");
    }
  }
  Future<void> updateDocumentStatus(String id, bool isPaid) async {
    try {
      await docs.doc(id).update({
        'isPaid': isPaid,
      });
    } catch (e) {
      print("Status update error: $e");
    }
  }
}