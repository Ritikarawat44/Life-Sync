import 'package:flutter/material.dart';
import '../services/bill_service.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();

  // ✅ NEW: UPI CONTROLLER
  final _upi = TextEditingController();

  DateTime? _dueDate;

  String _category = "Electricity";
  String _repeat = "Monthly";
  int _reminderDays = 3;

  final service = BillService();
  bool loading = false;

  final List<String> categories = [
    "Electricity",
    "Rent",
    "Subscription",
    "EMI",
    "SIP",
    "Water Bill",
    "Taxes",
  ];

  final List<String> repeatOptions = [
    "Monthly",
    "6 Months",
    "Yearly",
  ];

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> save() async {
    if (_title.text.isEmpty ||
        _amount.text.isEmpty ||
        _dueDate == null ||
        _upi.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    await service.addBill(
      title: _title.text.trim(),
      amount: double.parse(_amount.text),
      dueDate: _dueDate!,
      category: _category,
      reminderDays: _reminderDays,
      repeat: _repeat,
      upiId: _upi.text.trim(), // ✅ NEW
    );

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Bill")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // TITLE
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            // AMOUNT
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            const SizedBox(height: 10),

            // 💳 UPI FIELD (NEW)
            TextField(
              controller: _upi,
              decoration: const InputDecoration(
                labelText: "UPI ID",
                hintText: "example@upi",
              ),
            ),

            const SizedBox(height: 10),

            // DATE
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? "Pick Due Date"
                        : _dueDate.toString().split(' ')[0],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: pickDate,
                )
              ],
            ),

            const SizedBox(height: 10),

            // CATEGORY
            DropdownButtonFormField(
              value: _category,
              items: categories
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: "Category"),
            ),

            // REPEAT
            DropdownButtonFormField(
              value: _repeat,
              items: repeatOptions
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _repeat = v!),
              decoration: const InputDecoration(labelText: "Repeat"),
            ),

            // REMINDER
            DropdownButtonFormField(
              value: _reminderDays,
              items: [7, 3, 1]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text("$e days before"),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _reminderDays = v!),
              decoration: const InputDecoration(labelText: "Reminder"),
            ),

            const SizedBox(height: 20),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: loading ? null : save,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Bill"),
            ),
          ],
        ),
      ),
    );
  }
}