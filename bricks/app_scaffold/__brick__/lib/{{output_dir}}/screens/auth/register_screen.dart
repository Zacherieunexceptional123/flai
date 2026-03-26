import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers/auth_provider.dart';

/// A registration screen with name, email, password, and confirm password
/// fields.
///
/// Calls [AuthProvider.signUp] when the user taps the register button.
/// Provides a navigation link back to the login screen.
///
/// ```dart
/// FlaiRegisterScreen(
///   authProvider: myAuthProvider,
///   onNavigateToLogin: () => context.go('/login'),
///   onRegisterSuccess: () => context.go('/chats'),
/// )
/// ```
class FlaiRegisterScreen extends StatefulWidget {
  /// The auth provider to call on sign-up.
  final AuthProvider authProvider;

  /// Called when the user taps "Already have an account?".
  final VoidCallback? onNavigateToLogin;

  /// Called after a successful registration.
  final VoidCallback? onRegisterSuccess;

  const FlaiRegisterScreen({
    super.key,
    required this.authProvider,
    this.onNavigateToLogin,
    this.onRegisterSuccess,
  });

  @override
  State<FlaiRegisterScreen> createState() => _FlaiRegisterScreenState();
}

class _FlaiRegisterScreenState extends State<FlaiRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authProvider.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onRegisterSuccess?.call();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Icon(
                      theme.icons.chat,
                      size: 48,
                      color: theme.colors.primary,
                    ),
                    SizedBox(height: theme.spacing.md),
                    Text(
                      'Create account',
                      style: theme.typography.headingLarge(
                        color: theme.colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      'Get started with your AI assistant',
                      style: theme.typography.bodyBase(
                        color: theme.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: theme.spacing.xl),

                    // Error message
                    if (_errorMessage != null) ...[
                      _ErrorBanner(
                        message: _errorMessage!,
                        theme: theme,
                      ),
                      SizedBox(height: theme.spacing.md),
                    ],

                    // Name field
                    _FlaiTextField(
                      controller: _nameController,
                      label: 'Name',
                      hintText: 'Your name',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      theme: theme,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: theme.spacing.md),

                    // Email field
                    _FlaiTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      theme: theme,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: theme.spacing.md),

                    // Password field
                    _FlaiTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'At least 8 characters',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      theme: theme,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? theme.icons.expand
                              : theme.icons.collapse,
                          size: 20,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: theme.spacing.md),

                    // Confirm password field
                    _FlaiTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hintText: 'Re-enter your password',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      theme: theme,
                      onFieldSubmitted: (_) => _handleRegister(),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? theme.icons.expand
                              : theme.icons.collapse,
                          size: 20,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: theme.spacing.lg),

                    // Register button
                    _FlaiPrimaryButton(
                      label: 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                      theme: theme,
                    ),
                    SizedBox(height: theme.spacing.lg),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.typography.bodySmall(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: Text(
                            'Sign In',
                            style: theme.typography.bodySmall(
                              color: theme.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form widgets
// ---------------------------------------------------------------------------

class _FlaiTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FlaiThemeData theme;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _FlaiTextField({
    required this.controller,
    required this.label,
    required this.theme,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.bodySmall(
            color: theme.colors.foreground,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: theme.typography.bodyBase(color: theme.colors.foreground),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.typography.bodyBase(
              color: theme.colors.mutedForeground,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.colors.input,
            contentPadding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.sm + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.radius.md),
              borderSide: BorderSide(color: theme.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.radius.md),
              borderSide: BorderSide(color: theme.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.radius.md),
              borderSide: BorderSide(color: theme.colors.ring, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.radius.md),
              borderSide: BorderSide(color: theme.colors.destructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.radius.md),
              borderSide:
                  BorderSide(color: theme.colors.destructive, width: 2),
            ),
            errorStyle: theme.typography.bodySmall(
              color: theme.colors.destructive,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlaiPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final FlaiThemeData theme;

  const _FlaiPrimaryButton({
    required this.label,
    required this.theme,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: theme.spacing.sm + 4),
        decoration: BoxDecoration(
          color: isLoading
              ? theme.colors.primary.withValues(alpha: 0.6)
              : theme.colors.primary,
          borderRadius: BorderRadius.circular(theme.radius.md),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colors.primaryForeground,
                  ),
                )
              : Text(
                  label,
                  style: theme.typography.bodyBase(
                    color: theme.colors.primaryForeground,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final FlaiThemeData theme;

  const _ErrorBanner({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(
          color: theme.colors.destructive.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            theme.icons.error,
            size: 18,
            color: theme.colors.destructive,
          ),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.typography.bodySmall(
                color: theme.colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
