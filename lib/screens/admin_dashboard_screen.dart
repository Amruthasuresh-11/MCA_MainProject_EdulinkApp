import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color themeBlue = Color(0xFF4A00E0);

  Future<void> toggleBlock(BuildContext context, String uid, bool isBlocked) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "isBlocked": !isBlocked,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isBlocked ? "Student Blocked 🚫" : "Student Unblocked ✅",
        ),
      ),
    );
  }

  void showConfirmDialog(
      BuildContext context, String uid, bool isBlocked) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isBlocked ? "Unblock Student?" : "Block Student?",
        ),
        content: Text(
          isBlocked
              ? "This student will be allowed to login."
              : "This student will NOT be able to login.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
            onPressed: () async {
              Navigator.pop(context);
              await toggleBlock(context, uid, isBlocked);
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
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),

        actions: [
          IconButton(
              icon: const Icon(Icons.report, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/complaints');
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),


      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No Students Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final data = userDoc.data() as Map<String, dynamic>;
              final imageUrl = data["profileImageUrl"] ?? "";

              final bool isBlocked = data["isBlocked"] ?? false;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: themeBlue,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),

                  title: Text(data["name"] ?? "Student"),

                  subtitle: Text(
                    "${data["college"] ?? ""}\n${data["course"] ?? ""}",
                  ),

                  isThreeLine: true,

                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBlocked ? Colors.red : themeBlue,
                    ),
                    onPressed: () {
                      showConfirmDialog(
                        context,
                        userDoc.id,
                        isBlocked,
                      );
                    },
                    child: Text(
                      isBlocked ? "Blocked" : "Active",
                      style: const TextStyle(color: Colors.white),
                    ),
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
