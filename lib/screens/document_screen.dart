// (same imports — unchanged)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// ✅ OCR
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:major_project/services/firestore_service.dart';
import 'package:major_project/services/notification_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final TextEditingController nameController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

  final FirestoreService service = FirestoreService();

  File? selectedImage;
  final picker = ImagePicker();

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
    "PassportPhoto"
  ];

  String selectedCategory = "Aadhar Card";

  // 🔥 STEP 1: CHECK EXPIRY TYPE
  bool hasExpiry(String category) {
    return !(category == "Aadhar Card" || category == "PAN Card");
  }

  // ✅ OCR
  Future<String?> scanTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();

    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return recognizedText.text;
  }

  // ✅ EXTRACT DATE
  DateTime? extractDate(String text) {
    final regex = RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b');

    final match = regex.firstMatch(text);

    if (match != null) {
      String dateStr = match.group(0)!;

      try {
        return DateTime.parse(
          dateStr.replaceAll('/', '-').split('-').reversed.join('-'),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> pickDate() async {
    DateTime now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // 📸 PICK IMAGE
  Future<void> pickImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      setState(() {
        selectedImage = imageFile;
      });

      String? text = await scanTextFromImage(imageFile);

      if (text != null) {
        DateTime? detectedDate = extractDate(text);

        if (detectedDate != null) {
          setState(() {
            selectedDate = detectedDate;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Expiry date detected automatically ✅")),
          );
        }
      }
    }
  }

  // ☁️ CLOUDINARY UPLOAD
  Future<String> uploadToCloudinary(File imageFile) async {
    final cloudName = "dwyjsrbze";
    final uploadPreset = "my_unsigned_preset";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final resData = await response.stream.bytesToString();
      final data = json.decode(resData);
      return data['secure_url'];
    } else {
      throw Exception("Image upload failed");
    }
  }

  // 💾 SAVE DOCUMENT
  Future<void> saveDocument() async {
    if (nameController.text.trim().isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      String imageUrl = "";

      if (selectedImage != null) {
        imageUrl = await uploadToCloudinary(selectedImage!);
      }

      await service.addDocument(
        nameController.text.trim(),
        selectedDate!,
        selectedCategory,
        imageUrl,
      );

      DateTime today = DateTime.now();
      DateTime cleanToday =
      DateTime(today.year, today.month, today.day);

      DateTime cleanSelected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );

      int days = cleanSelected.difference(cleanToday).inDays;

      // 🔥 STEP 2: APPLY EXPIRY LOGIC
      if (hasExpiry(selectedCategory)) {
        if (days >= 0 && days <= 2) {
          await NotificationService.showNotification(
            "Document Alert ⚠️",
            days == 0
                ? "${nameController.text} expires TODAY 🚨"
                : days == 1
                ? "${nameController.text} expires TOMORROW ⏰"
                : "${nameController.text} expires in $days days",
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved successfully ✅")),
      );

      nameController.clear();

      setState(() {
        selectedDate = null;
        selectedCategory = categories[0];
        selectedImage = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🎨 UI (UNCHANGED)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Document")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Document Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? "No date selected"
                        : "Expiry: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                  ),
                ),
                ElevatedButton(
                  onPressed: pickDate,
                  child: const Text("Pick Date"),
                ),
              ],
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: selectedImage == null
                    ? const Center(child: Text("Tap to select image 📸"))
                    : Image.file(selectedImage!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () async {
                if (selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Select image first")),
                  );
                  return;
                }

                String? text =
                await scanTextFromImage(selectedImage!);

                if (text != null) {
                  DateTime? date = extractDate(text);

                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Expiry detected ✅")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No date found")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan Document"),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveDocument,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Document"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}