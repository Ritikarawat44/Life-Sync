import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_bill_screen.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  bool isThisMonth(DateTime date) {
    DateTime now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }

  Future<Map<String, dynamic>> getData() async {
    final user = FirebaseAuth.instance.currentUser;

    final expensesSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user!.uid)
        .get();

    final billsSnap = await FirebaseFirestore.instance
        .collection('bills')
        .where('userId', isEqualTo: user.uid)
        .get();

    return {
      "expenses": expensesSnap.docs,
      "bills": billsSnap.docs,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Expense Dashboard 📊"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 6,

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddBillScreen(),
            ),
          );
        },
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: getData(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading data"),
            );
          }

          final data = snapshot.data ?? {};

          double total = 0;

          Map<String, double> categoryMap = {};

          // 🔥 EXPENSES
          for (var d in data["expenses"] ?? []) {

            try {

              DateTime date =
              (d['date'] as Timestamp).toDate();

              if (!isThisMonth(date)) continue;

              double amount =
              (d['amount'] as num).toDouble();

              String category =
                  d['category'] ?? "Other";

              total += amount;

              categoryMap[category] =
                  (categoryMap[category] ?? 0) + amount;

            } catch (e) {
              debugPrint("Expense error: $e");
            }
          }

          // 🔥 BILLS
          for (var d in data["bills"] ?? []) {

            try {

              final billData =
              d.data() as Map<String, dynamic>;

              bool isPaid =
                  billData['isPaid'] == true;

              if (!isPaid) continue;

              DateTime due =
              (billData['dueDate'] as Timestamp)
                  .toDate();

              if (!isThisMonth(due)) continue;

              double amount =
              (billData['amount'] as num)
                  .toDouble();

              String category =
                  billData['category'] ?? "Bills";

              total += amount;

              categoryMap[category] =
                  (categoryMap[category] ?? 0) + amount;

            } catch (e) {
              debugPrint("Bill error: $e");
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                // 🔥 TOTAL CARD
                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      const Text(
                        "Total Spend",

                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "₹${total.toStringAsFixed(0)}",

                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 ALERT
                if (total > 5000)
                  Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,

                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    child: Row(
                      children: [

                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                        ),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Text(
                            "You are spending more than usual",

                            style: TextStyle(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // 🤖 AI SMART INSIGHT
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        Colors.blue,
                      ],
                    ),

                    borderRadius:
                    BorderRadius.circular(20),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
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

                          total > 5000
                              ? "💡 Your spending increased this month."
                              : "✅ Your expenses are under control.",

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

                const SizedBox(height: 18),

                // 🔥 CHART CARD
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        const Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Spending Breakdown",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: total == 0
                              ? const Center(
                            child: Text(
                              "No expenses yet 📭",
                            ),
                          )

                              : PieChart(
                            PieChartData(

                              sections:
                              categoryMap.entries
                                  .where(
                                      (e) => e.value > 0)
                                  .map((entry) {

                                return PieChartSectionData(
                                  value: entry.value,

                                  title:
                                  "₹${entry.value.toInt()}",

                                  radius: 80,

                                  titleStyle:
                                  const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),

                              sectionsSpace: 3,
                              centerSpaceRadius: 50,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔥 CATEGORY TAGS
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,

                          children:
                          categoryMap.entries.map((entry) {

                            return Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color:
                                const Color(0xFFF1F5F9),

                                borderRadius:
                                BorderRadius.circular(20),
                              ),

                              child: Text(
                                "${entry.key} ₹${entry.value.toInt()}",

                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}