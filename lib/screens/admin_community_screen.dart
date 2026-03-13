import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_discussion_screen.dart';

class AdminCommunityScreen extends StatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  State<AdminCommunityScreen> createState() => _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends State<AdminCommunityScreen> {

  static const Color themeBlue = Color(0xFF4A00E0);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  /// CREATE COMMUNITY
  Future<void> createCommunity() async {

    if (nameController.text.trim().isEmpty ||
        descController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );

      return;
    }
    await FirebaseFirestore.instance.collection("communities").add({
      "name": nameController.text.trim(),
      "description": descController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    nameController.clear();
    descController.clear();

    Navigator.pop(context);
  }

  /// DELETE COMMUNITY
  Future<void> deleteCommunity(String id) async {

  final communityRef =
      FirebaseFirestore.instance.collection("communities").doc(id);

  /// Delete all community messages first
  final messagesSnapshot =
      await communityRef.collection("communitymessages").get();

  for (var doc in messagesSnapshot.docs) {
    await doc.reference.delete();
  }

  /// Now delete the community document
  await communityRef.delete();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Community deleted successfully")),
  );
}

  /// CREATE COMMUNITY DIALOG
  void showCreateDialog() {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(

        title: const Text("Create Community"),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Community Name"),
            ),

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

          ],
        ),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: createCommunity,
            child: const Text("Create"),
          )

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Community Management",
          style: TextStyle(color: Colors.white),
        ),
      ),

      /// CREATE BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeBlue,
        onPressed: showCreateDialog,
        child: const Icon(Icons.add,color: Colors.white,),
      ),

      /// COMMUNITY LIST
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("communities")
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final communities = snapshot.data!.docs;

          if (communities.isEmpty) {
            return const Center(
              child: Text("No communities yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: communities.length,

            itemBuilder: (context, index) {

              final doc = communities[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                color: const Color(0xFFF0E6FF), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityDiscussionScreen(
                          communityId: doc.id,
                          communityName: data["name"] ?? "",
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: themeBlue,
                    child: const Icon(Icons.groups, color: Colors.white),
                  ),

                  title: Text(
                    data["name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    ),

                  subtitle: Text(
                    data["description"] ?? "",
                    style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),

                  trailing: PopupMenuButton<String>(

                    onSelected: (value) {

                      if (value == "delete") {

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(

                            title: const Text("Delete Community"),

                            content: const Text(
                              "Are you sure you want to delete this community?",
                            ),

                            actions: [

                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {

                                  Navigator.pop(context);
                                  deleteCommunity(doc.id);

                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),

                            ],
                          ),
                        );
                      }
                    },

                    itemBuilder: (context) => const [

                      PopupMenuItem(
                        value: "delete",
                        child: Text("Delete Community"),
                      ),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}