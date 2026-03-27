import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowListScreen extends StatelessWidget {
  final String userId;
  final bool isFollowers; // true = followers, false = following

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      ///  APP BAR (THEME BLUE)
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A00E0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isFollowers ? "Followers" : "Following",
          style: const TextStyle(color: Colors.white),
        ),
      ),

      ///  REALTIME LIST
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection(isFollowers ? "followers" : "following")
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isFollowers ? "No Followers Yet" : "Not Following Anyone",
                style: const TextStyle(fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final uid = docs[index].id;

              ///  FETCH USER DETAILS
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .get(),

                builder: (context, userSnapshot) {

                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final data =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),

                    child: Row(
                      children: [

                        ///  PROFILE IMAGE
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (data["profileImageUrl"] != null &&
                                  data["profileImageUrl"] != "")
                              ? NetworkImage(data["profileImageUrl"])
                              : null,
                          child: (data["profileImageUrl"] == null ||
                                  data["profileImageUrl"] == "")
                              ? const Icon(Icons.person)
                              : null,
                        ),

                        const SizedBox(width: 12),

                        ///  USER DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                data["name"] ?? "No Name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                data["college"] ?? "",
                                style: const TextStyle(fontSize: 12,
                                  color: Colors.black,),
                              ),

                              Text(
                                data["course"] ?? "",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}