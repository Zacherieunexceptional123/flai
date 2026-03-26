import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// A selectable AI model option with metadata.
class FlaiModelOption {
  /// Unique identifier for the model.
  final String id;

  /// Display name of the model.
  final String name;

  /// Optional description of the model's strengths or purpose.
  final String? description;

  /// The provider name (e.g. "OpenAI", "Anthropic").
  final String? provider;

  /// Maximum context window size in tokens.
  final int? contextWindow;

  /// List of capability tags (e.g. "vision", "function calling").
  final List<String> capabilities;

  const FlaiModelOption({
    required this.id,
    required this.name,
    this.description,
    this.provider,
    this.contextWindow,
    this.capabilities = const [],
  });
}

/// A compact chip that shows the currently selected model and opens a bottom
/// sheet to pick a different one.
class FlaiModelSelector extends StatelessWidget {
  /// All available models.
  final List<FlaiModelOption> models;

  /// The id of the currently selected model.
  final String? selectedModelId;

  /// Called when the user picks a model from the bottom sheet.
  final void Function(FlaiModelOption)? onSelect;

  const FlaiModelSelector({
    super.key,
    required this.models,
    this.selectedModelId,
    this.onSelect,
  });

  FlaiModelOption? get _selected {
    if (selectedModelId == null) return null;
    try {
      return models.firstWhere((m) => m.id == selectedModelId);
    } catch (_) {
      return null;
    }
  }

  void _openSheet(BuildContext context) {
    final theme = FlaiTheme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.radius.xl),
        ),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      builder: (sheetContext) {
        return _ModelSheet(
          models: models,
          selectedModelId: selectedModelId,
          theme: theme,
          onSelect: (model) {
            Navigator.of(sheetContext).pop();
            onSelect?.call(model);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final selected = _selected;

    return GestureDetector(
      onTap: models.isNotEmpty ? () => _openSheet(context) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm + 2,
          vertical: theme.spacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(theme.radius.full),
          border: Border.all(
            color: theme.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: theme.colors.foreground,
            ),
            SizedBox(width: theme.spacing.xs),
            Text(
              selected?.name ?? 'Select model',
              style: theme.typography.bodySmall(
                color: theme.colors.foreground,
              ),
            ),
            SizedBox(width: theme.spacing.xs),
            Icon(
              Icons.unfold_more,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet content
// ---------------------------------------------------------------------------

class _ModelSheet extends StatelessWidget {
  final List<FlaiModelOption> models;
  final String? selectedModelId;
  final FlaiThemeData theme;
  final void Function(FlaiModelOption) onSelect;

  const _ModelSheet({
    required this.models,
    required this.selectedModelId,
    required this.theme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: theme.spacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Model',
                style: theme.typography.heading(
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ),

          Divider(
            height: 1,
            color: theme.colors.border.withValues(alpha: 0.4),
          ),

          // Model list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
              itemCount: models.length,
              itemBuilder: (context, index) {
                final model = models[index];
                final isSelected = model.id == selectedModelId;

                return _ModelRow(
                  model: model,
                  isSelected: isSelected,
                  theme: theme,
                  onTap: () => onSelect(model),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model row
// ---------------------------------------------------------------------------

class _ModelRow extends StatelessWidget {
  final FlaiModelOption model;
  final bool isSelected;
  final FlaiThemeData theme;
  final VoidCallback onTap;

  const _ModelRow({
    required this.model,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? theme.colors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected indicator
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.mutedForeground,
              ),
            ),
            SizedBox(width: theme.spacing.sm),

            // Model info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + provider badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.name,
                          style: theme.typography.bodyBase(
                            color: isSelected
                                ? theme.colors.primary
                                : theme.colors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (model.provider != null) ...[
                        SizedBox(width: theme.spacing.sm),
                        _ProviderBadge(
                          provider: model.provider!,
                          theme: theme,
                        ),
                      ],
                    ],
                  ),

                  // Description
                  if (model.description != null) ...[
                    SizedBox(height: theme.spacing.xs / 2),
                    Text(
                      model.description!,
                      style: theme.typography.bodySmall(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Context window + capabilities
                  if (model.contextWindow != null ||
                      model.capabilities.isNotEmpty) ...[
                    SizedBox(height: theme.spacing.xs),
                    Wrap(
                      spacing: theme.spacing.xs,
                      runSpacing: theme.spacing.xs,
                      children: [
                        if (model.contextWindow != null)
                          _InfoTag(
                            label: '${_formatContextWindow(model.contextWindow!)} ctx',
                            theme: theme,
                          ),
                        ...model.capabilities.map(
                          (cap) => _InfoTag(label: cap, theme: theme),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider badge
// ---------------------------------------------------------------------------

class _ProviderBadge extends StatelessWidget {
  final String provider;
  final FlaiThemeData theme;

  const _ProviderBadge({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(theme.radius.sm),
      ),
      child: Text(
        provider,
        style: theme.typography.bodySmall(
          color: theme.colors.accent,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info tag (capability / context window)
// ---------------------------------------------------------------------------

class _InfoTag extends StatelessWidget {
  final String label;
  final FlaiThemeData theme;

  const _InfoTag({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(theme.radius.sm),
        border: Border.all(
          color: theme.colors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: theme.typography.bodySmall(
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatContextWindow(int tokens) {
  if (tokens >= 1000000) {
    final value = tokens / 1000000;
    return value == value.truncateToDouble()
        ? '${value.toInt()}M'
        : '${value.toStringAsFixed(1)}M';
  }
  if (tokens >= 1000) {
    final value = tokens / 1000;
    return value == value.truncateToDouble()
        ? '${value.toInt()}K'
        : '${value.toStringAsFixed(1)}K';
  }
  return '$tokens';
}
