class Bill {
  String title;
  double amount;
  DateTime dueDate;
  bool isPaid;
  String category;

  Bill({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    required this.category,
  });
}