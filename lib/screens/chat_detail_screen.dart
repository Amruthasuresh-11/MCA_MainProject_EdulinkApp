import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;

  const ChatDetailScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();

  int selectedRating = 0;

  String myUid = FirebaseAuth.instance.currentUser!.uid;

  String getChatId() {
    return myUid.hashCode <= widget.otherUid.hashCode
        ? "$myUid-${widget.otherUid}"
        : "${widget.otherUid}-$myUid";
  }

  Future<double> getAverageRating() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.otherUid)
        .collection("ratings")
        .get();

    if (snapshot.docs.isEmpty) return 0;

    double total = 0;

    for (var doc in snapshot.docs) {
      total += (doc["rating"] ?? 0);
    }

    return total / snapshot.docs.length;
  }

  Future<void> submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select rating ⭐")),
      );
      return;
    }

    final ratingRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.otherUid)
        .collection("ratings")
        .doc(myUid);

    await ratingRef.set({
      "rating": selectedRating,
      "ratedBy": myUid,
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rating Submitted ⭐")),
    );
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final chatId = getChatId();
    final msgText = messageController.text.trim();

    final chatRef =
        FirebaseFirestore.instance.collection("chats").doc(chatId);

    await chatRef.collection("messages").add({
      "senderId": myUid,
      "text": msgText,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      "users": [myUid, widget.otherUid],
      "lastMessage": msgText,
      "lastMessageTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    messageController.clear();
  }

  /// REPORT DIALOG 
void showReportDialog() {
  String selectedReason = "";

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Report Chat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text("Not Educational"),
                value: "Not Educational",
                groupValue: selectedReason,
                onChanged: (value) {
                  setStateDialog(() => selectedReason = value!);
                },
              ),
              RadioListTile(
                title: const Text("Inappropriate Behaviour"),
                value: "Inappropriate Behaviour",
                groupValue: selectedReason,
                onChanged: (value) {
                  setStateDialog(() => selectedReason = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason.isEmpty) return;

                await FirebaseFirestore.instance.collection("complaints").add({
                  "type": "chat",
                  "reportedBy": myUid,
                  "reportedUserId": widget.otherUid,
                  "reason": selectedReason,
                  "createdAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Complaint Submitted")),
                );
              },
              child: const Text("Submit"),
            )
          ],
        );
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A00E0),
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(
          widget.otherName,
          style: const TextStyle(color: Colors.white),
        ),

        actions: [
          ///  3 DOT MENU
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ListTile(
                      leading: const Icon(Icons.report, color: Colors.red),
                      title: const Text("Report"),
                      onTap: () {
                        Navigator.pop(context);
                        showReportDialog();
                      },
                    );
                  },
                );
              },
            ),

          /// ⭐ STAR BUTTON
          IconButton(
            icon: const Icon(Icons.star, color: Colors.white),
            onPressed: () {
              selectedRating = 0;
              showDialog(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return AlertDialog(
                      title: const Text("Rate Student"),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;

                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color: selectedRating >= starIndex
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                selectedRating = starIndex;
                              });
                            },
                          );
                        }),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            await submitRating();
                            Navigator.pop(context);
                            setState(() {}); // refresh rating
                          },
                          child: const Text("Submit"),
                        )
                      ],
                    );
                  },
                ),
              );
            },
          ),

          /// ⭐ AVERAGE RATING DISPLAY (SECOND)
          FutureBuilder<double>(
            future: getAverageRating(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) return const SizedBox();

              final avg = snapshot.data!;

              if (avg == 0) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(right: 16,left: 4),
                child: Center(
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("createdAt",descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == myUid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF4A00E0)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["text"],
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xFF4A00E0)),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
