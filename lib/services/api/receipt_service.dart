import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../services/api/api_config.dart';

class ReceiptService {
  static Future<void> downloadReceipt(
    Map<String, dynamic> payment, {
    required String instituteName,
    required String studentName,
    required String studentId,
    String? logoUrl, // 🔥 from DB
  }) async {
    final pdf = pw.Document();
final font = await pw.Font.ttf(
  await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
);
pw.ImageProvider? logoImage;

if (logoUrl != null) {
  final fullUrl = "${ApiConfig.publicBaseUrl}$logoUrl";

  print("LOGO URL: $fullUrl");

  try {
    logoImage = await networkImage(fullUrl);
  } catch (e) {
    print("LOGO ERROR: $e");
  }
}

pdf.addPage(
  pw.Page(
theme: pw.ThemeData.withFont(
  base: font,
  bold: font,
  italic: font,
  boldItalic: font,
),
    build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // 🔥 HEADER WITH LOGO
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
// pw.Container(
//   height: 60,
//   width: 60,
//   child: logoImage != null
//       ? pw.Image(logoImage!)
//       : pw.Text("NO LOGO"),
// ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            instituteName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "Fee Receipt",
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.Text(
                    "RECEIPT",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),

              // 🔥 STUDENT INFO
              pw.Text(
                "Student Details",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Name:"),
                  pw.Text(studentName),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Student ID:"),
                  pw.Text(studentId),
                ],
              ),

              pw.SizedBox(height: 15),

              // 🔥 TRANSACTION INFO
              pw.Text(
                "Transaction Details",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Transaction ID:"),
                  pw.Text(payment['transactionId']),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Date:"),
                  pw.Text(payment['date']),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Method:"),
                  pw.Text(payment['method']),
                ],
              ),

              pw.SizedBox(height: 20),

              // 🔥 TABLE HEADER
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey300,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Description",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Amount",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              // 🔥 TABLE ROW
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(payment['description']),
                    pw.Text("₹${payment['amount']}"),
                  ],
                ),
              ),

              pw.Divider(),

              // 🔥 TOTAL
pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.Text(
    "Total: ₹ ${payment['amount']}", // space added
    style: pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
),

              pw.SizedBox(height: 30),

              // 🔥 FOOTER
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  "This is a computer-generated receipt.\nNo signature required.",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      "${dir.path}/receipt_${payment['transactionId']}.pdf",
    );

    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }
}