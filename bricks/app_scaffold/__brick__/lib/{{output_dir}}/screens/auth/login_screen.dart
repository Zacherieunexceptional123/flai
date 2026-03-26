import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers/auth_provider.dart';

/// A sign-in screen with email and password fields.
///
/// Calls [AuthProvider.signIn] when the user taps the login button.
/// Provides navigation links to the register and forgot-password screens.
///
/// ```dart
/// FlaiLoginScreen(
///   authProvider: myAuthProvider,
///   onNavigateToRegister: () => context.go('/register'),
///   onNavigateToForgotPassword: () => context.go('/forgot-password'),
///   onLoginSuccess: () => context.go('/chats'),
/// )
/// ```
class FlaiLoginScreen extends StatefulWidget {
  /// The auth provider to call on sign-in.
  final AuthProvider authProvider;

  /// Called when the user taps "Don't have an account?".
  final VoidCallback? onNavigateToRegister;

  /// Called when the user taps "Forgot password?".
  final VoidCallback? onNavigateToForgotPassword;

  /// Called after a successful login.
  final VoidCallback? onLoginSuccess;

  const FlaiLoginScreen({
    super.key,
    required this.authProvider,
    this.onNavigateToRegister,
    this.onNavigateToForgotPassword,
    this.onLoginSuccess,
  });

  @override
  State<FlaiLoginScreen> createState() => _FlaiLoginScreenState();
}

class _FlaiLoginScreenState extends State<FlaiLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onLoginSuccess?.call();
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
                      'Welcome back',
                      style: theme.typography.headingLarge(
                        color: theme.colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      'Sign in to continue',
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
                      hintText: 'Enter your password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      theme: theme,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                        return null;
                      },
                    ),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: theme.spacing.sm),
                        child: GestureDetector(
                          onTap: widget.onNavigateToForgotPassword,
                          child: Text(
                            'Forgot password?',
                            style: theme.typography.bodySmall(
                              color: theme.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: theme.spacing.lg),

                    // Login button
                    _FlaiPrimaryButton(
                      label: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      theme: theme,
                    ),
                    SizedBox(height: theme.spacing.lg),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.typography.bodySmall(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Sign Up',
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
// Shared form widgets (private to this file, duplicated in sister screens)
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
