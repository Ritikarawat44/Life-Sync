import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bill_service.dart';
import 'add_bill_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen>
    with WidgetsBindingObserver {
  final BillService service = BillService();

  String filter = "All";

  String? pendingBillId;
  bool isReturningFromPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        isReturningFromPayment &&
        pendingBillId != null) {

      isReturningFromPayment = false;

      bool? result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Payment Confirmation"),
          content: const Text("Did you complete the payment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        ),
      );

      if (result == true) {
        service.togglePaid(pendingBillId!, true);
      }

      pendingBillId = null;
    }
  }

  Color getColor(int days, bool paid) {
    if (paid) return Colors.green;
    if (days < 0) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.blue;
  }

  int calculateDays(DateTime due) {
    DateTime today = DateTime.now();
    DateTime cleanToday = DateTime(today.year, today.month, today.day);
    DateTime cleanDue = DateTime(due.year, due.month, due.day);
    return cleanDue.difference(cleanToday).inDays;
  }

  Future<void> payWithUPI(String upiId, double amount, String note) async {
    final uri = Uri.parse(
      "upi://pay?pa=$upiId&pn=BillPayment&am=$amount&cu=INR&tn=$note",
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch UPI app");
    }
  }

  Widget buildChart(List<QueryDocumentSnapshot> docs) {
    Map<int, double> monthlyData = {};

    for (var d in docs) {
      DateTime date = (d['dueDate'] as Timestamp).toDate();
      int month = date.month;
      double amount = (d['amount'] as num).toDouble();

      monthlyData[month] = (monthlyData[month] ?? 0) + amount;
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: monthlyData.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("My Bills 💰"),
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBillScreen()),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getBills(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          int total = docs.length;
          int paidCount = docs.where((d) => d['isPaid'] == true).length;
          int pending = total - paidCount;

          final filteredDocs = docs.where((d) {
            if (filter == "Paid") return d['isPaid'] == true;
            if (filter == "Unpaid") return d['isPaid'] != true;
            return true;
          }).toList();

          return Column(
            children: [

              // SUMMARY
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    summaryBox("Total", total, Colors.blue),
                    summaryBox("Paid", paidCount, Colors.green),
                    summaryBox("Pending", pending, Colors.red),
                  ],
                ),
              ),

              // GRAPH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildChart(docs),
              ),

              const SizedBox(height: 10),

              // FILTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["All", "Paid", "Unpaid"].map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(e),
                      selected: filter == e,
                      onSelected: (_) {
                        setState(() => filter = e);
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // LIST
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, i) {
                    var d = filteredDocs[i];

                    DateTime due =
                    (d['dueDate'] as Timestamp).toDate();
                    int days = calculateDays(due);
                    bool paid = d['isPaid'] ?? false;

                    Map<String, dynamic> data =
                    d.data() as Map<String, dynamic>;

                    String upiId =
                    data.containsKey('upiId') ? data['upiId'] : "";

                    Color color = getColor(days, paid);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt, color: color),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(d['title'],
                                    style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold)),
                                Text("₹${d['amount']}"),
                                Text(
                                    "Due: ${due.toString().split(' ')[0]}"),
                                Text(
                                  paid
                                      ? "Paid"
                                      : "Due in $days days",
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                          ),

                          if (!paid)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (upiId.isEmpty) return;

                                pendingBillId = d.id;
                                isReturningFromPayment = true;

                                await payWithUPI(
                                  upiId,
                                  d['amount'],
                                  d['title'],
                                );
                              },
                              child: Text("Pay ₹${d['amount']}"),
                            ),

                          if (paid)
                            GestureDetector(
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('bills')
                                    .doc(d.id)
                                    .delete();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget summaryBox(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title),
          Text(
            "$value",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}