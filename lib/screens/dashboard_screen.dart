import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 🔥 CHECK IF DOCUMENT HAS EXPIRY
  bool hasExpiry(String category) {
    return !(category == "Aadhar Card" ||
        category == "PAN Card");
  }

  // 🔥 CALCULATE DOCUMENT STATS
  Map<String, int> calculateStats(
      List<QueryDocumentSnapshot> docs) {

    int total = docs.length;
    int expired = 0;
    int expiring = 0;
    int safe = 0;

    DateTime today = DateTime.now();

    DateTime cleanToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    for (var doc in docs) {
      try {

        String category = doc['category'] ?? "";

        // 🔥 SKIP NON-EXPIRY DOCS
        if (!hasExpiry(category)) continue;

        DateTime due =
        (doc['dueDate'] as Timestamp).toDate();

        DateTime cleanDue = DateTime(
          due.year,
          due.month,
          due.day,
        );

        int days =
            cleanDue.difference(cleanToday).inDays;

        if (days < 0) {
          expired++;
        } else if (days <= 3) {
          expiring++;
        } else {
          safe++;
        }

      } catch (e) {
        debugPrint("Date error: $e");
      }
    }

    return {
      "total": total,
      "expired": expired,
      "expiring": expiring,
      "safe": safe,
    };
  }

  // 🔥 CARD UI
  Widget buildCard(
      String title,
      int count,
      Color color,
      IconData icon,
      ) {

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: color.withOpacity(0.1),

                borderRadius:
                BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,

              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              count.toString(),

              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 LOGOUT DIALOG
  void showLogoutDialog(BuildContext context) {

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(
          title: const Text("Logout"),

          content: const Text(
              "Are you sure you want to logout?"),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(context),

              child: const Text("No"),
            ),

            ElevatedButton(
              onPressed: () async {

                await FirebaseAuth.instance
                    .signOut();

                Navigator.pop(context);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },

              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Dashboard"),

        elevation: 0,

        backgroundColor: Colors.transparent,

        foregroundColor: Colors.black,

        actions: [

          IconButton(
            icon: const Icon(Icons.logout),

            onPressed: () =>
                showLogoutDialog(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('userId',
            isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading data"),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                  "No documents found 📂"),
            );
          }

          final docs = snapshot.data!.docs;

          final stats = calculateStats(docs);

          return SingleChildScrollView(

            child: Padding(
              padding:
              const EdgeInsets.all(12),

              child: Column(
                children: [

                  // 🔥 FIRST ROW
                  Row(
                    children: [

                      buildCard(
                        "Total",
                        stats["total"]!,
                        Colors.blue,
                        Icons.insert_drive_file,
                      ),

                      buildCard(
                        "Expired",
                        stats["expired"]!,
                        Colors.red,
                        Icons.warning,
                      ),
                    ],
                  ),

                  // 🔥 SECOND ROW
                  Row(
                    children: [

                      buildCard(
                        "Expiring",
                        stats["expiring"]!,
                        Colors.orange,
                        Icons.schedule,
                      ),

                      buildCard(
                        "Safe",
                        stats["safe"]!,
                        Colors.green,
                        Icons.verified,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🤖 AI SMART INSIGHT CARD
                  Container(
                    width: double.infinity,

                    padding:
                    const EdgeInsets.all(18),

                    decoration: BoxDecoration(

                      gradient:
                      const LinearGradient(
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
                          size: 30,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(

                            stats["expired"]! > 0
                                ? "⚠️ You have expired documents that need attention."
                                : stats["expiring"]! > 0
                                ? "📅 Some documents are expiring soon."
                                : "✅ All your important documents are safe.",

                            style:
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}