import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import 'full_image_screen.dart';

class DocumentListScreen extends StatefulWidget {
  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final FirestoreService service = FirestoreService();

  String searchQuery = "";
  String selectedFilter = "All";

  final List<String> categories = [
    "Aadhar Card",
    "PAN Card",
    "Driving License",
    "Vehicle RC",
    "Voter ID",
    "Passport",
    "Visa",
    "ATM Card",
    "ID Card",
    "Bills",
    "PassportPhoto"
  ];

  // 🔥 STEP 4 FUNCTION
  bool hasExpiry(String category) {
    return !(category == "Aadhar Card" || category == "PAN Card");
  }

  Future<void> payWithUPI(String upiId, double amount, String note) async {
    final uri = Uri.parse(
      "upi://pay?pa=$upiId&pn=BillPayment&am=$amount&cu=INR&tn=$note",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void showPaymentDialog(BuildContext context, var doc) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Amount"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter amount"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              child: Text("Pay"),
              onPressed: () {
                double amount =
                    double.tryParse(amountController.text) ?? 0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enter valid amount")),
                  );
                  return;
                }

                Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;

                String upiId =
                data.containsKey('upiId') ? data['upiId'] : "";

                if (upiId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("UPI ID not available")),
                  );
                  return;
                }

                Navigator.pop(context);

                payWithUPI(upiId, amount, doc['name']);
                service.updateDocumentStatus(doc.id, true);
              },
            ),
          ],
        );
      },
    );
  }

  bool matchesFilter(DateTime dueDate) {
    DateTime today = DateTime.now();
    DateTime cleanToday = DateTime(today.year, today.month, today.day);
    DateTime cleanDue = DateTime(dueDate.year, dueDate.month, dueDate.day);

    int days = cleanDue.difference(cleanToday).inDays;

    if (selectedFilter == "Expired") return days < 0;
    if (selectedFilter == "Expiring") return days >= 0 && days <= 3;
    if (selectedFilter == "Safe") return days > 3;
    return true;
  }

  void showEditDialog(BuildContext context, var doc) {
    TextEditingController nameController =
    TextEditingController(text: doc['name']);

    DateTime selectedDate =
    (doc['dueDate'] as Timestamp).toDate();

    String selectedCategory = doc['category'] ?? "Aadhar Card";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Document"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Expiry: ${selectedDate.toString().split(' ')[0]}",
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      )
                    ],
                  ),

                  SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: categories.contains(selectedCategory)
                        ? selectedCategory
                        : categories[0],
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration:
                    InputDecoration(labelText: "Category"),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Update"),
              onPressed: () async {
                await service.updateDocument(
                  doc.id,
                  nameController.text.trim(),
                  selectedDate,
                  selectedCategory,
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Documents")),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search documents...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Expired", "Expiring", "Safe"]
                  .map((filter) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                ),
              ))
                  .toList(),
            ),
          ),

          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.getDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading data"));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No documents found 📂"));
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  String name =
                  doc['name'].toString().toLowerCase();
                  DateTime dueDate =
                  (doc['dueDate'] as Timestamp).toDate();

                  return name.contains(searchQuery) &&
                      matchesFilter(dueDate);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];

                    DateTime dueDate =
                    (doc['dueDate'] as Timestamp).toDate();

                    Map<String, dynamic> data =
                    doc.data() as Map<String, dynamic>;

                    String imageUrl =
                    data.containsKey('imageUrl')
                        ? data['imageUrl']
                        : "";

                    bool isPaid =
                    data.containsKey('isPaid') ? data['isPaid'] : false;

                    String category =
                        doc['category'] ?? "Aadhar Card";

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FullImageScreen(imageUrl: imageUrl),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : Icon(Icons.description),

                        title: Text(doc['name']),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ✅ FIXED LOGIC
                            if (!hasExpiry(category)) ...[
                              const Text("No Expiry ♾️"),
                              Text("Category: $category"),
                            ] else ...[
                              Text("Expiry: ${dueDate.toString().split(' ')[0]}"),
                              Text("Category: $category"),

                              if (category == "Bills") ...[
                                Text(
                                  isPaid ? "Paid ✅" : "Unpaid ❌",
                                  style: TextStyle(
                                    color: isPaid ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                Builder(
                                  builder: (_) {
                                    DateTime today = DateTime.now();
                                    DateTime cleanToday =
                                    DateTime(today.year, today.month, today.day);
                                    DateTime cleanDue =
                                    DateTime(dueDate.year, dueDate.month, dueDate.day);

                                    int days =
                                        cleanDue.difference(cleanToday).inDays;

                                    if (days < 0) {
                                      return Text("Expired ❌",
                                          style: TextStyle(color: Colors.red));
                                    } else if (days <= 3) {
                                      return Text("Expiring Soon ⚠️",
                                          style: TextStyle(color: Colors.orange));
                                    } else {
                                      return Text("Safe ✅",
                                          style: TextStyle(color: Colors.green));
                                    }
                                  },
                                ),
                              ],
                            ],
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (category == "Bills")
                              IconButton(
                                icon: Icon(Icons.payment, color: Colors.green),
                                onPressed: () {
                                  showPaymentDialog(context, doc);
                                },
                              ),

                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                showEditDialog(context, doc);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                service.deleteDocument(doc.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}