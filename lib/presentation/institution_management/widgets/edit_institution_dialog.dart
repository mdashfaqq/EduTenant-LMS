// import 'package:flutter/material.dart';
// import 'package:sizer/sizer.dart';
//
// class EditInstitutionDialog extends StatefulWidget {
//   final Map<String, dynamic> institution;
//   final Function(Map<String, dynamic>) onUpdate;
//
//   const EditInstitutionDialog({
//     super.key,
//     required this.institution,
//     required this.onUpdate,
//   });
//
//   @override
//   State<EditInstitutionDialog> createState() => _EditInstitutionDialogState();
// }
//
// class _EditInstitutionDialogState extends State<EditInstitutionDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _addressController;
//   late TextEditingController _emailController;
//   late TextEditingController _phoneController;
//   late TextEditingController _academicYearController;
//   late TextEditingController _userLimitController;
//   late Map<String, bool> _modules;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.institution['name']);
//     _addressController = TextEditingController(
//       text: widget.institution['address'],
//     );
//     _emailController = TextEditingController(
//       text: widget.institution['contactEmail'],
//     );
//     _phoneController = TextEditingController(
//       text: widget.institution['contactPhone'],
//     );
//     _academicYearController = TextEditingController(
//       text: widget.institution['academicYear'],
//     );
//     _userLimitController = TextEditingController(
//       text: widget.institution['userLimit'].toString(),
//     );
//     _modules = Map<String, bool>.from(widget.institution['modules']);
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _academicYearController.dispose();
//     _userLimitController.dispose();
//     super.dispose();
//   }
//
//   String? _validateRequired(String? value, String fieldName) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter $fieldName';
//     }
//     return null;
//   }
//
//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter email';
//     }
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(value)) {
//       return 'Please enter a valid email';
//     }
//     return null;
//   }
//
//   void _handleSubmit() {
//     if (_formKey.currentState!.validate()) {
//       widget.onUpdate({
//         'name': _nameController.text.trim(),
//         'address': _addressController.text.trim(),
//         'contactEmail': _emailController.text.trim(),
//         'contactPhone': _phoneController.text.trim(),
//         'academicYear': _academicYearController.text.trim(),
//         'userLimit': int.parse(_userLimitController.text),
//         'modules': Map.from(_modules),
//       });
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(4.w),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         'Edit Institution',
//                         style: theme.textTheme.titleLarge?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Institution Code (Read-only)
//                 Container(
//                   padding: EdgeInsets.all(3.w),
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.surfaceContainerHighest,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.vpn_key,
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                       SizedBox(width: 2.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Institution Code',
//                               style: theme.textTheme.labelSmall?.copyWith(
//                                 color: theme.colorScheme.onSurfaceVariant,
//                               ),
//                             ),
//                             Text(
//                               widget.institution['code'],
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Institution Name
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Institution Name *',
//                     prefixIcon: Icon(Icons.business),
//                   ),
//                   validator: (value) =>
//                       _validateRequired(value, 'institution name'),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Address
//                 TextFormField(
//                   controller: _addressController,
//                   decoration: const InputDecoration(
//                     labelText: 'Address *',
//                     prefixIcon: Icon(Icons.location_on),
//                   ),
//                   validator: (value) => _validateRequired(value, 'address'),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Contact Email
//                 TextFormField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: const InputDecoration(
//                     labelText: 'Contact Email *',
//                     prefixIcon: Icon(Icons.email),
//                   ),
//                   validator: _validateEmail,
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Contact Phone
//                 TextFormField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: const InputDecoration(
//                     labelText: 'Contact Phone *',
//                     prefixIcon: Icon(Icons.phone),
//                   ),
//                   validator: (value) =>
//                       _validateRequired(value, 'phone number'),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Academic Year
//                 TextFormField(
//                   controller: _academicYearController,
//                   decoration: const InputDecoration(
//                     labelText: 'Academic Year *',
//                     prefixIcon: Icon(Icons.calendar_today),
//                   ),
//                   validator: (value) =>
//                       _validateRequired(value, 'academic year'),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // User Limit
//                 TextFormField(
//                   controller: _userLimitController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                     labelText: 'User Limit *',
//                     prefixIcon: Icon(Icons.people),
//                   ),
//                   validator: (value) => _validateRequired(value, 'user limit'),
//                 ),
//                 SizedBox(height: 2.h),
//
//                 // Module Selection
//                 Text(
//                   'Enable/Disable Modules',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 SizedBox(height: 1.h),
//                 ..._modules.keys.map((module) {
//                   return CheckboxListTile(
//                     title: Text(
//                       module[0].toUpperCase() + module.substring(1),
//                       style: theme.textTheme.bodyMedium,
//                     ),
//                     value: _modules[module],
//                     onChanged: (value) {
//                       setState(() {
//                         _modules[module] = value ?? false;
//                       });
//                     },
//                     contentPadding: EdgeInsets.zero,
//                     controlAffinity: ListTileControlAffinity.leading,
//                   );
//                 }),
//                 SizedBox(height: 2.h),
//
//                 // Action Buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel'),
//                     ),
//                     SizedBox(width: 2.w),
//                     ElevatedButton(
//                       onPressed: _handleSubmit,
//                       child: const Text('Update Institution'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

class EditInstitutionDialog extends StatefulWidget {
  final Map<String, dynamic> institution;
  final void Function(Map<String, dynamic> payload, File? logoFile) onUpdate;

  const EditInstitutionDialog({
    super.key,
    required this.institution,
    required this.onUpdate,
  });

  @override
  State<EditInstitutionDialog> createState() => _EditInstitutionDialogState();
}

class _EditInstitutionDialogState extends State<EditInstitutionDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _userLimitController;

  late Map<String, bool> _modules;
  File? _logoFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.institution['name']);
    _addressController =
        TextEditingController(text: widget.institution['address']);
    _emailController =
        TextEditingController(text: widget.institution['contactEmail']);
    _phoneController =
        TextEditingController(text: widget.institution['contactPhone']);
    _academicYearController =
        TextEditingController(text: widget.institution['academicYear']);
    _userLimitController =
        TextEditingController(text: widget.institution['userLimit'].toString());

    _modules = Map<String, bool>.from(widget.institution['modules']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _academicYearController.dispose();
    _userLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _logoFile = File(image.path));
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Please enter $label' : null;

Future<void> _submit() async {
  debugPrint('🟡 [EditDialog] SUBMIT clicked');

  if (!_formKey.currentState!.validate()) {
    debugPrint('🔴 [EditDialog] Form validation failed');
    return;
  }

  if (_submitting) {
    debugPrint('🟠 [EditDialog] Already submitting, ignored');
    return;
  }


    setState(() => _submitting = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'academic_year': _academicYearController.text.trim(),
        'user_limit': int.parse(_userLimitController.text),

        // modules (snake_case, exploded)
        'modules_courses': _modules['courses'] ?? false,
        'modules_assignments': _modules['assignments'] ?? false,
        'modules_grades': _modules['grades'] ?? false,
        'modules_attendance': _modules['attendance'] ?? false,
        'modules_fees': _modules['fees'] ?? false,
        'modules_discussions': _modules['discussions'] ?? false,
        'modules_exams': _modules['exams'] ?? false,
      };
      debugPrint('🟢 [EditDialog] Payload ready:');
debugPrint(payload.toString());
debugPrint('🟢 [EditDialog] Logo file: ${_logoFile?.path}');

      widget.onUpdate(payload, _logoFile);
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Institution',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Logo
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: _logoFile != null
                        ? Image.file(_logoFile!, fit: BoxFit.cover)
                        : widget.institution['logo'] != null
                            ? Image.network(
                                widget.institution['logo'],
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(Icons.image, size: 40),
                              ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Institution Name *'),
                  validator: (v) => _required(v, 'institution name'),
                ),
                SizedBox(height: 2.h),

                // User limit
                TextFormField(
                  controller: _userLimitController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'User Limit *'),
                  validator: (v) => _required(v, 'user limit'),
                ),
                SizedBox(height: 2.h),

                Text('Modules', style: theme.textTheme.titleMedium),
                ..._modules.keys.map(
                  (m) => CheckboxListTile(
                    title:
                        Text(m[0].toUpperCase() + m.substring(1)),
                    value: _modules[m],
                    onChanged: (v) =>
                        setState(() => _modules[m] = v ?? false),
                  ),
                ),

                SizedBox(height: 2.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Institution'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
