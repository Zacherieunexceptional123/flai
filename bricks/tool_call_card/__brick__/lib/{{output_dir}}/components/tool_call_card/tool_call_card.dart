import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/flai_theme.dart';

/// A card that displays an AI tool/function call with its name, arguments,
/// result, and loading state.
///
/// Shows a wrench icon and tool name in the header, parsed JSON arguments in a
/// mono-font container, and the result once available. Displays a loading
/// spinner while the tool call is still in progress.
class FlaiToolCallCard extends StatelessWidget {
  /// The tool call data to display.
  final ToolCall toolCall;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  const FlaiToolCallCard({
    super.key,
    required this.toolCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(color: theme.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: icon + tool name + status
            _Header(toolCall: toolCall, theme: theme),

            // Arguments section
            if (toolCall.arguments.isNotEmpty)
              _ArgumentsSection(arguments: toolCall.arguments, theme: theme),

            // Result section
            if (toolCall.result != null)
              _ResultSection(result: toolCall.result!, theme: theme),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final ToolCall toolCall;
  final FlaiThemeData theme;

  const _Header({required this.toolCall, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.build_rounded,
            size: 14,
            color: theme.colors.mutedForeground,
          ),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Text(
              toolCall.name,
              style: theme.typography.mono(
                color: theme.colors.cardForeground,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (toolCall.isComplete)
            Icon(
              Icons.check_circle,
              size: 14,
              color: const Color(0xFF4ADE80),
            )
          else
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arguments section
// ---------------------------------------------------------------------------

class _ArgumentsSection extends StatelessWidget {
  final String arguments;
  final FlaiThemeData theme;

  const _ArgumentsSection({
    required this.arguments,
    required this.theme,
  });

  String _formatArguments() {
    try {
      final parsed = json.decode(arguments);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsed);
    } catch (_) {
      return arguments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(theme.radius.sm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          _formatArguments(),
          style: theme.typography.mono(
            color: theme.colors.mutedForeground,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result section
// ---------------------------------------------------------------------------

class _ResultSection extends StatelessWidget {
  final String result;
  final FlaiThemeData theme;

  const _ResultSection({
    required this.result,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(theme.spacing.sm),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(theme.radius.sm),
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result',
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              result,
              style: theme.typography.mono(
                color: theme.colors.cardForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
