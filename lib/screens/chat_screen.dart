import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  // 🔹 Time ago function (same logic as Feed)
  String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "";

    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("users", arrayContains: myUid)
          .snapshots(), // ✅ NO orderBy → NO index
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No chats yet"));
        }

        // 🔹 Convert docs to list
        final chats = snapshot.data!.docs.toList();

        // 🔹 SORT by lastMessageTime (latest first)
        chats.sort((a, b) {
          final t1 = a["lastMessageTime"] as Timestamp?;
          final t2 = b["lastMessageTime"] as Timestamp?;

          if (t1 == null && t2 == null) return 0;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1); // latest first
        });

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;

            final List users = chat["users"];
            final String otherUid =
                users.firstWhere((uid) => uid != myUid);

            final String lastMessage = chat["lastMessage"] ?? "";
            final Timestamp? lastTime = chat["lastMessageTime"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const SizedBox();
                }

                final user =
                    userSnap.data!.data() as Map<String, dynamic>;
                final imageUrl = user["profileImageUrl"] ?? "";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                   leading: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              userId: otherUid,
                            ),
                          ),
                        );
                      },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF4A00E0),
                      backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                   ),
                    title: Text(
                      user["name"] ?? "Student",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: Text(
                      timeAgo(lastTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            otherUid: otherUid,
                            otherName: user["name"] ?? "Student",
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
