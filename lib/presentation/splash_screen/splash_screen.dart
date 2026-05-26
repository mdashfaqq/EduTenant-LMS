import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../core/app_export.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import 'package:local_auth/local_auth.dart';


//

/// Splash Screen for EduTenant LMS
///
/// Provides branded app launch experience while initializing multi-tenant LMS services
/// and determining user navigation path based on authentication status and user role.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
final LocalAuthentication _auth = LocalAuthentication();

  bool _isInitializing = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  /// Setup fade and scale animations for logo
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }



Future<void> _handleBiometricIfEnabled(String? userRole) async {
  final isBiometricEnabled =
      SessionService.instance.biometricEnabled;

  if (!isBiometricEnabled) {
    Navigator.pushReplacementNamed(
      context,
      _getRoleDashboard(userRole),
    );
    return;
  }

  try {
    final authenticated = await _auth.authenticate(
      localizedReason: 'Authenticate to access your account',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (authenticated) {
      Navigator.pushReplacementNamed(
        context,
        _getRoleDashboard(userRole),
      );
    } else {
      await SessionService.instance.clearSession();
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  } catch (e) {
    Navigator.pushReplacementNamed(context, '/login-screen');
  }
}

void _goToHome() {
  Navigator.pushReplacementNamed(context, '/home');
}

void _goToLogin() {
  Navigator.pushReplacementNamed(context, '/login');
}

  /// Initialize app services and determine navigation path
  Future<void> _initializeApp() async {
    try {
      await SessionService.instance.init();

      // Step 1: Validate Institution Code from stored credentials
      if (mounted) {
        setState(() => _statusMessage = 'Validating institution...');
      }
      final hasInstitutionCode = await _validateInstitutionCode();

      // Step 2: Check authentication status
      if (mounted) {
        setState(() => _statusMessage = 'Checking authentication...');
      }
      final isAuthenticated = await _checkAuthenticationStatus();

      // Step 3: Load user role preferences
      if (mounted) {
        setState(() => _statusMessage = 'Loading preferences...');
      }
      final userRole = await _loadUserRole();

      // Step 4: Fetch tenant-specific configuration
      if (mounted) {
        setState(() => _statusMessage = 'Fetching configuration...');
      }
      await _fetchTenantConfiguration();

      // Step 5: Prepare cached course data
      if (mounted) {
        setState(() => _statusMessage = 'Preparing data...');
      }
      await _prepareCachedData();

      // Wait for animation to complete
      if (_animationController.status != AnimationStatus.completed) {
        await _animationController.forward();
      }

      // Navigate based on initialization results
if (!hasInstitutionCode) {
  Navigator.pushReplacementNamed(context, '/institution-setup');
  return;
}

if (!isAuthenticated) {
  Navigator.pushReplacementNamed(context, '/login-screen');
  return;
}

// 🔐 Only authenticated users reach here
await _handleBiometricIfEnabled(userRole);

    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        _handleInitializationError(e);
      }
    }
  }

  /// Validate Institution Code from stored credentials
  Future<bool> _validateInstitutionCode() async {
    final code = SessionService.instance.institutionCode;
    return code != null && code.trim().isNotEmpty;
  }

  /// Check authentication status
  Future<bool> _checkAuthenticationStatus() async {
    final token = SessionService.instance.authToken;
    final user = SessionService.instance.currentUser;
    return token != null &&
        token.isNotEmpty &&
        user != null &&
        user.isNotEmpty;
  }

  /// Load user role preferences
  Future<String?> _loadUserRole() async {
    final user = SessionService.instance.currentUser;
    final role = user?['role']?.toString();
    if (role == null || role.trim().isEmpty) {
      return null;
    }
    return role;
  }

  /// Fetch tenant-specific configuration
  Future<void> _fetchTenantConfiguration() async {
    // Simulate config fetch - In production, API call with Institution Code
    await Future.delayed(const Duration(milliseconds: 400));
    // Load branding, features, settings
  }

  /// Prepare cached course data
  Future<void> _prepareCachedData() async {
    // Simulate data preparation - In production, sync local database
    await Future.delayed(const Duration(milliseconds: 300));
    // Prepare offline content, course materials
  }

  /// Navigate to appropriate screen based on initialization results
  void _navigateToNextScreen({
    required bool hasInstitutionCode,
    required bool isAuthenticated,
    String? userRole,
  }) {
    String targetRoute;

    if (!hasInstitutionCode) {
      // New installation - show Institution Code entry
      targetRoute = '/institution-setup';
    } else if (!isAuthenticated) {
      // Returning non-authenticated user - show login
      targetRoute = '/login-screen';
    } else {
      // Authenticated user - navigate to role-specific dashboard
      targetRoute = _getRoleDashboard(userRole);
    }

    // Smooth fade transition to next screen
    Navigator.pushReplacementNamed(context, targetRoute);
  }

  /// Get dashboard route based on user role
  String _getRoleDashboard(String? role) {
    switch (normalizeRoleValue(role)) {
      case 'platform_admin':
        return '/platform-admin-dashboard';
      case 'admin':
        return '/admin-course-management';
      case 'instructor':
        return '/instructor-dashboard';
      case 'student':
      default:
        return '/student-dashboard';
    }
  }

  /// Handle initialization errors with retry option
  void _handleInitializationError(Object error) {
    setState(() {
      _isInitializing = false;
      _statusMessage = 'Connection error';
    });

    // Show retry option after 5 seconds timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _showRetryDialog();
      }
    });
  }

  /// Show retry dialog for initialization errors
  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
          'Unable to initialize the application. Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isInitializing = true;
                _statusMessage = 'Retrying...';
              });
              _initializeApp();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
decoration: BoxDecoration(
  color: theme.colorScheme.primary,
),

        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo Section
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Institution Logo
Container(
  width: 40.w,
  height: 40.w,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 25,
        offset: const Offset(0, 12),
      ),
    ],
    image: const DecorationImage(
      image: AssetImage('assets/images/Splash_screen_logo.png'),
      fit: BoxFit.cover, // 👈 fills entire container
    ),
  ),
),



                    SizedBox(height: 3.h),

                    // App Name
                    Text(
                      'EduTenant LMS',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Tagline
                    Text(
                      'Learn Anywhere, Anytime',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator Section
              if (_isInitializing) ...[
                SizedBox(
                  width: 8.w,
                  height: 8.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Status Message
                Text(
                  _statusMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],

              SizedBox(height: 4.h),

              // Version Info
              Text(
                'Version 1.0.1 ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10.sp,
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
