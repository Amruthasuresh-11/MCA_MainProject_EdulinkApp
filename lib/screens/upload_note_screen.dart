import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadNoteScreen extends StatefulWidget {
  const UploadNoteScreen({super.key});

  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {

  static const Color themeBlue = Color(0xFF4A00E0);

  final TextEditingController titleController = TextEditingController();
  final TextEditingController topicController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  PlatformFile? selectedFile;

  /// Pick PDF file
  Future<void> pickFile() async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  /// Upload button 
  Future<void> uploadNote() async {

  if (titleController.text.isEmpty ||
      topicController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      selectedFile == null) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields and select PDF")),
    );
    return;
  }

  try {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading PDF...")),
    );

    /// Cloudinary upload URL
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/dniawqazl/raw/upload",
    );

    /// Upload request
    var request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = 'edulink_upload';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedFile!.path!,
      ),
    );

    /// Send request
    var response = await request.send();

    var responseData = await response.stream.bytesToString();

    var jsonData = json.decode(responseData);

    String fileUrl = jsonData["secure_url"];

    /// Get current user
    final user = FirebaseAuth.instance.currentUser;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    String userName = userDoc["name"];

    /// Save note in Firestore
    await FirebaseFirestore.instance.collection("notes").add({

      "title": titleController.text.trim(),
      "topic": topicController.text.trim(),
      "description": descriptionController.text.trim(),
      "fileUrl": fileUrl,

      "userId": user.uid,
      "userName": userName,

      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note Uploaded Successfully ✅")),
    );

    Navigator.pop(context);

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
    );
  }
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Upload Notes",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: "Topic",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeBlue,
              ),
              onPressed: pickFile,
              icon: const Icon(Icons.attach_file,color: Colors.white),
              label: const Text(
                "Select PDF",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            if (selectedFile != null)
              Text(selectedFile!.name),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                ),
                onPressed: uploadNote,
                child: const Text(
                  "Upload",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}