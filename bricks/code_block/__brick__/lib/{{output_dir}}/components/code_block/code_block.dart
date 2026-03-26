import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/flai_theme.dart';

/// A styled code block with a language label, optional line numbers, horizontal
/// scrolling, and a copy-to-clipboard button.
///
/// Uses mono font styling from the FlaiTheme system and a muted background to
/// visually distinguish code from surrounding content.
class FlaiCodeBlock extends StatelessWidget {
  /// The source code to display.
  final String code;

  /// Optional language identifier shown in the header (e.g. "dart", "json").
  final String? language;

  /// Whether to show line numbers in the gutter.
  final bool showLineNumbers;

  /// Called after the code is copied to the clipboard. If null, the default
  /// copy behavior still runs but no callback fires.
  final VoidCallback? onCopy;

  const FlaiCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          _Header(
            language: language,
            theme: theme,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: code));
              onCopy?.call();
            },
          ),

          // Divider
          Container(height: 1, color: theme.colors.border),

          // Code body
          _CodeBody(
            code: code,
            showLineNumbers: showLineNumbers,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header with language label and copy button
// ---------------------------------------------------------------------------

class _Header extends StatefulWidget {
  final String? language;
  final FlaiThemeData theme;
  final VoidCallback onCopy;

  const _Header({
    required this.language,
    required this.theme,
    required this.onCopy,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _copied = false;

  void _handleCopy() {
    widget.onCopy();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        children: [
          if (widget.language != null)
            Text(
              widget.language!,
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _handleCopy,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 14,
                  color: _copied
                      ? const Color(0xFF4ADE80)
                      : theme.colors.mutedForeground,
                ),
                SizedBox(width: theme.spacing.xs),
                Text(
                  _copied ? 'Copied' : 'Copy',
                  style: theme.typography.bodySmall(
                    color: _copied
                        ? const Color(0xFF4ADE80)
                        : theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Code body with optional line numbers
// ---------------------------------------------------------------------------

class _CodeBody extends StatelessWidget {
  final String code;
  final bool showLineNumbers;
  final FlaiThemeData theme;

  const _CodeBody({
    required this.code,
    required this.showLineNumbers,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    final lineNumberWidth = lines.length.toString().length;

    return Padding(
      padding: EdgeInsets.all(theme.spacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: showLineNumbers
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: lineNumberWidth * 8.0 + theme.spacing.md,
                        child: Text(
                          '${index + 1}'.padLeft(lineNumberWidth),
                          style: theme.typography.mono(
                            color: theme.colors.mutedForeground
                                .withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        lines[index],
                        style: theme.typography.mono(
                          color: theme.colors.foreground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }),
              )
            : Text(
                code,
                style: theme.typography.mono(
                  color: theme.colors.foreground,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}
