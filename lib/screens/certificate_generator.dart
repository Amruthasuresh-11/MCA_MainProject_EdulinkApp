import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

Future<void> generateCertificate(String name, String badge) async {

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(25),

      build: (pw.Context context) {

        return pw.Container(

          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.orange,
              width: 6,
            ),
          ),

          padding: const pw.EdgeInsets.all(30),

          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,

            children: [

              /// HEADER (🎓 EduLink)
              pw.Text(
                "EduLink",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Text(
                "Inter-College Academic Resources Sharing\nand Peer Mentorship Platform",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),

              pw.SizedBox(height: 25),

              /// CERTIFICATE TITLE
              pw.Text(
                "CERTIFICATE OF RECOGNITION",
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                "This certificate is proudly awarded to",
                style: pw.TextStyle(
                  fontSize: 16,
                ),
              ),

              pw.SizedBox(height: 15),

              /// NAME
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                "For outstanding mentoring contributions on the EduLink platform",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                ),
              ),

              pw.SizedBox(height: 25),

              /// BADGE
              pw.Text(
              "$badge Mentor",
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange,
              ),
            ),

              pw.SizedBox(height: 40),

              /// FOOTER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [

                  pw.Column(
                    children: [

                      pw.Text(
                        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                        style: pw.TextStyle(fontSize: 14),
                      ),

                      pw.Text("Date"),
                    ],
                  ),

                  pw.Column(
                    children: [

                      pw.Text(
                        "EduLink Authority",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}