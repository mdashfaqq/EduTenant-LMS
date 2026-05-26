import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/api/api_client.dart';
import '../../services/api/session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() =>
      _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
List<PlatformFile> _attachments = [];
  bool _submitting = false;
bool _initialized = false;
bool _isEdit = false;
String? _announcementId;
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();

  if (_initialized) return;

  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  final announcement = args?['announcement'];
  _isEdit = args?['isEdit'] == true;

  if (_isEdit && announcement != null) {
    _announcementId = announcement['announcement_id'];

    _titleController.text = announcement['title'] ?? '';
    _contentController.text = announcement['content'] ?? '';
  }

  _initialized = true;
}


Future<void> _pickFiles() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
     withData: true,
  );

  if (result != null) {
    setState(() {
      _attachments.addAll(result.files);
    });
  }
}

  Future<void> _submit(int courseId) async {
    debugPrint('🟡 SUBMIT CLICKED');
    debugPrint('📘 courseId = $courseId');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ FORM VALIDATION FAILED');
      return;
    }

if (_isEdit) {
  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  final original = args?['announcement'];

  if (original != null &&
      original['title'] == _titleController.text.trim() &&
      original['content'] == _contentController.text.trim()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No changes made')),
    );
    return;
  }
}
    setState(() => _submitting = true);

    try {
      // 🔍 SESSION DEBUG
      await SessionService.instance.init();
      debugPrint(
        '👤 USER = ${SessionService.instance.currentUser}',
      );
      debugPrint(
        '🔑 TOKEN = ${SessionService.instance.authToken}',
      );
      debugPrint(
        '🏫 INSTITUTION = ${SessionService.instance.institutionCode}',
      );

      debugPrint('📤 SENDING POST REQUEST');

final files = _attachments
    .where((f) => f.bytes != null)
    .map((file) => MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ))
    .toList();

final data = {
  if (_isEdit) 'announcement_id': _announcementId,
  if (!_isEdit) 'course_id': courseId,
  'title': _titleController.text.trim(),
  'content': _contentController.text.trim(),
  if (!_isEdit) 'priority': 'normal',
};

final res = _isEdit
    ? await ApiClient.instance.put(
        '/announcements.php',
        data: data,
      )
    : await ApiClient.instance.post(
        '/announcements.php',
        data: data,
      );

      debugPrint('✅ POST SUCCESS RESPONSE = $res');

      if (!mounted) return;

final message = res['message'] ?? '';

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      _isEdit
          ? (message.isNotEmpty ? message : 'Announcement updated')
          : 'Announcement posted',
    ),
  ),
);

      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('❌ POST FAILED');
      debugPrint('❌ ERROR = $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

String errorMessage = 'Something went wrong';

if (e is DioException) {
  final data = e.response?.data;

  if (data is Map && data['message'] != null) {
    errorMessage = data['message'];
  } else if (e.response?.statusCode == 400) {
    errorMessage = 'No changes made';
  } else if (e.response?.statusCode == 403) {
    errorMessage = 'You are not allowed to edit this';
  } else if (e.response?.statusCode == 404) {
    errorMessage = 'Announcement not found';
  }
}

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(errorMessage)),
);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    debugPrint('📦 ROUTE ARGS = $args');

    final courseId = args?['courseId'];

    if (courseId == null) {
      debugPrint('❌ courseId NULL — navigation bug');
      return const Scaffold(
        body: Center(child: Text('Invalid course')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEdit ? 'Edit Announcement' : 'Create Announcement',
        variant: AppBarVariant.standard,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Announcement',
                ),
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,

              ),

//               Align(
//   alignment: Alignment.centerLeft,
//   child: TextButton.icon(
//     onPressed: _pickFiles,
//     icon: const Icon(Icons.attach_file),
//     label: const Text("Add Attachment"),
//   ),
// ),

if (_attachments.isNotEmpty)
  SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final file = _attachments[index];

        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file),
              const SizedBox(width: 6),
              SizedBox(
                width: 100,
                child: Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _attachments.removeAt(index);
                  });
                },
              )
            ],
          ),
        );
      },
    ),
  ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(courseId),
child: Text(_isEdit ? 'Update Announcement' : 'Post Announcement')
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
