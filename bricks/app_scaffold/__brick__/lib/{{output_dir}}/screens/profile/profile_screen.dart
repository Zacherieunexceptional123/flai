import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers/auth_provider.dart';

/// A profile screen displaying user info with options to edit and sign out.
///
/// Shows the user's avatar, display name, and email. Provides callbacks for
/// editing the profile and signing out.
///
/// ```dart
/// FlaiProfileScreen(
///   user: currentUser,
///   onEditProfile: () => showEditDialog(),
///   onSignOut: () => authProvider.signOut(),
///   onBack: () => context.go('/chats'),
/// )
/// ```
class FlaiProfileScreen extends StatelessWidget {
  /// The currently signed-in user.
  final AppUser user;

  /// Called when the user taps "Edit Profile".
  final VoidCallback? onEditProfile;

  /// Called when the user taps "Sign Out".
  final VoidCallback? onSignOut;

  /// Called when the user taps the back button.
  final VoidCallback? onBack;

  const FlaiProfileScreen({
    super.key,
    required this.user,
    this.onEditProfile,
    this.onSignOut,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          // App bar
          _ProfileAppBar(theme: theme, onBack: onBack),

          // Profile content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.lg),
              child: Column(
                children: [
                  // Avatar
                  _Avatar(user: user, theme: theme),
                  SizedBox(height: theme.spacing.md),

                  // Display name
                  Text(
                    user.displayName ?? 'User',
                    style: theme.typography.headingLarge(
                      color: theme.colors.foreground,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),

                  // Email
                  Text(
                    user.email,
                    style: theme.typography.bodyBase(
                      color: theme.colors.mutedForeground,
                    ),
                  ),

                  // Member since
                  if (user.createdAt != null) ...[
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      'Member since ${_formatDate(user.createdAt!)}',
                      style: theme.typography.bodySmall(
                        color: theme.colors.mutedForeground
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  SizedBox(height: theme.spacing.xl),

                  // Actions
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Edit profile button
                        _ProfileAction(
                          icon: theme.icons.citation,
                          label: 'Edit Profile',
                          theme: theme,
                          onTap: onEditProfile,
                        ),
                        SizedBox(height: theme.spacing.sm),

                        // Sign out button
                        _ProfileAction(
                          icon: theme.icons.close,
                          label: 'Sign Out',
                          isDestructive: true,
                          theme: theme,
                          onTap: onSignOut,
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

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _ProfileAppBar extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback? onBack;

  const _ProfileAppBar({required this.theme, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + theme.spacing.sm,
        left: theme.spacing.xs,
        right: theme.spacing.md,
        bottom: theme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          bottom: BorderSide(color: theme.colors.border),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.sm),
              child: Icon(
                theme.icons.collapse,
                size: 22,
                color: theme.colors.foreground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Profile',
              style: theme.typography.heading(
                color: theme.colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final AppUser user;
  final FlaiThemeData theme;

  const _Avatar({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(user.displayName ?? user.email);

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.colors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsAvatar(
                  initials: initials,
                  theme: theme,
                ),
              ),
            )
          : _InitialsAvatar(initials: initials, theme: theme),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final FlaiThemeData theme;

  const _InitialsAvatar({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: theme.typography.headingLarge(
          color: theme.colors.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile action button
// ---------------------------------------------------------------------------

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final FlaiThemeData theme;
  final VoidCallback? onTap;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.theme,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? theme.colors.destructive : theme.colors.foreground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(
            color: isDestructive
                ? theme.colors.destructive.withValues(alpha: 0.3)
                : theme.colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: theme.spacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.typography.bodyBase(color: color),
              ),
            ),
            Icon(
              theme.icons.expand,
              size: 18,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}
