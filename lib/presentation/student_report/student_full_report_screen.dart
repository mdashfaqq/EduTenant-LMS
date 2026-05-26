import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../services/api/exam_results_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/session_service.dart';
import '../../services/api/institution_service.dart';
import '../../services/api/api_config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StudentFullReportScreen extends StatefulWidget {
  final int studentId;

  const StudentFullReportScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentFullReportScreen> createState() =>
      _StudentFullReportScreenState();
}

class _StudentFullReportScreenState
    extends State<StudentFullReportScreen> {

  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    
    final data = await ExamResultsService.instance
        .getResultsByStudent(widget.studentId);
      print("REPORT DATA: $data");
    if (!mounted) return;


    setState(() {
      _results = data;
      _loading = false;
    });
  }

  // 🔹 Grade → Color
  Color _gradeColor(String grade) {
    if (grade.startsWith("A")) return Colors.green;
    if (grade.startsWith("B")) return Colors.blue;
    if (grade.startsWith("C")) return Colors.orange;
    return Colors.red;
  }

  // 🔹 Grade → GPA Points
  double _gradeToPoint(String grade) {
    switch (grade) {
      case "A+":
      case "A":
        return 4.0;
      case "B":
        return 3.0;
      case "C":
        return 2.0;
      default:
        return 0.0;
    }
  }

  // 🔹 Generate PDF
 Future<void> _downloadPdf() async {
  
  final pdf = pw.Document();

  final student = SessionService.instance.currentUser;
  final studentName = student?['name'] ?? "Student";
  final studentId = student?['id']?.toString() ?? "-";

  // 🔹 Fetch institution
  final institution =
      await InstitutionService.instance.getCurrentInstitution();

  final institutionName =
      institution?['name'] ?? "Institution";

  final logoPath = institution?['logo'];

  pw.ImageProvider? logoImage;

  if (logoPath != null) {
final fullUrl =
    "${ApiConfig.publicBaseUrl}$logoPath";

logoImage = await networkImage(fullUrl);
  }

  // 🔹 GPA Calculation
  double totalMarks = 0;
  double totalPoints = 0;

  for (var r in _results) {
    final marks =
        double.tryParse(r['marks_obtained'] ?? "0") ?? 0;

    totalMarks += marks;

    totalPoints += _gradeToPoint(r['grade'] ?? "F");
  }

  final avg = totalMarks / _results.length;
  final gpa = totalPoints / _results.length;
debugPrint("Institution: $institution");
debugPrint("Logo path: $logoPath");
  pdf.addPage(
    
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [

        // ================= HEADER =================
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logoImage),
              ),

            pw.SizedBox(width: 20),

            pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  institutionName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "Official Academic Transcript",
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            )
          ],
        ),

        pw.Divider(),
        pw.SizedBox(height: 20),

        // ================= STUDENT INFO =================
        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Student Name: $studentName"),
            pw.Text("Student ID: $studentId"),
          ],
        ),

        pw.SizedBox(height: 5),
        pw.Text(
            "Date: ${DateTime.now().toString().split(' ').first}"),

        pw.SizedBox(height: 20),

        // ================= SUMMARY =================
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
          ),
          child: pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Text("Average"),
                pw.Text(
                  avg.toStringAsFixed(1),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold),
                ),
              ]),
              pw.Column(children: [
                pw.Text("GPA"),
                pw.Text(
                  gpa.toStringAsFixed(2),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold),
                ),
              ]),
              pw.Column(children: [
                pw.Text("Total Exams"),
                pw.Text(
                  _results.length.toString(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold),
                ),
              ]),
            ],
          ),
        ),

        pw.SizedBox(height: 30),

        // ================= TABLE =================
        pw.Table.fromTextArray(
          headers: [
            "Exam Title",
            "Marks",
            "Percentage",
            "Grade"
          ],
          data: _results.map((r) {
            return [
              r['exam_title'] ?? "",
              r['marks_obtained'] ?? "",
              r['percentage'] ?? "",
              r['grade'] ?? "",
            ];
          }).toList(),
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),

        pw.SizedBox(height: 40),

// ================= FOOTER =================
pw.Divider(),
pw.SizedBox(height: 10),

pw.Center(
  child: pw.Column(
    children: [
      pw.Text(
        "This report is auto-generated by the system.",
        style: pw.TextStyle(fontSize: 10),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        "No manual signature is required.",
        style: pw.TextStyle(fontSize: 10),
      ),
    ],
  ),
),
      ],
    ),
  );

final bytes = await pdf.save();

await Printing.sharePdf(
  bytes: bytes,
  filename: "Academic_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Choose a location to save your report"),
  ),
);
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("My Academic Report"),
      actions: [
        if (!_loading && _results.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _downloadPdf,
          )
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _results.isEmpty
            ? const Center(child: Text("No results available"))
            : _buildReportContent(),
    bottomNavigationBar: CustomBottomBar(
      variant: bottomBarVariantFromRole(
        SessionService.instance.currentUser?['role'],
      ),
    ),
  );
}

  Widget _buildReportContent() {
  double totalMarks = 0;
  double totalPoints = 0;

  for (var r in _results) {
    totalMarks +=
        double.tryParse(r['marks_obtained'] ?? "0") ?? 0;
    totalPoints += _gradeToPoint(r['grade'] ?? "F");
  }
final avg = _results.isEmpty
    ? 0
    : totalMarks / _results.length;

final gpa = _results.isEmpty
    ? 0
    : totalPoints / _results.length;

  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard("Average",
                  avg.toStringAsFixed(1)),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _summaryCard(
                  "GPA", gpa.toStringAsFixed(2)),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        SizedBox(
          height: 25.h,
          child: LineChart(
LineChartData(
  minY: 0,
  maxY: 100,
  gridData: FlGridData(show: true),
  titlesData: FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          int index = value.toInt();
          if (index < 0 || index >= _results.length) {
            return const SizedBox();
          }
          return Text(
            "E${index + 1}",
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  ),
  borderData: FlBorderData(show: true),
  lineBarsData: [
    LineChartBarData(
      spots: _results
          .asMap()
          .entries
          .map((e) {
        final value =
            double.tryParse(e.value['percentage'] ?? "0") ?? 0;
        return FlSpot(e.key.toDouble(), value);
      }).toList(),
      isCurved: true,
      barWidth: 3,
      dotData: FlDotData(show: true),
      color: Colors.blue,
    )
  ],
)
          ),
        ),
        SizedBox(height: 3.h),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final r = _results[index];
              final grade = r['grade'] ?? "";

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  title: Text(r['exam_title'] ?? ""),
                  subtitle: Text(
                      "Marks: ${r['marks_obtained']}"),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                    decoration: BoxDecoration(
                      color: _gradeColor(grade)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _gradeColor(grade),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _summaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Text(title),
            SizedBox(height: 1.h),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}