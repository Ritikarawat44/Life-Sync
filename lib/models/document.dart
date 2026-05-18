class Document {
  String title;
  DateTime dueDate;
  String category; // ✅ NEW

  Document({
    required this.title,
    required this.dueDate,
    required this.category,
  });
}