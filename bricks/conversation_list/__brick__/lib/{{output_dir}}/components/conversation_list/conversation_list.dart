import 'package:flutter/material.dart';

import '../../core/models/conversation.dart';
import '../../core/theme/flai_theme.dart';

/// A scrollable list of past conversations with search filtering, selection
/// highlighting, swipe-to-delete, and an empty state.
class FlaiConversationList extends StatefulWidget {
  /// The conversations to display.
  final List<Conversation> conversations;

  /// The currently selected conversation id, if any.
  final String? selectedId;

  /// Called when a conversation is tapped.
  final void Function(Conversation)? onSelect;

  /// Called when a conversation is swiped away.
  final void Function(Conversation)? onDelete;

  /// Called when the "New Conversation" button is tapped.
  final VoidCallback? onCreate;

  /// Placeholder text shown in the search bar.
  final String searchPlaceholder;

  const FlaiConversationList({
    super.key,
    required this.conversations,
    this.selectedId,
    this.onSelect,
    this.onDelete,
    this.onCreate,
    this.searchPlaceholder = 'Search conversations...',
  });

  @override
  State<FlaiConversationList> createState() => _FlaiConversationListState();
}

class _FlaiConversationListState extends State<FlaiConversationList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> get _filtered {
    if (_query.isEmpty) return widget.conversations;
    final lower = _query.toLowerCase();
    return widget.conversations.where((c) {
      return c.displayTitle.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final filtered = _filtered;

    return Column(
      children: [
        // Search bar
        _SearchBar(
          controller: _searchController,
          placeholder: widget.searchPlaceholder,
          theme: theme,
          onChanged: (value) => setState(() => _query = value),
        ),

        // New conversation button
        if (widget.onCreate != null) ...[
          _NewConversationButton(theme: theme, onTap: widget.onCreate!),
          Divider(
            height: 1,
            color: theme.colors.border.withValues(alpha: 0.4),
          ),
        ],

        // List or empty state
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  theme: theme,
                  hasSearch: _query.isNotEmpty,
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: theme.spacing.md,
                    endIndent: theme.spacing.md,
                    color: theme.colors.border.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final isSelected = conversation.id == widget.selectedId;

                    return _ConversationTile(
                      conversation: conversation,
                      isSelected: isSelected,
                      theme: theme,
                      onTap: widget.onSelect != null
                          ? () => widget.onSelect!(conversation)
                          : null,
                      onDismissed: widget.onDelete != null
                          ? () => widget.onDelete!(conversation)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final FlaiThemeData theme;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.placeholder,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(theme.spacing.sm),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.typography.bodyBase(color: theme.colors.foreground),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: theme.typography.bodyBase(
            color: theme.colors.mutedForeground,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colors.mutedForeground,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colors.mutedForeground,
                  ),
                )
              : null,
          filled: true,
          fillColor: theme.colors.input,
          contentPadding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New conversation button
// ---------------------------------------------------------------------------

class _NewConversationButton extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback onTap;

  const _NewConversationButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 2,
        ),
        margin: EdgeInsets.only(
          left: theme.spacing.sm,
          right: theme.spacing.sm,
          bottom: theme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colors.primary,
          borderRadius: BorderRadius.circular(theme.radius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: theme.colors.primaryForeground,
            ),
            SizedBox(width: theme.spacing.xs),
            Text(
              'New Conversation',
              style: theme.typography.bodyBase(
                color: theme.colors.primaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final FlaiThemeData theme;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.theme,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? theme.colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 2,
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(theme.radius.full),
              ),
            ),
            SizedBox(width: theme.spacing.sm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayTitle,
                    style: theme.typography.bodyBase(
                      color: isSelected
                          ? theme.colors.primary
                          : theme.colors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: theme.spacing.xs / 2),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(conversation.updatedAt),
                        style: theme.typography.bodySmall(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      if (conversation.model != null) ...[
                        SizedBox(width: theme.spacing.sm),
                        Text(
                          conversation.model!,
                          style: theme.typography.bodySmall(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Message count badge
            if (conversation.messageCount > 0) ...[
              SizedBox(width: theme.spacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.sm,
                  vertical: theme.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
                child: Text(
                  '${conversation.messageCount}',
                  style: theme.typography.bodySmall(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onDismissed == null) return tile;

    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: theme.spacing.lg),
        color: theme.colors.destructive,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: tile,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final FlaiThemeData theme;
  final bool hasSearch;

  const _EmptyState({required this.theme, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.chat_bubble_outline,
              size: 40,
              color: theme.colors.mutedForeground.withValues(alpha: 0.5),
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              hasSearch ? 'No matching conversations' : 'No conversations yet',
              style: theme.typography.bodyBase(
                color: theme.colors.mutedForeground,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Start a new conversation to get going',
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground.withValues(alpha: 0.7),
              ),
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

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final daysDiff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(dt.year, dt.month, dt.day))
      .inDays;

  if (daysDiff == 1) return 'Yesterday';
  if (daysDiff < 7) return '${daysDiff}d ago';

  final month = _monthName(dt.month);
  return '$month ${dt.day}';
}

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
}
