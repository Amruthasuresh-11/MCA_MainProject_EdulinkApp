import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class MentorsScreen extends StatefulWidget {
  const MentorsScreen({super.key});

  @override
  State<MentorsScreen> createState() => _MentorsScreenState();
}

class _MentorsScreenState extends State<MentorsScreen> {
  static const Color themeBlue = Color(0xFF4A00E0);

  String myUniversity = "";
  String myCourse = "";
  String myYear = "";
  String myUid = "";

  bool isLoading = true;
  String searchText = "";

  final Map<String, int> yearRank = const {
    "1st Year": 1,
    "2nd Year": 2,
    "3rd Year": 3,
    "Final Year": 4,
    "Passout": 5,
  };

  @override
  void initState() {
    super.initState();
    loadMyProfile();
  }

  Future<void> loadMyProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    myUid = user.uid;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(myUid).get();

    if (doc.exists) {
      final data = doc.data();

      myUniversity = data?["university"] ?? "";
      myCourse = data?["course"] ?? "";
      myYear = data?["year"] ?? "";
    }

    setState(() => isLoading = false);
  }

  bool isHigherYear(String mentorYear) {
    return (yearRank[mentorYear] ?? 0) > (yearRank[myYear] ?? 0);
  }

  /// ✅ BADGE LOGIC
  String getBadge(double rating) {
    if (rating >= 4.5) return "🥇";
    if (rating >= 3.5) return "🥈";
    if (rating >= 2.5) return "🥉";
    return "";
  }

  /// ✅ AVERAGE RATING
  Future<double> getAverageRating(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("ratings")
        .get();

    if (snapshot.docs.isEmpty) return 0;

    double total = 0;

    for (var doc in snapshot.docs) {
      total += (doc["rating"] ?? 0);
    }

    return total / snapshot.docs.length;
  }

  Future<void> showTopMentorsDialog() async {

  final usersSnapshot =
      await FirebaseFirestore.instance.collection("users").get();

  List<Map<String, dynamic>> gold = [];
  List<Map<String, dynamic>> silver = [];
  List<Map<String, dynamic>> bronze = [];

  for (var doc in usersSnapshot.docs) {

    final rating = await getAverageRating(doc.id);
    final data = doc.data();

    final mentor = {
      "name": data["name"] ?? "Mentor",
      "image": data["profileImageUrl"] ?? "",
      "rating": rating
    };

    if (rating >= 4.5) {
      gold.add(mentor);
    } 
    else if (rating >= 3.5) {
      silver.add(mentor);
    } 
    else if (rating >= 2.5) {
      bronze.add(mentor);
    }
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("🏆 Top Mentors"),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              buildMentorSection("🥇 Gold Mentors", gold),
              buildMentorSection("🥈 Silver Mentors", silver),
              buildMentorSection("🥉 Bronze Mentors", bronze),

            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildMentorSection(String title, List mentors) {

  if (mentors.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const SizedBox(height: 10),

      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      ...mentors.map((m) {

        return ListTile(

          leading: CircleAvatar(
            backgroundImage: m["image"] != ""
                ? NetworkImage(m["image"])
                : null,
            child: m["image"] == ""
                ? const Icon(Icons.person)
                : null,
          ),

          title: Text(m["name"]),

          subtitle: Text("⭐ ${m["rating"].toStringAsFixed(1)}"),

        );

      }).toList(),

    ],
  );
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myUniversity.isEmpty || myCourse.isEmpty || myYear.isEmpty) {
      return const Center(
        child: Text("Please complete your profile to get mentor suggestions."),
      );
    }

    final query = FirebaseFirestore.instance
        .collection("users")
        .where("university", isEqualTo: myUniversity)
        .where("course", isEqualTo: myCourse);

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [

              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search users by name, skill, course or university",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.emoji_events, color: Colors.orange,size: 38,),
                onPressed: showTopMentorsDialog,
              ),

            ],
          ),
        ),
    if (searchText.isNotEmpty)
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.where((doc) {

            final data = doc.data() as Map<String, dynamic>;

            if (doc.id == myUid) return false;

            final name = (data["name"] ?? "").toString().toLowerCase();
            final skills = (data["skills"] ?? "").toString().toLowerCase();
            final course = (data["course"] ?? "").toString().toLowerCase();
            final university = (data["university"] ?? "").toString().toLowerCase();

            return name.contains(searchText) ||
                skills.contains(searchText) ||
                course.contains(searchText) ||
                university.contains(searchText);

          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: users.length,
            itemBuilder: (context, index) {

              final u = users[index].data() as Map<String, dynamic>;
              final imageUrl = u["profileImageUrl"] ?? "";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          userId: users[index].id,
                        ),
                      ),
                    );
                  },

                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: themeBlue,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),

                  title: Text(
                    u["name"] ?? "Student",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    "${u["course"]} • ${u["college"]}",
                  ),

                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            otherUid: users[index].id,
                            otherName: u["name"] ?? "Student",
                          ),
                        ),
                      );
                    },
                    child: const Text("Chat",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
   if (searchText.isEmpty)
    Expanded( 
     child: StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final mentors = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (data["uid"] == myUid) return false;
          if (!isHigherYear(data["year"])) return false;

          return true;
        }).toList();

        if (mentors.isEmpty) {
          return const Center(child: Text("No mentors found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: mentors.length,
          itemBuilder: (context, index) {
            final m = mentors[index].data() as Map<String, dynamic>;
            final imageUrl = m["profileImageUrl"] ?? "";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          userId: mentors[index].id,
                        ),
                      ),
                    );
                  },
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: themeBlue,
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                /// ✅ NAME + BADGE (UPDATED)
                title: FutureBuilder<double>(
                  future: getAverageRating(mentors[index].id),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return Text(m["name"] ?? "Mentor");
                    }

                    final rating = snapshot.data!;
                    final badge = getBadge(rating);

                    return Row(
                      children: [
                        Text(
                          m["name"] ?? "Mentor",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(badge),
                        ]
                      ],
                    );
                  },
                ),

                subtitle: Text(
                    "${m["year"]} • ${m["college"]}\nSkills: ${m["skills"]}"),
                isThreeLine: true,

                trailing: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: themeBlue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          otherUid: mentors[index].id,
                          otherName: m["name"] ?? "Mentor",
                        ),
                      ),
                    );
                  },
                  child: const Text("Chat",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
     ),
    ),
    ],    
    );
  }
}
