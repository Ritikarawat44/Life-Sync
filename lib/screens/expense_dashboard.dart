import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseDashboard extends StatelessWidget {
  const ExpenseDashboard({super.key});

  bool isThisMonth(DateTime date) {
    DateTime now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }

  Future<Map<String, double>> getData() async {
    final user = FirebaseAuth.instance.currentUser;

    double total = 0;
    double paid = 0;
    double unpaid = 0;

    // 💸 EXPENSES
    final expensesSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user!.uid)
        .get();

    for (var doc in expensesSnap.docs) {
      try {
        DateTime date = (doc['date'] as Timestamp).toDate();

        if (!isThisMonth(date)) continue;

        double amount = (doc['amount'] as num).toDouble();

        total += amount;
        paid += amount;
      } catch (_) {}
    }

    // 💰 BILLS
    final billsSnap = await FirebaseFirestore.instance
        .collection('bills')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var doc in billsSnap.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        DateTime due = (data['dueDate'] as Timestamp).toDate();

        if (!isThisMonth(due)) continue;

        double amount = (data['amount'] as num).toDouble();

        bool isPaid = data['isPaid'] == true;

        total += amount;

        if (isPaid) {
          paid += amount;
        } else {
          unpaid += amount;
        }
      } catch (_) {}
    }

    return {
      "total": total,
      "paid": paid,
      "unpaid": unpaid,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Dashboard 📊"),
        centerTitle: true,
      ),

      body: FutureBuilder<Map<String, double>>(
        future: getData(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!;

          double total = data["total"]!;
          double paid = data["paid"]!;
          double unpaid = data["unpaid"]!;

          // 🤖 AI SMART INSIGHT
          String aiInsight = "";

          if (paid > unpaid) {
            aiInsight =
            "✅ Great job! Most of your expenses are cleared this month.";
          } else if (unpaid > paid) {
            aiInsight =
            "⚠️ Your unpaid expenses are higher this month.";
          } else {
            aiInsight =
            "📊 Your paid and unpaid expenses are balanced.";
          }

          double paidPercent =
          total == 0 ? 0 : (paid / total).clamp(0, 1);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔥 TOTAL CARD
                  buildMainCard(total),

                  const SizedBox(height: 20),

                  // 🤖 AI INSIGHT CARD
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.deepPurple,
                          Colors.blue,
                        ],
                      ),

                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            aiInsight,

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔥 PROGRESS BAR
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Spending Overview",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: paidPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Paid: ₹${paid.toInt()}  |  Unpaid: ₹${unpaid.toInt()}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔥 SUMMARY CARDS
                  Row(
                    children: [

                      Expanded(
                        child: buildSmallCard(
                          "Paid",
                          paid,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: buildSmallCard(
                          "Unpaid",
                          unpaid,
                          Colors.red,
                          Icons.warning,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🔥 EXTRA INSIGHTS
                  if (total > 5000)
                    insightBox(
                      "⚠️ High spending detected this month!",
                      Colors.red,
                    ),

                  if (unpaid > 0)
                    insightBox(
                      "💡 You have unpaid bills pending!",
                      Colors.orange,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔥 MAIN CARD
  Widget buildMainCard(double amount) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.blue,
            Colors.indigo,
          ],
        ),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [

          const Text(
            "Total Spend (This Month)",

            style: TextStyle(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "₹${amount.toStringAsFixed(0)}",

            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 SMALL SUMMARY CARDS
  Widget buildSmallCard(
      String title,
      double amount,
      Color color,
      IconData icon,
      ) {

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(height: 5),

          Text(title),

          const SizedBox(height: 5),

          Text(
            "₹${amount.toStringAsFixed(0)}",

            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 INSIGHT BOX
  Widget insightBox(String text, Color color) {

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [

          Icon(
            Icons.info,
            color: color,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}