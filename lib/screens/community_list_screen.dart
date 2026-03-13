import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_discussion_screen.dart';

class CommunityListScreen extends StatelessWidget {
  const CommunityListScreen({super.key});

  static const Color themeBlue = Color(0xFF4A00E0);

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
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
            child: Text("No communities available"),
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

                leading: const CircleAvatar(
                  backgroundColor: themeBlue,
                  child: Icon(Icons.groups, color: Colors.white),
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
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
