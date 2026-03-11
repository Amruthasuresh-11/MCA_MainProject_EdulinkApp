import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminComplaintsScreen extends StatelessWidget {
  const AdminComplaintsScreen({super.key});

  static const Color themeBlue = Color(0xFF4A00E0);

  ///  Widget to fetch & show username from UID
  Widget buildUserName(String uid) {
    if (uid.isEmpty) {
      return const Text("Not Available");
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("Loading...");
        }

        if (!snapshot.data!.exists) {
          return const Text("User Not Found");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data["name"] ?? "Unknown User";

        return Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }
  Future<void> deletePost(BuildContext context, String postId) async {

  final postRef =
      FirebaseFirestore.instance.collection("posts").doc(postId);

  final doc = await postRef.get();

  if (!doc.exists) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post already deleted")),
    );

    return;
  }
   ///  Delete likes subcollection
  final likesSnapshot = await postRef.collection("likes").get();

  for (var likeDoc in likesSnapshot.docs) {
    await likeDoc.reference.delete();
  }

  ///  Delete the post
  await postRef.delete();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Post deleted successfully")),
  );
}

Future<void> blockUser(BuildContext context, String uid) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .update({"isBlocked": true});

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("User blocked successfully")),
  );
}

void showConfirmDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text(
            "Confirm",
            style: TextStyle(color: Colors.white),
          ),
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
        title: const Text(
          "User Complaints",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("complaints")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data!.docs;

          if (complaints.isEmpty) {
            return const Center(
              child: Text("No Complaints Found ✅"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {

              final complaintDoc = complaints[index];
              final data = complaintDoc.data() as Map<String, dynamic>;

              final reason = data["reason"] ?? "No Reason";
              final type = data["type"] ?? "Unknown";

              final reportedBy = data["reportedBy"] ?? "";
              final reportedUserId = data["reportedUserId"] ?? "";

              final postId = data["postId"];
              final createdAt = data["createdAt"];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        type == "post" ? themeBlue : Colors.orange,
                    child: Icon(
                      type == "post"
                          ? Icons.article
                          : Icons.chat,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  trailing: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(reportedUserId)
                        .get(),
                    builder: (context, userSnap) {

                      bool isBlocked = false;

                      if (userSnap.hasData && userSnap.data!.exists) {
                        final userData = userSnap.data!.data() as Map<String, dynamic>;
                        isBlocked = userData["isBlocked"] ?? false;
                      }

                      return PopupMenuButton<String>(

                        onSelected: (value) {

                          if (value == "deletePost" && postId != null) {
                            showConfirmDialog(
                              context,
                              "Delete Post?",
                              "Are you sure you want to delete this reported post?",
                              () => deletePost(context, postId),
                            );
                          }

                          if (value == "blockUser") {
                            showConfirmDialog(
                              context,
                              "Block User?",
                              "This user will not be able to login.",
                              () => blockUser(context, reportedUserId),
                            );
                          }

                          if (value == "unblockUser") {
                            showConfirmDialog(
                              context,
                              "Unblock User?",
                              "This user will be allowed to login again.",
                              () async {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(reportedUserId)
                                    .update({"isBlocked": false});
                              },
                            );
                          }

                        },

                        itemBuilder: (context) {

                          if (type == "post") {

                            return [

                              const PopupMenuItem(
                                value: "deletePost",
                                child: Text("Delete Post"),
                              ),

                              PopupMenuItem(
                                value: isBlocked ? "unblockUser" : "blockUser",
                                child: Text(isBlocked ? "Unblock User" : "Block User"),
                              ),

                            ];
                          }

                          return [

                            PopupMenuItem(
                              value: isBlocked ? "unblockUser" : "blockUser",
                              child: Text(isBlocked ? "Unblock User" : "Block User"),
                            ),

                          ];
                        },
                      );
                    },
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 6),

                      Text("Type: ${type.toUpperCase()}"),

                      const SizedBox(height: 4),

                      const Text("Reported By:"),
                      buildUserName(reportedBy),   // ✅ NAME instead of UID

                      const SizedBox(height: 6),

                      const Text("Against User:"),
                      buildUserName(reportedUserId), // ✅ NAME instead of UID

                      if (postId != null)
                        Text("Post ID: $postId"),

                      if (createdAt != null)
                        Text(
                          "Date: ${createdAt.toDate()}",
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),

                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
