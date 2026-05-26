import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateInstitutionDialog extends StatefulWidget {
  final String generatedCode;
final Future<void> Function(
  Map<String, dynamic> data,
  File? logoFile,
) onAdd;


  const CreateInstitutionDialog({
    super.key,
    required this.generatedCode,
    required this.onAdd,
  });

  @override
  State<CreateInstitutionDialog> createState() =>
      _CreateInstitutionDialogState();
}


class _CreateInstitutionDialogState extends State<CreateInstitutionDialog> {
  final _formKey = GlobalKey<FormState>();
  File? _logoFile;
  bool _submitting = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _academicYearController = TextEditingController(text: '2024-2025');
  final _userLimitController = TextEditingController(text: '1000');

  String _primaryColor = '#2563EB';
  final Map<String, bool> _modules = {
    'courses': true,
    'assignments': true,
    'grades': true,
    'attendance': true,
    'fees': true,
    'discussions': true,
    'exams': true,
  };
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$');
    ;
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
    
await widget.onAdd(
  {
    'name': _nameController.text.trim(),
    'code': widget.generatedCode,
    'userLimit': int.parse(_userLimitController.text),
    'modules': Map.from(_modules),
  },
  _logoFile,
);


      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
    }
    finally {
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create Institution',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Institution Code (Auto-generated)
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: theme.colorScheme.primary),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Institution Code (Auto-generated)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.generatedCode,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
// Institution Logo Picker
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: _logoFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 40),
                        SizedBox(height: 8),
                        Text('Upload Institution Logo'),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _logoFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Institution Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Institution Name *',
                    hintText: 'Enter institution name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'institution name'),
                ),
                SizedBox(height: 2.h),

                // Address
                // TextFormField(
                //   controller: _addressController,
                //   decoration: const InputDecoration(
                //     labelText: 'Address *',
                //     hintText: 'Enter full address',
                //     prefixIcon: Icon(Icons.location_on),
                //   ),
                //   validator: (value) => _validateRequired(value, 'address'),
                // ),
                // SizedBox(height: 2.h),

                // // Contact Email
                // TextFormField(
                //   controller: _emailController,
                //   keyboardType: TextInputType.emailAddress,
                //   decoration: const InputDecoration(
                //     labelText: 'Contact Email *',
                //     hintText: 'admin@institution.edu',
                //     prefixIcon: Icon(Icons.email),
                //   ),
                //   validator: _validateEmail,
                // ),
                // SizedBox(height: 2.h),

                // // Contact Phone
                // TextFormField(
                //   controller: _phoneController,
                //   keyboardType: TextInputType.phone,
                //   decoration: const InputDecoration(
                //     labelText: 'Contact Phone *',
                //     hintText: '+1-555-0000',
                //     prefixIcon: Icon(Icons.phone),
                //   ),
                //   validator: (value) =>
                //       _validateRequired(value, 'phone number'),
                // ),
                // SizedBox(height: 2.h),

                // // Academic Year
                // TextFormField(
                //   controller: _academicYearController,
                //   decoration: const InputDecoration(
                //     labelText: 'Academic Year *',
                //     hintText: '2024-2025',
                //     prefixIcon: Icon(Icons.calendar_today),
                //   ),
                //   validator: (value) =>
                //       _validateRequired(value, 'academic year'),
                // ),
                // SizedBox(height: 2.h),

                // User Limit
                TextFormField(
                  controller: _userLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'User Limit *',
                    hintText: '1000',
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) => _validateRequired(value, 'user limit'),
                ),
                SizedBox(height: 2.h),

                // Module Selection
                Text(
                  'Enable Modules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                ..._modules.keys.map((module) {
                  return CheckboxListTile(
                    title: Text(
                      module[0].toUpperCase() + module.substring(1),
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _modules[module],
                    onChanged: (value) {
                      setState(() {
                        _modules[module] = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
                SizedBox(height: 2.h),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Create Institution'),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
