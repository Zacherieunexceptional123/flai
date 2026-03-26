import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers/auth_provider.dart';

/// A screen for requesting a password reset email.
///
/// Calls [AuthProvider.resetPassword] and displays a success confirmation.
///
/// ```dart
/// FlaiForgotPasswordScreen(
///   authProvider: myAuthProvider,
///   onNavigateToLogin: () => context.go('/login'),
/// )
/// ```
class FlaiForgotPasswordScreen extends StatefulWidget {
  /// The auth provider to call for password reset.
  final AuthProvider authProvider;

  /// Called when the user taps "Back to login".
  final VoidCallback? onNavigateToLogin;

  const FlaiForgotPasswordScreen({
    super.key,
    required this.authProvider,
    this.onNavigateToLogin,
  });

  @override
  State<FlaiForgotPasswordScreen> createState() =>
      _FlaiForgotPasswordScreenState();
}

class _FlaiForgotPasswordScreenState extends State<FlaiForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authProvider.resetPassword(
        email: _emailController.text.trim(),
      );
      setState(() => _emailSent = true);
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
              child: _emailSent
                  ? _buildSuccessState(theme)
                  : _buildFormState(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(FlaiThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          theme.icons.check,
          size: 48,
          color: theme.colors.primary,
        ),
        SizedBox(height: theme.spacing.md),
        Text(
          'Check your email',
          style: theme.typography.headingLarge(
            color: theme.colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}',
          style: theme.typography.bodyBase(
            color: theme.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.xl),
        GestureDetector(
          onTap: widget.onNavigateToLogin,
          child: Text(
            'Back to login',
            style: theme.typography.bodyBase(
              color: theme.colors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFormState(FlaiThemeData theme) {
    return Form(
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
            'Reset password',
            style: theme.typography.headingLarge(
              color: theme.colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            'Enter your email and we\'ll send you a reset link',
            style: theme.typography.bodyBase(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: theme.spacing.xl),

          // Error message
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!, theme: theme),
            SizedBox(height: theme.spacing.md),
          ],

          // Email field
          _FlaiTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            theme: theme,
            onFieldSubmitted: (_) => _handleReset(),
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
          SizedBox(height: theme.spacing.lg),

          // Reset button
          _FlaiPrimaryButton(
            label: 'Send Reset Link',
            isLoading: _isLoading,
            onPressed: _handleReset,
            theme: theme,
          ),
          SizedBox(height: theme.spacing.lg),

          // Back to login link
          GestureDetector(
            onTap: widget.onNavigateToLogin,
            child: Text(
              'Back to login',
              style: theme.typography.bodySmall(
                color: theme.colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
