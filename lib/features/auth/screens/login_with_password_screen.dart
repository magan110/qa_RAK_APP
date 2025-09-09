import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen_with_otp.dart';

class LoginWithPasswordScreen extends StatefulWidget {
  const LoginWithPasswordScreen({super.key});

  @override
  State<LoginWithPasswordScreen> createState() =>
      _LoginWithPasswordScreenState();
}

class _LoginWithPasswordScreenState extends State<LoginWithPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final bool _isDarkMode = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use AuthService for login
      final success = await AuthService.login(
        _userIdController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showErrorSnackBar('Invalid credentials. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Login failed. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
          final isDesktop = constraints.maxWidth >= 1200;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A0A0A),
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFf8f9ff),
                        Color(0xFFe3f2fd),
                        Color(0xFFffffff),
                      ],
                    ),
            ),
            child: Stack(
              children: [
                if (Navigator.of(context).canPop())
                  const Positioned(
                    top: 50,
                    left: 20,
                    child: CustomBackButton(),
                  ),
                isMobile
                    ? _buildMobileLayout(isDark)
                    : _buildWebLayout(isDark, isTablet, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/rak_logo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback with RAK text logo if image fails to load
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'RAK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: isDark ? 0 : 24,
                  shadowColor: isDark
                      ? Colors.transparent
                      : Colors.blue.withOpacity(0.15),
                  color: isDark
                      ? const Color(0xFF1E1E1E).withOpacity(0.95)
                      : Colors.white.withOpacity(0.98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: isDark
                        ? BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(40),
                    child: _buildLoginForm(isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(bool isDark, bool isTablet, bool isDesktop) {
    return Row(
      children: [
        // Left side - Branding/Info
        Expanded(
          flex: isDesktop ? 3 : 2,
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 80 : 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedLogo(),
                SizedBox(height: isDesktop ? 40 : 32),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 36,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                Text(
                  'Sign in to access your RAK account and manage your registrations.',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Login Form
        Expanded(
          flex: isDesktop ? 2 : 3,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withOpacity(0.95)
                  : Colors.white.withOpacity(0.98),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 60 : 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginForm(isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedTitle(),
          const SizedBox(height: 32),
          ModernTextField(
            controller: _userIdController,
            labelText: 'User ID',
            hintText: 'Enter your user ID',
            keyboardType: TextInputType.text,
            isDark: isDark,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your user ID';
              }
              return null;
            },
            delay: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 24),
          ModernPasswordField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            isDark: isDark,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            delay: const Duration(milliseconds: 450),
          ),
          const SizedBox(height: 16),
          _buildRememberMeSection(),
          const SizedBox(height: 32),
          ModernButton(
            text: 'Sign In',
            isLoading: _isLoading,
            onPressed: _handleLogin,
            isPrimary: true,
            isDark: isDark,
            delay: const Duration(milliseconds: 600),
          ),
          const SizedBox(height: 16),
          ModernButton(
            text: 'Continue with OTP',
            isLoading: false,
            onPressed: () {
              Navigator.pushNamed(context, '/login-otp');
            },
            isPrimary: false,
            isDark: isDark,
            delay: const Duration(milliseconds: 750),
          ),
          const SizedBox(height: 24),
          _buildSignUpSection(),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        'Login',
        style: AppTheme.headline.copyWith(color: Colors.blue),
      ),
    );
  }

  Widget _buildRememberMeSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Implement forgot password
                  _showErrorSnackBar('Forgot password will be implemented');
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignUpSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registration-type');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Duration delay;

  const AnimatedPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    required this.delay,
  });

  @override
  State<AnimatedPasswordField> createState() => _AnimatedPasswordFieldState();
}

class _AnimatedPasswordFieldState extends State<AnimatedPasswordField> {
  bool _isVisible = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

// Custom animated text field
class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Duration delay;

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixText,
    required this.keyboardType,
    this.validator,
    required this.delay,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          keyboardType: widget.keyboardType,
          validator: widget.validator,
        ),
      ),
    );
  }
}

// Custom animated button
class AnimatedButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Duration delay;
  final Color? textColor;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.delay,
    this.textColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.blue,
              foregroundColor: widget.textColor ?? Colors.white,
            ),
            child: widget.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Please wait...'),
                    ],
                  )
                : Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Modern TextField Component
class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Duration delay;
  final bool isDark;
  final IconData? prefixIcon;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.keyboardType,
    this.validator,
    required this.delay,
    required this.isDark,
    this.prefixIcon,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _isVisible = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? Colors.blue
                          : (widget.isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade50,
              labelStyle: TextStyle(
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
              ),
              hintStyle: TextStyle(
                color: widget.isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

// Modern Password Field Component
class ModernPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Duration delay;
  final bool isDark;

  const ModernPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    required this.delay,
    required this.isDark,
  });

  @override
  State<ModernPasswordField> createState() => _ModernPasswordFieldState();
}

class _ModernPasswordFieldState extends State<ModernPasswordField> {
  bool _isVisible = false;
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
              ),
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(_obscureText),
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade50,
              labelStyle: TextStyle(
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
              ),
              hintStyle: TextStyle(
                color: widget.isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

// Modern Button Component
class ModernButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Duration delay;
  final bool isPrimary;
  final bool isDark;

  const ModernButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.delay,
    required this.isPrimary,
    required this.isDark,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: widget.isPrimary
              ? ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style:
                      ElevatedButton.styleFrom(
                        elevation: _isHovered ? 12 : 6,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey.shade400;
                          }
                          return Colors.blue;
                        }),
                      ),
                  onHover: (hovering) {
                    setState(() {
                      _isHovered = hovering;
                    });
                  },
                  child: widget.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text('Signing in...'),
                          ],
                        )
                      : Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                )
              : OutlinedButton(
                  onPressed: widget.onPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: _isHovered
                        ? (widget.isDark
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade50)
                        : null,
                  ),
                  onHover: (hovering) {
                    setState(() {
                      _isHovered = hovering;
                    });
                  },
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// Custom animated outline button
class AnimatedOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Duration delay;

  const AnimatedOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<AnimatedOutlineButton> createState() => _AnimatedOutlineButtonState();
}

class _AnimatedOutlineButtonState extends State<AnimatedOutlineButton> {
  bool _isVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isHovered ? Colors.blue : Colors.grey.shade400,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isHovered
                  ? Colors.blue.withOpacity(0.05)
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 14,
                color: _isHovered ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
