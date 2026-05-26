import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/sync_status_badge.dart';
import './widgets/help_section_widget.dart';
import './widgets/institution_code_input_widget.dart';
import './widgets/institution_logo_widget.dart';
import '../../services/api/institution_service.dart';
import '../../services/api/session_service.dart';


/// Institution Setup Screen
/// Enables first-time users to connect their educational institution through Institution Code entry
class InstitutionSetup extends StatefulWidget {
  const InstitutionSetup({super.key});

  @override
  State<InstitutionSetup> createState() => _InstitutionSetupState();
}

class _InstitutionSetupState extends State<InstitutionSetup> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isValidCode = false;
  String? _institutionName;
  String? _errorMessage;
  String? _lastFetchedCode;
  String? _institutionLogo;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_validateCode);
  }



  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }
void _validateCode() async {
  final code = _codeController.text.replaceAll(RegExp(r'\D'), '');

  if (code.length != 6) {
    setState(() {
      _isValidCode = false;
      _institutionName = null;
      _institutionLogo = null;
      _errorMessage = null;
      _lastFetchedCode = null;
    });
    return;
  }

  if (_lastFetchedCode == code) return;
  _lastFetchedCode = code;

  setState(() {
    _isValidCode = true;
    _errorMessage = null;
  });

  try {
    final institution =
        await InstitutionService.instance.getInstitution(code);

    final data = institution['data'] ?? institution;
    final name = data['name']?.toString();
    final logo = data['logo']?.toString();

    if (!mounted) return;

    setState(() {
      _institutionName = name;
      _institutionLogo = logo;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _institutionName = null;
      _institutionLogo = null;
      _errorMessage = 'Invalid institution code';
    });
  }
}



  /// Handles the connect button press
  Future<void> _handleConnect() async {
    if (!_isValidCode || _isLoading) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code =
      _codeController.text.replaceAll(RegExp(r'\D'), '');

      final institution = await InstitutionService.instance.getInstitution(
        code,
      );
      final data = institution['data'] ?? institution;
      final institutionName = data['name']?.toString();


      if (institutionName == null || institutionName.isEmpty) {
        throw Exception('Institution not found');
      }

      await SessionService.instance.setInstitution(
        code: code,
        name: institutionName,
      );

      // Success - provide haptic feedback
      HapticFeedback.mediumImpact();

      // Navigate to login screen with institution branding
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/login-screen',
          arguments: {
            'institutionCode': code,
            'institutionName': institutionName,
                'institutionLogo': _institutionLogo, // ✅ ADD THIS
          },
        );
      }
    } catch (e) {
      // Network error or invalid code
      setState(() {
        _errorMessage =
            'Institution not found or server unavailable. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Shows help bottom sheet
  void _showHelpSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const HelpBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Institution Setup',
        variant: AppBarVariant.standard,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // const SyncStatusBadge(showTimestamp: true, compact: false),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 8.h),

                  // Institution Logo Placeholder
InstitutionLogoWidget(
  institutionName: _institutionName,
  logoUrl: _institutionLogo,
),



                  SizedBox(height: 6.h),

                  // Title
                  Text(
                    'Connect Your Institution',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 2.h),

                  // Subtitle
                  Text(
                    'Enter your institution code to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 6.h),

                  // Institution Code Input
                  InstitutionCodeInputWidget(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    isValid: _isValidCode,
                    institutionName: _institutionName,
                    errorMessage: _errorMessage,
                    enabled: !_isLoading,
                  ),

                  SizedBox(height: 4.h),

                  // Help Section
                  HelpSectionWidget(onHelpTap: _showHelpSheet),

                  SizedBox(height: 6.h),

                  // Connect Button
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isValidCode && !_isLoading
        ? _handleConnect
        : null,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48), // ✅ standard Material height
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      disabledBackgroundColor:
          theme.colorScheme.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor:
          theme.colorScheme.onSurface.withValues(alpha: 0.38),
      elevation: _isValidCode && !_isLoading ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: _isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : Text(
            'Connect',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
  ),
),

                  SizedBox(height: 3.h),

                  // Need Help Button
                  TextButton(
                    onPressed: _isLoading ? null : _showHelpSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'help_outline',
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Need Help?',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Help Bottom Sheet Widget
class HelpBottomSheet extends StatelessWidget {
  const HelpBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Title
          Text(
            'Need Help?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 3.h),

          // FAQ Section
          _buildFAQItem(
            context,
            'Where do I find my institution code?',
            'Contact your institution\'s administration office or IT department. They will provide you with a 6-digit code.',
          ),

          SizedBox(height: 2.h),

          _buildFAQItem(
            context,
            'What if my code doesn\'t work?',
            'Ensure you\'ve entered the correct 6-digit code. If the problem persists, contact your institution for verification.',
          ),

          SizedBox(height: 2.h),

          _buildFAQItem(
            context,
            'Can I change my institution later?',
            'Yes, you can disconnect and connect to a different institution from the settings menu.',
          ),

          SizedBox(height: 4.h),

          // Contact Support Button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle contact support
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'support_agent',
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Contact Support',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
