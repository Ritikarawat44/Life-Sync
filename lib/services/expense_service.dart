import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final _col = FirebaseFirestore.instance.collection('expenses');

  String get userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return user.uid;
  }

  // ✅ Add Expense
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    await _col.add({
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'createdAt': Timestamp.now(),
    });
  }

  // ✅ Get Expenses
  Stream<QuerySnapshot> getExpenses() {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ✅ Delete Expense
  Future<void> deleteExpense(String id) async {
    await _col.doc(id).delete();
  }

  // 🤖 AI Expense Insight Feature
  String generateExpenseInsight({
    required double currentMonth,
    required double previousMonth,
    required String category,
  }) {
    if (previousMonth == 0) {
      return "No previous month data available.";
    }

    double difference =
        ((currentMonth - previousMonth) / previousMonth) * 100;

    if (difference > 0) {
      return "$category expenses increased by "
          "${difference.toStringAsFixed(0)}% this month.";
    } else if (difference < 0) {
      return "$category expenses decreased by "
          "${difference.abs().toStringAsFixed(0)}% this month.";
    } else {
      return "$category expenses remained the same this month.";
    }
  }
}