import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'notes_screen.dart';
import 'upload_note_screen.dart';
import 'chat_detail_screen.dart';
import 'certificate_generator.dart';

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {

  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    await likeRef.delete();
  } else {
    await likeRef.set({
      "liked": true,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}

void showEditPostDialog(String postId, String oldTitle, String oldDesc) {

  final titleController = TextEditingController(text: oldTitle);
  final descController = TextEditingController(text: oldDesc);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Post"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Title"),
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
          onPressed: () async {

            await FirebaseFirestore.instance
                .collection("posts")
                .doc(postId)
                .update({
              "title": titleController.text.trim(),
              "desc": descController.text.trim(),
            });

            Navigator.pop(context);

          },
          child: const Text("Update"),
        ),

      ],
    ),
  );
}

  File? selectedImage;
  String profileImageUrl = "";

  String name = "";
  String university = "";
  String college = "";
  String course = "";
  String year = "";
  String skills = "";

  bool isLoading = true;
  String myUid = "";
  bool isOwner = false;

  int postCount = 0;
  int notesCount = 0;

  Future<void> fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // if userId is passed → open that profile
    // otherwise open current user's profile
    myUid = widget.userId ?? currentUser.uid;
    isOwner = myUid == currentUser.uid;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(myUid).get();
        if(!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;

      postCount = await getPostCount();
      notesCount = await getNotesCount();

      setState(() {
        name = data["name"] ?? "";
        university = data["university"] ?? "";
        college = data["college"] ?? "";
        course = data["course"] ?? "";
        year = data["year"] ?? "";
        skills = data["skills"] ?? "";
        profileImageUrl = data["profileImageUrl"] ?? "";
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
  final picker = ImagePicker();

  final pickedFile =
      await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    setState(() {
      selectedImage = File(pickedFile.path);
    });

    uploadToCloudinary();
  }
}

Future<void> uploadToCloudinary() async {

  if (selectedImage == null) return;

  var uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/dniawqazl/image/upload");

  var request = http.MultipartRequest("POST", uri);

  request.fields['upload_preset'] = 'edulink_upload';

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      selectedImage!.path,
    ),
  );

  var response = await request.send();

  if (response.statusCode == 200) {

    var responseData =
        json.decode(await response.stream.bytesToString());

    String imageUrl = responseData['secure_url'];

    await FirebaseFirestore.instance
        .collection("users")
        .doc(myUid)
        .update({
      "profileImageUrl": imageUrl
    });

    setState(() {
      profileImageUrl = imageUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile picture updated")),
    );

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image upload failed")),
    );

  }
}

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String showValue(String value) =>
      value.trim().isEmpty ? "Not added yet" : value;
  //Badge Logic
  String getBadge(double rating) {
  if (rating >= 4.5) return "🥇";
  if (rating >= 3.5) return "🥈";
  if (rating >= 2.5) return "🥉";
  return "";
  }
  //Average Rating
  Future<double> getAverageRating() async {
  final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(myUid)
      .collection("ratings")
      .get();

  if (snapshot.docs.isEmpty) return 0;

  double total = 0;

  for (var doc in snapshot.docs) {
    total += (doc["rating"] ?? 0);
  }

  return total / snapshot.docs.length;
}
//post count function
Future<int> getPostCount() async {

  final snapshot = await FirebaseFirestore.instance
      .collection("posts")
      .where("uid", isEqualTo: myUid)
      .get();

  return snapshot.docs.length;

}
// Notes count function
Future<int> getNotesCount() async {

  final snapshot = await FirebaseFirestore.instance
      .collection("notes")
      .where("userId", isEqualTo: myUid)
      .get();

  return snapshot.docs.length;

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isOwner && widget.userId == null
       ? null
       : AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title:  Text(
          name,
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: isOwner ? 47 : 0),
                         child:GestureDetector(
                            onTap: isOwner ? pickImage : null,
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             if (isOwner)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: themeBlue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfileScreen(),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() => isLoading = true);
                                        fetchUserData();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_box_outlined,
                                        color: themeBlue),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddPostDialog(),
                                      );
                                      fetchUserData();
                                    },
                                  ),
                                  IconButton(
                                     icon: const Icon(Icons.upload_file,
                                     color: themeBlue,),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const UploadNoteScreen(),
                                        ),
                                      );
                                      fetchUserData();
                                    },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.logout,
                                        color: Colors.red),
                                    onPressed: logout,
                                  ),
                                ],
                              ),
                              
                              FutureBuilder<double>(
                                future: getAverageRating(),
                                builder: (context, snapshot) {

                                  final rating = snapshot.data ?? 0;
                                  final badge = getBadge(rating);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          if (badge.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              badge,
                                              style: const TextStyle(fontSize: 22),
                                            ),
                                          ]
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [

                                          Column(
                                            children: [
                                              Text(
                                                postCount.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Text("Posts"),
                                            ],
                                          ),

                                          Column(
                                            children: [
                                              Text(
                                                notesCount.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Text("Notes"),
                                            ],
                                          ),

                                       if (rating > 0)
                                          Column(
                                            children: [
                                              Text(
                                                "⭐ ${rating.toStringAsFixed(1)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Text("Rating"),
                                            ],
                                          ),

                                          if (badge.isNotEmpty && isOwner)
                                            GestureDetector(
                                              onTap: () {

                                                String badgeName = "Bronze";

                                                if (badge == "🥇") {
                                                  badgeName = "Gold";
                                                } else if (badge == "🥈") {
                                                  badgeName = "Silver";
                                                }

                                                generateCertificate(name, badgeName);
                                              },
                                              child: Column(
                                                children: const [
                                                  Icon(Icons.workspace_premium, color: Colors.orange),
                                                  Text("Certificate"),
                                                ],
                                              ),
                                            ),

                                        ],
                                      ),
                                     
                                    ],
                                  );
                                },
                              ),
                              Text("University : ${showValue(university)}"),
                              Text("College : ${showValue(college)}"),
                              Text("Course : ${showValue(course)}"),
                              Text("Year : ${showValue(year)}"),
                              Text("Skills : ${showValue(skills)}"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                                    onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NotesScreen(
                                              userId: myUid,
                                              isOwner: isOwner,
                                            ),
                                          ),
                                        );
                                    },
                                    child: const Text(" View Notes",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
                                  ),
                                ),

                                if (!isOwner) ...[
                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: themeBlue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatDetailScreen(
                                              otherUid: myUid,
                                              otherName: name,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Message",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),


                    const SizedBox(height: 20),
                    const Text(" My Posts",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // ✅ MY POSTS
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("posts")
                          .where("uid", isEqualTo: myUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final posts = snapshot.data!.docs.toList();

                        posts.sort((a, b) {
                          final t1 = a["createdAt"] as Timestamp?;
                          final t2 = b["createdAt"] as Timestamp?;

                          if (t1 == null || t2 == null) return 0;

                          return t2.compareTo(t1); // newest first
                        });

                        if (posts.isEmpty) {
                          return const Center(child: Text("No posts yet"));
                        }

                        return Column(
                          children: posts.map((doc) {
                            final post = doc.data() as Map<String, dynamic>;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  /// HEADER ROW
                                  Row(
                                    children: [

                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: profileImageUrl.isNotEmpty
                                            ? NetworkImage(profileImageUrl)
                                            : null,
                                        child: profileImageUrl.isEmpty
                                            ? const Icon(Icons.person, size: 18)
                                            : null,
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
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

                                      if (post["createdAt"] != null)
                                        Text(
                                          DateFormat('d MMM yyyy')
                                              .format((post["createdAt"] as Timestamp).toDate()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      /// 3 DOT MENU
                                    if (isOwner)
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == "edit") {

                                            showEditPostDialog(
                                              doc.id,
                                              post["title"] ?? "",
                                              post["desc"] ?? "",
                                            );

                                          }

                                          if (value == "delete") {

                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text("Delete Post"),
                                                content: const Text(
                                                    "Are you sure you want to delete this post?"),
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

                                                      await FirebaseFirestore.instance
                                                          .collection("posts")
                                                          .doc(doc.id)
                                                          .delete();

                                                      Navigator.pop(context);
                                                      fetchUserData();
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
                                            value: "edit",
                                            child: Text("Edit"),
                                          ),
                                          PopupMenuItem(
                                            value: "delete",
                                            child: Text("Delete"),
                                          )
                                        ],
                                      ),

                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  /// TITLE
                                  Text(
                                    post["title"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  /// DESCRIPTION
                                  Text(
                                    post["desc"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  /// IMAGE
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

                                        final isLiked = likeDocs.any((d) => d.id == myUid);

                                        return Row(
                                          children: [

                                            GestureDetector(
                                              onTap: () => toggleLike(doc.id),
                                              child: Icon(
                                                Icons.thumb_up,
                                                color: isLiked ? themeBlue : Colors.grey,
                                                size: 22,
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            Text(
                                              "$likeCount Likes",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),

                                          ],
                                        );
                                      },
                                    ),

                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

// ================= ADD POST DIALOG =================

class AddPostDialog extends StatefulWidget {
  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {

  final titleController = TextEditingController();
  final descController = TextEditingController();

  File? selectedImage;
  String imageUrl = "";
  bool isPicking = false;

  /// PICK IMAGE
  Future<void> pickImage() async {

  if (isPicking) return;   // prevent multiple picker calls

  isPicking = true;

  final picker = ImagePicker();

  final pickedFile =
      await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    setState(() {
      selectedImage = File(pickedFile.path);
    });

    await uploadImage();
  }

  isPicking = false;
}
  /// UPLOAD IMAGE TO CLOUDINARY
  Future<void> uploadImage() async {

    if (selectedImage == null) return;

    var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dniawqazl/image/upload");

    var request = http.MultipartRequest("POST", uri);

    request.fields['upload_preset'] = 'edulink_upload';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedImage!.path,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {

      var responseData =
          json.decode(await response.stream.bytesToString());

      setState(() {
        imageUrl = responseData['secure_url'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded")),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed")),
      );

    }
  }

  /// SAVE POST
  Future<void> savePost() async {

    if (titleController.text.trim().isEmpty ||
    descController.text.trim().isEmpty ||
    imageUrl.isEmpty) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please add image, title and description"),
    ),
  );

  return;
}

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    await FirebaseFirestore.instance.collection("posts").add({

      "uid": user.uid,
      "name": userDoc["name"],
      "college": userDoc["college"],

      "title": titleController.text.trim(),
      "desc": descController.text.trim(),

      "imageUrl": imageUrl,   // NEW FIELD

      "createdAt": FieldValue.serverTimestamp(),

    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text("Create Post"),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// IMAGE PREVIEW
            if (selectedImage != null)
              Image.file(
                selectedImage!,
                height: 120,
              ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: isPicking ? null : pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Select Image"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

          ],
        ),
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: savePost,
          child: const Text("Post"),
        )

      ],
    );
  }
}