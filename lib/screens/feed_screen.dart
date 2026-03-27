import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Color themeBlue = Color(0xFF4A00E0);

  Future<void> toggleLike(String postId) async {

  final uid = FirebaseAuth.instance.currentUser!.uid;

  final likeRef = FirebaseFirestore.instance
      .collection("posts")
      .doc(postId)
      .collection("likes")
      .doc(uid);

  final doc = await likeRef.get();

  if (doc.exists) {
    // unlike
    await likeRef.delete();
  } else {
    // like
    await likeRef.set({
      "liked": true,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
Future<List<String>> getFollowingIds() async {
  final myUid = FirebaseAuth.instance.currentUser!.uid;

  final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(myUid)
      .collection("following")
      .get();

  return snapshot.docs.map((doc) => doc.id).toList();
}

  // 🔹 Time ago function
  String timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final diff = now.difference(postTime);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  }

  // ✅ REPORT DIALOG
  void showReportDialog(String postId, String postOwnerUid) {
    String selectedReason = "Not Educational";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Report Post 🚩"),
        content: DropdownButtonFormField<String>(
          value: selectedReason,
          items: const [
            DropdownMenuItem(
                value: "Not Educational", child: Text("Not Educational")),
            DropdownMenuItem(value: "Spam", child: Text("Spam")),
            DropdownMenuItem(value: "Inappropriate", child: Text("Inappropriate")),
          ],
          onChanged: (value) {
            selectedReason = value!;
          },
          decoration: const InputDecoration(labelText: "Select Reason"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
            onPressed: () async {
              final myUid = FirebaseAuth.instance.currentUser!.uid;

              await FirebaseFirestore.instance.collection("complaints").add({
                "type": "post",
                "postId": postId,
                "reportedUserId": postOwnerUid,
                "reportedBy": myUid,
                "reason": selectedReason,
                "createdAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Complaint Submitted ✅")),
              );
            },
            child: const Text("Submit",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("posts")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text("No posts yet"));
        }

      return FutureBuilder<List<String>>(
      future: getFollowingIds(),
      builder: (context, followSnapshot) {

        if (!followSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final followingIds = followSnapshot.data!;

        //  Separate posts
        final followedPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return followingIds.contains(data["uid"]);
        }).toList();

        final otherPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !followingIds.contains(data["uid"]);
        }).toList();

        // Merge
        final sortedPosts = [...followedPosts, ...otherPosts];

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: sortedPosts.length,
          itemBuilder: (context, index) {

            final doc = sortedPosts[index];
            final post = doc.data() as Map<String, dynamic>;
            final uid = post["uid"];
            final myUid = FirebaseAuth.instance.currentUser!.uid;

            final name = post["name"] ?? "Student";
            final college = post["college"] ?? "";
            final title = post["title"] ?? "";
            final desc = post["desc"] ?? "";
            final createdAt = post["createdAt"] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  //  Header row (UPDATED)
                  Row(
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(uid)
                            .get(),
                        builder: (context, userSnapshot) {

                          if (!userSnapshot.hasData) {
                            return const CircleAvatar(
                              radius: 22,
                              backgroundColor: themeBlue,
                              child: Icon(Icons.person, color: Colors.white),
                            );
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>?;

                          final imageUrl = userData?["profileImageUrl"] ?? "";
                           
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: uid),
                                ),
                              );
                            },
                          child:CircleAvatar(
                            radius: 22,
                            backgroundColor: themeBlue,
                            backgroundImage:
                                imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          )
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(userId: uid),
                                  ),
                                );
                              },
                            child:Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            ),
                            Text(
                              college,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (createdAt != null)
                        Text(
                          timeAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black),
                        ),

                      //  3 DOT MENU
                    if (uid != myUid)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "report") {
                            showReportDialog(doc.id, post["uid"]);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "report",
                            child: Text("Report 🚩"),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    desc,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87),
                  ),

                  const SizedBox(height: 12),

                  if (post["imageUrl"] != null && post["imageUrl"] != "")
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post["imageUrl"],                        
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),

                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("posts")
                        .doc(doc.id)
                        .collection("likes")
                        .snapshots(),
                    builder: (context, likeSnapshot) {

                      if (!likeSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final likeDocs = likeSnapshot.data!.docs;

                      final likeCount = likeDocs.length;

                      final myUid = FirebaseAuth.instance.currentUser!.uid;

                      final isLiked =
                          likeDocs.any((d) => d.id == myUid);

                      return Row(
                        children: [

                          GestureDetector(
                            onTap: () => toggleLike(doc.id),
                            child: Icon(
                              Icons.thumb_up,
                              color: isLiked ? themeBlue: Colors.grey,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            "$likeCount Likes",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              ),
                          ),
                        ],
                      );
                    },
                  ),

                  if (uid != myUid)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                otherUid: uid,
                                otherName: name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                        label: const Text(
                          "Message",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
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
