import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color themeBlue = Color(0xFF4A00E0);

  final TextEditingController collegeController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = true;

  final List<String> universityList = const [
    "Mahatma Gandhi University",
    "Calicut University",
    "Kerala University",
    "KTU University"
  ];

  final List<String> courseList = const [
    "BCA",
    "MCA",
    "BSc Computer Science",
    "MSc Computer Science",
  ];

  final List<String> yearList = const [
    "1st Year",
    "2nd Year",
    "3rd Year",
    "Final Year",
    "Passout",
  ];

  String selectedUniversity = "Mahatma Gandhi University";
  String selectedCourse = "BCA";
  String selectedYear = "1st Year";

  @override
  void initState() {
    super.initState();
    loadExistingData();
  }

  Future<void> loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data();

      collegeController.text = data?["college"] ?? "";
      skillsController.text = data?["skills"] ?? "";

      if (universityList.contains(data?["university"])) {
        selectedUniversity = data?["university"];
      }

      if (courseList.contains(data?["course"])) {
        selectedCourse = data?["course"];
      }

      if (yearList.contains(data?["year"])) {
        selectedYear = data?["year"];
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "university": selectedUniversity,
      "course": selectedCourse,
      "college": collegeController.text.trim(),
      "skills": skillsController.text.trim(),
      "year": selectedYear,
    });

    Navigator.pop(context, true);
  }

  Widget dropdown(String label, IconData icon, String value, List<String> list,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items:
            list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget field(String label, TextEditingController c, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        validator: (v) => v!.isEmpty ? "$label required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    dropdown("University", Icons.school, selectedUniversity,
                        universityList,
                        (v) => setState(() => selectedUniversity = v!)),

                    dropdown("Course", Icons.book, selectedCourse, courseList,
                        (v) => setState(() => selectedCourse = v!)),

                    field("College", collegeController, Icons.apartment),

                    dropdown("Year", Icons.calendar_month, selectedYear, yearList,
                        (v) => setState(() => selectedYear = v!)),

                    field("Skills", skillsController, Icons.lightbulb_outline),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                        ),
                        child: const Text("Save Changes",
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
