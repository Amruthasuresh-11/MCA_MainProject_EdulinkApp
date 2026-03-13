import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityDiscussionScreen extends StatefulWidget {

  final String communityId;
  final String communityName;

  const CommunityDiscussionScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityDiscussionScreen> createState() =>
      _CommunityDiscussionScreenState();
}

class _CommunityDiscussionScreenState extends State<CommunityDiscussionScreen> {

  static const Color themeBlue = Color(0xFF4A00E0);

  final TextEditingController messageController = TextEditingController();

  String myUid = "";
  String myName = "";
  bool isAdmin = false;

  /// LOAD USER DATA
  Future<void> loadUser() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    myUid = user.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(myUid)
        .get();

    final data = doc.data();

    myName = data?["name"] ?? "User";

    if (user.email == "admin@gmail.com") {
      isAdmin = true;
      myName = "Admin";
    }

    setState(() {});
  }

  /// SEND MESSAGE
  Future<void> sendMessage() async {

    if (messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("communities")
        .doc(widget.communityId)
        .collection("communitymessages")
        .add({

      "senderId": myUid,
      "senderName": myName,
      "message": messageController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),

    });
    await FirebaseFirestore.instance
    .collection("communities")
    .doc(widget.communityId)
    .update({
  "lastMessageTime": FieldValue.serverTimestamp(),
});

    messageController.clear();
  }

  /// DELETE MESSAGE (ADMIN ONLY)
  Future<void> deleteMessage(String messageId) async {

    await FirebaseFirestore.instance
        .collection("communities")
        .doc(widget.communityId)
        .collection("communitymessages")
        .doc(messageId)
        .delete();
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.communityName,
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [

          /// MESSAGE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("communities")
                  .doc(widget.communityId)
                  .collection("communitymessages")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text("No messages yet"),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,

                  itemBuilder: (context, index) {

                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final sender = data["senderName"] ?? "";
                    final message = data["message"] ?? "";
                    final isMe = data["senderId"] == myUid;

                    return Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [

                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 260,
                            ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe ? themeBlue : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [

                                    Text(
                                      sender,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isMe ? Colors.white : Colors.black,
                                      ),
                                    ),

                                    if (isAdmin)
                                      PopupMenuButton<String>(
                                        iconColor: isMe ? Colors.white : Colors.black,
                                        onSelected: (value) {

                                          if (value == "delete") {

                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text("Delete Message"),
                                                content: const Text(
                                                  "Are you sure you want to delete this message?",
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
                                                      deleteMessage(doc.id);

                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  )

                                                ],
                                              ),
                                            );

                                          }

                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: "delete",
                                            child: Text("Delete Message"),
                                          )
                                        ],
                                      ),

                                  ],
                                ),

                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          ),
                        ),

                      ],
                    );
                  },
                );
              },
            ),
          ),

          /// MESSAGE INPUT
          Container(
            padding: const EdgeInsets.all(10),

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.send, color: themeBlue),
                  onPressed: sendMessage,
                )

              ],
            ),
          )

        ],
      ),
    );
  }
}