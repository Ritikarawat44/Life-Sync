import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'expense_screen.dart';
import 'expense_list_screen.dart';

import '../models/document.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

import 'document_screen.dart';
import 'document_list_screen.dart';
import 'add_task_screen.dart';
import 'dashboard_screen.dart';
import 'bill_screen.dart';

import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;

  const HomeScreen({super.key, this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  final AuthService authService = AuthService();

  // 🔥 NEW: EXPENSE + BILL LOGIC
  Future<double> getMonthlyExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    double total = 0;

    DateTime now = DateTime.now();

    bool isThisMonth(DateTime date) {
      return date.month == now.month && date.year == now.year;
    }

    // 💸 EXPENSES
    final expenseSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user!.uid)
        .get();

    for (var doc in expenseSnap.docs) {
      try {
        DateTime date = (doc['date'] as Timestamp).toDate();
        if (!isThisMonth(date)) continue;

        total += (doc['amount'] as num).toDouble();
      } catch (_) {}
    }

    // 💰 BILLS (ONLY PAID)
    final billSnap = await FirebaseFirestore.instance
        .collection('bills')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var doc in billSnap.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        bool isPaid = data['isPaid'] == true;
        if (!isPaid) continue;

        DateTime due = (data['dueDate'] as Timestamp).toDate();
        if (!isThisMonth(due)) continue;

        total += (data['amount'] as num).toDouble();
      } catch (_) {}
    }

    return total;
  }

  String getSuggestion(List<Document> documents) {
    if (documents.isEmpty) return "Start adding documents!";

    DateTime today = DateTime.now();

    bool hasExpiringSoon = documents.any((doc) {
      int diff = doc.dueDate.difference(today).inDays;
      return diff <= 3 && diff >= 0;
    });

    bool hasExpired =
    documents.any((doc) => doc.dueDate.isBefore(today));

    if (hasExpired) return "⚠️ Some documents expired!";
    if (hasExpiringSoon) return "⏰ Documents expiring soon!";

    return "All documents are safe ✅";
  }

  void addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen()),
    );

    if (result != null) {
      setState(() {
        tasks.add(Task(title: result));
      });
    }
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();
              Navigator.pop(context);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget buildCardButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Life Admin",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode,
                color: Theme.of(context).iconTheme.color),
            onPressed: widget.toggleTheme,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, color: Colors.black)
                  : null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout,
                color: Theme.of(context).iconTheme.color),
            onPressed: showLogoutDialog,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: addTask,
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 STATUS + EXPENSE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('documents')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                List<Document> documents = docs.map((doc) {
                  return Document(
                    title: doc['name'],
                    dueDate:
                    (doc['dueDate'] as Timestamp).toDate(),
                    category: doc['category'] ?? "General",
                  );
                }).toList();

                return FutureBuilder<double>(
                  future: getMonthlyExpense(),
                  builder: (context, expenseSnap) {

                    String text = documents.isEmpty
                        ? "No documents yet 📂"
                        : getSuggestion(documents);

                    if (expenseSnap.hasData) {
                      text +=
                      "\n💸 This month: ₹${expenseSnap.data!.toInt()}";
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [

                  buildCardButton("Add Document", Icons.add, Colors.blue,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DocumentScreen()),
                      )),

                  buildCardButton("View Documents", Icons.folder,
                      Colors.purple, () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DocumentListScreen()),
                      )),

                  buildCardButton("Dashboard", Icons.dashboard,
                      Colors.indigo, () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const DashboardScreen()),
                      )),

                  buildCardButton("Bills Management 💰",
                      Icons.account_balance_wallet, Colors.green,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BillScreen()),
                      )),

                  buildCardButton("Expense Dashboard 📊",
                      Icons.pie_chart, Colors.orange,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const ExpenseScreen()),
                      )),

                  buildCardButton("Expenses 💸", Icons.money,
                      Colors.teal, () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ExpenseListScreen()),
                      )),

                  const SizedBox(height: 20),

                  tasks.isEmpty
                      ? const Center(child: Text("No tasks added"))
                      : Column(
                    children: tasks.map((task) {
                      return TaskTile(
                        task: task,
                        onChanged: (val) {
                          setState(() {
                            task.isDone = val!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}