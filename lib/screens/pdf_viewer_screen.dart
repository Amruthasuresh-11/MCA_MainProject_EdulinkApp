import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;

  const PdfViewerScreen({super.key, required this.url});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {

  String? localPath;

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  Future<void> downloadFile() async {

    var dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}/temp.pdf";

    await Dio().download(widget.url, path);

    setState(() {
      localPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A00E0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("View PDF",
        style: TextStyle(color: Colors.white),
        ),
      ),

      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localPath!,
            ),
    );
  }
}