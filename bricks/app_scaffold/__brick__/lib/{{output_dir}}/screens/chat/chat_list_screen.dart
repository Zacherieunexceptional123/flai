import 'package:flutter/material.dart';

import '../../core/models/conversation.dart';
import '../../core/theme/flai_theme.dart';
import '../../components/conversation_list/conversation_list.dart';

/// A screen showing the list of conversations with a navigation drawer.
///
/// Uses [FlaiConversationList] internally and provides a FAB to create new
/// conversations. The drawer offers navigation to Settings and Profile.
///
/// ```dart
/// FlaiChatListScreen(
///   conversations: myConversations,
///   onSelectConversation: (c) => context.go('/chats/${c.id}'),
///   onNewConversation: () => createNewChat(),
///   onNavigateToSettings: () => context.go('/settings'),
///   onNavigateToProfile: () => context.go('/profile'),
/// )
/// ```
class FlaiChatListScreen extends StatelessWidget {
  /// The list of conversations to display.
  final List<Conversation> conversations;

  /// The currently selected conversation id, if any.
  final String? selectedConversationId;

  /// Called when a conversation is tapped.
  final void Function(Conversation)? onSelectConversation;

  /// Called when a conversation is deleted.
  final void Function(Conversation)? onDeleteConversation;

  /// Called when the user wants to create a new conversation.
  final VoidCallback? onNewConversation;

  /// Called when the user taps Settings in the drawer.
  final VoidCallback? onNavigateToSettings;

  /// Called when the user taps Profile in the drawer.
  final VoidCallback? onNavigateToProfile;

  const FlaiChatListScreen({
    super.key,
    required this.conversations,
    this.selectedConversationId,
    this.onSelectConversation,
    this.onDeleteConversation,
    this.onNewConversation,
    this.onNavigateToSettings,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      drawer: _AppDrawer(
        theme: theme,
        onNavigateToSettings: onNavigateToSettings,
        onNavigateToProfile: onNavigateToProfile,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _AppBar(theme: theme),
      ),
      body: FlaiConversationList(
        conversations: conversations,
        selectedId: selectedConversationId,
        onSelect: onSelectConversation,
        onDelete: onDeleteConversation,
        onCreate: onNewConversation,
      ),
      floatingActionButton: onNewConversation != null
          ? _NewChatFab(theme: theme, onPressed: onNewConversation!)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  final FlaiThemeData theme;

  const _AppBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          bottom: BorderSide(color: theme.colors.border),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            // Menu button
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
                child: Icon(
                  theme.icons.chat,
                  size: 24,
                  color: theme.colors.foreground,
                ),
              ),
            ),

            // Title
            Expanded(
              child: Text(
                'Conversations',
                style: theme.typography.heading(
                  color: theme.colors.foreground,
                ),
              ),
            ),

            // Search button
            GestureDetector(
              onTap: () {
                // Search is handled by the conversation list's built-in search
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
                child: Icon(
                  theme.icons.search,
                  size: 22,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation drawer
// ---------------------------------------------------------------------------

class _AppDrawer extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToProfile;

  const _AppDrawer({
    required this.theme,
    this.onNavigateToSettings,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: theme.colors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer header
            Container(
              padding: EdgeInsets.all(theme.spacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    theme.icons.chat,
                    size: 32,
                    color: theme.colors.primary,
                  ),
                  SizedBox(height: theme.spacing.sm),
                  Text(
                    'FlAI',
                    style: theme.typography.heading(
                      color: theme.colors.foreground,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    'AI Chat Assistant',
                    style: theme.typography.bodySmall(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: theme.spacing.sm),

            // Navigation items
            _DrawerItem(
              icon: theme.icons.chat,
              label: 'Conversations',
              isActive: true,
              theme: theme,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: theme.icons.model,
              label: 'Settings',
              theme: theme,
              onTap: () {
                Navigator.of(context).pop();
                onNavigateToSettings?.call();
              },
            ),
            _DrawerItem(
              icon: theme.icons.citation,
              label: 'Profile',
              theme: theme,
              onTap: () {
                Navigator.of(context).pop();
                onNavigateToProfile?.call();
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: EdgeInsets.all(theme.spacing.md),
              child: Text(
                'Powered by FlAI',
                style: theme.typography.bodySmall(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final FlaiThemeData theme;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.theme,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: theme.spacing.xs / 2,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(theme.radius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.colors.primary
                  : theme.colors.mutedForeground,
            ),
            SizedBox(width: theme.spacing.sm),
            Text(
              label,
              style: theme.typography.bodyBase(
                color: isActive
                    ? theme.colors.primary
                    : theme.colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating action button
// ---------------------------------------------------------------------------

class _NewChatFab extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback onPressed;

  const _NewChatFab({required this.theme, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          borderRadius: BorderRadius.circular(theme.radius.lg),
          boxShadow: [
            BoxShadow(
              color: theme.colors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          theme.icons.add,
          size: 24,
          color: theme.colors.primaryForeground,
        ),
      ),
    );
  }
}
