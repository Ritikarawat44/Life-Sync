import 'package:flutter/material.dart';
import '../models/bill.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  const BillCard({super.key, required this.bill});
  Color getStatusColor() {
    DateTime today = DateTime.now();
    int days = bill.dueDate.difference(today).inDays;
    if (bill.isPaid) return Colors.green;
    if (days < 0) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.blue;
  }
  String getStatusText() {
    if (bill.isPaid) return "Paid";
    int days = bill.dueDate.difference(DateTime.now()).inDays;
    if (days < 0) return "Overdue";
    if (days == 0) return "Due Today";
    return "Due in $days days";
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getStatusColor()),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: getStatusColor(),
            child: Icon(Icons.receipt, color: Colors.white),
          ),
          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text("₹${bill.amount}"),
                Text(getStatusText()),
              ],
            ),
          ),

          Icon(
            bill.isPaid ? Icons.check_circle : Icons.pending,
            color: getStatusColor(),
          ),
        ],
      ),
    );
  }
}