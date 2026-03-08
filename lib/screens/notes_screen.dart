import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatelessWidget {
  final String userId;
  final bool isOwner;

  const NotesScreen({
    super.key,
    required this.userId,
    required this.isOwner,
  });

  static const Color themeBlue = Color(0xFF4A00E0);

  /// Open PDF (View)
 Future<void> openFile(String url) async {
  final uri = Uri.parse(url);

  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}

  /// Delete note
  Future<void> deleteNote(String docId) async {
    await FirebaseFirestore.instance
        .collection("notes")
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Notes",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body:Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE7F6),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection("notes")
          .where("userId", isEqualTo: userId)
          .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

          final notes = snapshot.data?.docs.toList() ?? [];

            notes.sort((a, b) {
              final t1 = a["createdAt"] as Timestamp?;
              final t2 = b["createdAt"] as Timestamp?;

              if (t1 == null || t2 == null) return 0;

              return t2.compareTo(t1); // newest first
            });
            
          if (notes.isEmpty) {
            return const Center(
              child: Text("No notes uploaded yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: notes.length,
            itemBuilder: (context, index) {

              final doc = notes[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data["title"] ?? "Untitled";
              final topic = data["topic"] ?? "";
              final description = data["description"] ?? "";
              final url = data["fileUrl"] ?? "";
              final createdAt = data["createdAt"];

              return Card(
                color: const Color(0xFFD1C4E9),
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(10),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: const [
                          Icon(Icons.picture_as_pdf,
                              color: themeBlue),
                          SizedBox(width: 6),
                          Text(
                            "Study Notes",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text("Topic: $topic"),

                      const SizedBox(height: 4),

                      Text("Description: $description"),

                      const SizedBox(height: 4),

                      if (createdAt != null)
                        Text(
                          "Date: ${DateFormat('dd MMM yyyy').format(createdAt.toDate())}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 6),

                      Row(
                        children: [

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeBlue,
                            ),
                           onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(url: url),
                                ),
                              );
                            },
                              child: const Text(
                              "View",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeBlue,
                            ),
                            onPressed: () {
                              openFile(url);
                            },
                            child: const Text(
                              "Download",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (isOwner)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Delete Note"),
                                      content: const Text(
                                        "Are you sure you want to delete this note?"
                                      ),
                                      actions: [

                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Cancel"),
                                        ),

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await deleteNote(doc.id);
                                            Navigator.pop(context);

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Note deleted successfully"),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}