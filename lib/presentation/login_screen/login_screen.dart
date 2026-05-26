import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/api/institution_service.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/api/auth_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import './widgets/institution_logo_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/role_selection_widget.dart';

/// Login Screen for EduTenant LMS
/// Enables secure user authentication with mobile-optimized input methods
/// and role-based access control with tenant branding
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showRoleSelection = false;
  String? _selectedRole;
  String? _errorMessage;
  String? _institutionCode;
  String? _institutionName;
  String? _institutionLogo;


// @override
// void initState() {
//   super.initState();
//   _loadInstitutionBranding();
// }

@override
void initState() {
  super.initState();
  _initializeSession();
}

Future<void> _initializeSession() async {
  await SessionService.instance.init();

  setState(() {
    _institutionCode = SessionService.instance.institutionCode;
    _institutionName = SessionService.instance.institutionName;
    _institutionLogo = SessionService.instance.institutionLogo;
  });

  await _loadInstitutionBranding();
}

Future<void> _loadInstitutionBranding() async {
  await SessionService.instance.init();

  final code = SessionService.instance.institutionCode;

  if (code == null) return;

  final response =
      await InstitutionService.instance.getInstitution(code);

  setState(() {
    _institutionName = response['name'];
    _institutionLogo = response['logo'];
  });

  // Save to session properly
  await SessionService.instance.setInstitution(
    code: code,
    name: _institutionName,
    logo: _institutionLogo,
  );

  print("LOADED LOGO FROM API: $_institutionLogo");
}
@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    _institutionCode = args['institutionCode']?.toString();
    _institutionName = args['institutionName']?.toString();
    _institutionLogo = args['institutionLogo']?.toString();
  }

  // ✅ ALWAYS restore from session if null
  _institutionCode ??= SessionService.instance.institutionCode;
  _institutionName ??= SessionService.instance.institutionName;
  _institutionLogo ??= SessionService.instance.institutionLogo;
}

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });


print("SESSION INSTITUTION CODE: ${SessionService.instance.institutionCode}");
print("SESSION INSTITUTION NAME: ${SessionService.instance.institutionName}");
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    await SessionService.instance.init();
await SessionService.instance.init();
final institutionCode =
    _institutionCode ?? SessionService.instance.institutionCode;

// 🔹 If trying platform admin login, allow without institution
final isPlatformLogin = institutionCode == null || institutionCode.isEmpty;

    try {
final response = await AuthService.instance.login(
  email: username,
  password: password,
  institutionCode: institutionCode,
);
      final user = response['user'] as Map<String, dynamic>;

      final normalizedRole = normalizeRoleValue(
        user['role']?.toString(),
      );

      if (normalizedRole.isEmpty) {
        throw Exception('Unable to determine user role.');
      }

// ✅ SAVE USER + ROLE INTO SESSION
      await SessionService.instance.setCurrentUser({
        ...user,
        'role': normalizedRole,
      });


final userInstitutionCode =
    user['institution_code']?.toString();

if (userInstitutionCode != null && userInstitutionCode.isNotEmpty) {
  await SessionService.instance.setInstitution(
    code: userInstitutionCode,
    name: _institutionName,
    logo: _institutionLogo,
  );
} else {
  await SessionService.instance.clearInstitution();
}

print("LOGIN SAVED institutionCode: ${SessionService.instance.institutionCode}");
print("LOGIN SAVED currentUser: ${SessionService.instance.currentUser}");
// (optional but VERY useful for debugging)
      debugPrint('LOGIN SAVED ROLE = $normalizedRole');

      if (!mounted) return;
      setState(() => _isLoading = false);

// ✅ NOW navigate
      _navigateToDashboard(normalizedRole);

    } catch (e) {
  setState(() {
    _isLoading = false;

    final msg = e.toString().toLowerCase();

    if (msg.contains('invalid') || msg.contains('401')) {
      _errorMessage = 'Incorrect email or password. Please try again.';
    } 
    else if (msg.contains('network')) {
      _errorMessage = 'Unable to connect. Check your internet connection.';
    }
    else {
      _errorMessage = 'Login failed. Please try again.';
    }
  });
}}

  void _handleRoleSelection(String role) {
    setState(() {
      _selectedRole = role;
    });
    _navigateToDashboard(role);
  }

  void _navigateToDashboard(String role) {
    HapticFeedback.mediumImpact();

    final normalizedRole = normalizeRoleValue(role);

    switch (normalizedRole) {
      case 'platform_admin':
        Navigator.pushReplacementNamed(
          context,
          '/platform-admin-dashboard',
        );
        break;

      case 'admin':
        Navigator.pushReplacementNamed(
          context,
          '/admin-dashboard',
        );
        break;

      case 'instructor':
        Navigator.pushReplacementNamed(
          context,
          '/instructor-dashboard',
        );
        break;

      case 'student':
      default:
        Navigator.pushReplacementNamed(
          context,
          '/student-dashboard',
        );
        break;
    }
  }


  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Password reset functionality will be available soon. Please contact your institution administrator for assistance.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSwitchInstitution() {
    Navigator.pushReplacementNamed(context, '/institution-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: Column(
                    children: [
                      SizedBox(height: 0.h),

                      // Institution Logo
                    InstitutionLogoWidget(
  institutionName: _institutionName,
  logoUrl: _institutionLogo,
),

 
                      SizedBox(height: 4.h),

                      // Welcome Text
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 1.h),

                      Text(
                        'Sign in to continue learning',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'error_outline',
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Login Form or Role Selection
                      if (!_showRoleSelection)
                        LoginFormWidget(
                          formKey: _formKey,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          isPasswordVisible: _isPasswordVisible,
                          isLoading: _isLoading,
                          onPasswordVisibilityToggle: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          onForgotPassword: _handleForgotPassword,
                          onLogin: _handleLogin,
                        )
                      else
                        RoleSelectionWidget(
                          availableRoles: const ['Student'],
                          selectedRole: _selectedRole,
                          onRoleSelected: _handleRoleSelection,
                        ),

                      const Spacer(),

                      SizedBox(height: 3.h),

                      // Switch Institution Link
                      TextButton(
                        onPressed: _handleSwitchInstitution,
                        child: Text(
                          'Switch Institution',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      if (_institutionName != null)
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Connected Institution',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                _institutionName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
