import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';
const String taskName = "checkExpiryTask";
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();
    if (task == taskName) {
      await checkExpiringDocuments();
      await checkBillReminders();
      await sendDailySummary();
      await handleRecurringBills(); // 🔥 STEP 3 ADDED
    }
    return Future.value(true);
  });
}
Future<void> checkExpiringDocuments() async {
  final snapshot =
  await FirebaseFirestore.instance.collection('documents').get();
  DateTime today = DateTime.now();
  DateTime cleanToday = DateTime(today.year, today.month, today.day);

  for (var doc in snapshot.docs) {
    DateTime dueDate = (doc['dueDate'] as Timestamp).toDate();
    DateTime cleanDue =
    DateTime(dueDate.year, dueDate.month, dueDate.day);
    int days = cleanDue.difference(cleanToday).inDays;
    String docName = doc['name'];
    if (days >= 0 && days <= 2) {
      await NotificationService.showNotification(
        "Document Reminder ⚠️",
        days == 0
            ? "$docName expires TODAY 🚨"
            : days == 1
            ? "$docName expires TOMORROW ⏰"
            : "$docName expires in $days days",
      );
    }
  }
}

// 💰 BILL REMINDERS
Future<void> checkBillReminders() async {
  final snapshot =
  await FirebaseFirestore.instance.collection('bills').get();
  DateTime today = DateTime.now();
  DateTime cleanToday = DateTime(today.year, today.month, today.day);
  for (var bill in snapshot.docs) {
    DateTime dueDate = (bill['dueDate'] as Timestamp).toDate();
    DateTime cleanDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    int days = cleanDue.difference(cleanToday).inDays;
    String title = bill['title'];
    bool isPaid = bill['isPaid'] ?? false;
    int reminderDays = bill['reminderDays'] ?? 3;
    if (isPaid) continue;
    if (days == reminderDays || days == 1 || days == 0) {
      await NotificationService.showNotification(
        "Bill Reminder 💰",
        days == 0
            ? "$title is due TODAY 🚨"
            : days == 1
            ? "$title is due TOMORROW ⏰"
            : "$title is due in $days days",
      );
    }
  }
}

// 📊 DAILY SUMMARY
Future<void> sendDailySummary() async {
  final docs = await FirebaseFirestore.instance.collection('documents').get();
  final bills = await FirebaseFirestore.instance.collection('bills').get();
  DateTime today = DateTime.now();
  DateTime cleanToday = DateTime(today.year, today.month, today.day);

  int docExpiring = 0;
  int docExpired = 0;
  int billDue = 0;
  int billOverdue = 0;
  for (var d in docs.docs) {
    DateTime due = (d['dueDate'] as Timestamp).toDate();
    DateTime cleanDue = DateTime(due.year, due.month, due.day);
    int days = cleanDue.difference(cleanToday).inDays;
    if (days < 0) docExpired++;
    else if (days <= 2) docExpiring++;
  }for (var b in bills.docs) {
    DateTime due = (b['dueDate'] as Timestamp).toDate();
    DateTime cleanDue = DateTime(due.year, due.month, due.day);

    int days = cleanDue.difference(cleanToday).inDays;

    bool paid = b['isPaid'] ?? false;
    if (paid) continue;

    if (days < 0) billOverdue++;
    else if (days <= 2) billDue++;
  }

  if (docExpiring == 0 &&
      docExpired == 0 &&
      billDue == 0 &&
      billOverdue == 0) {
    return;
  }String message = "";
  if (docExpired > 0) {
    message += "⚠️ $docExpired documents expired\n";
  }
  if (docExpiring > 0) {
    message += "📄 $docExpiring documents expiring soon\n";
  }
  if (billOverdue > 0) {
    message += "💰 $billOverdue bills overdue\n";
  }
  if (billDue > 0) {
    message += "💸 $billDue bills due soon";
  }

  await NotificationService.showNotification(
    "Daily Summary 📊",
    message.trim(),
  );
}

// 🔁 STEP 3: RECURRING BILLS LOGIC
Future<void> handleRecurringBills() async {
  final snapshot =
  await FirebaseFirestore.instance.collection('bills').get();
  DateTime today = DateTime.now();
  for (var bill in snapshot.docs) {
    DateTime due = (bill['dueDate'] as Timestamp).toDate();
    String repeat = bill['repeat'] ?? "none";
    bool isPaid = bill['isPaid'] ?? false;
    if (repeat == "none" || isPaid) continue;
    if (due.isBefore(today)) {
      DateTime newDate;
      if (repeat == "monthly") {
        newDate = DateTime(due.year, due.month + 1, due.day);
      } else if (repeat == "weekly") {
        newDate = due.add(const Duration(days: 7));
      } else {
        continue;
      }

      // 🔒 Prevent duplicate creation
      final existing = await FirebaseFirestore.instance
          .collection('bills')
          .where('title', isEqualTo: bill['title'])
          .where('dueDate', isEqualTo: Timestamp.fromDate(newDate))
          .where('userId', isEqualTo: bill['userId'])
          .get();
      if (existing.docs.isNotEmpty) continue;
      await FirebaseFirestore.instance.collection('bills').add({
        'title': bill['title'],
        'amount': bill['amount'],
        'dueDate': Timestamp.fromDate(newDate),
        'category': bill['category'],
        'isPaid': false,
        'reminderDays': bill['reminderDays'] ?? 3,
        'repeat': repeat,
        'userId': bill['userId'],
        'createdAt': Timestamp.now(),
      });

      // ✔ Mark old as paid
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(bill.id)
          .update({'isPaid': true});
    }
  }
}