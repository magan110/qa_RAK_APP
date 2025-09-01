import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/theme.dart';
import '../widgets/custom_back_button.dart';

class LoginScreenWithOtp extends StatefulWidget {
  const LoginScreenWithOtp({super.key});

  @override
  State<LoginScreenWithOtp> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenWithOtp>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtpField = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set default values for testing
    _mobileController.text = '501234567';
    _otpController.text = '123456';

    // Initialize animations
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Back button - only show if we can go back
            if (Navigator.of(context).canPop())
              const Positioned(top: 50, left: 20, child: CustomBackButton()),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.blue.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 400,
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // RAK Logo with animation
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.asset(
                                            'assets/images/rak_logo.jpg',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.business,
                                                    size: 40,
                                                    color: Colors.blue,
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Animated title
                              TweenAnimationBuilder<double>(
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
                                  'Welcome Back',
                                  style: AppTheme.headline.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Animated subtitle
                              TweenAnimationBuilder<double>(
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
                                child: const Text(
                                  'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Mobile number field with animation
                              AnimatedTextField(
                                controller: _mobileController,
                                labelText: 'Mobile Number',
                                hintText: '50XXXXXXX',
                                prefixText: '+971 ',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  if (!RegExp(
                                    r'^[50|52|54|55|56|58]\d{7}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter valid UAE mobile number';
                                  }
                                  return null;
                                },
                                delay: const Duration(milliseconds: 300),
                              ),

                              const SizedBox(height: 20),

                              // OTP field with animation (only after Get OTP is pressed)
                              if (_showOtpField)
                                AnimatedTextField(
                                  controller: _otpController,
                                  labelText: 'OTP',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter OTP';
                                    }
                                    return null;
                                  },
                                  delay: const Duration(milliseconds: 450),
                                ),

                              const SizedBox(height: 32),

                              // Get OTP button with animation
                              if (!_showOtpField)
                                AnimatedButton(
                                  text: 'Get OTP',
                                  isLoading: _isLoading,
                                  onPressed: () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    // Simulate API call
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );

                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                        _showOtpField = true;
                                      });
                                    }
                                  },
                                  delay: const Duration(milliseconds: 750),
                                  textColor: Colors.white,
                                ),

                              // Login button with animation (after OTP is shown)
                              if (_showOtpField)
                                AnimatedButton(
                                  text: 'Login',
                                  isLoading: _isLoading,
                                  onPressed: () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    // Simulate API call
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );

                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });

                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/approval-dashboard',
                                      );
                                    }
                                  },
                                  delay: const Duration(milliseconds: 750),
                                  textColor: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

// Custom animated checkbox
class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final Function(bool?)? onChanged;
  final Duration delay;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.delay,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox> {
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
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.value ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: widget.value ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              width: 24,
              height: 24,
              child: widget.value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => widget.onChanged?.call(!widget.value),
              child: const Text(
                'Employee Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
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
              shadowColor: Colors.blue.withValues(alpha: 0.3),
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
                  ? Colors.blue.withValues(alpha: 0.05)
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
