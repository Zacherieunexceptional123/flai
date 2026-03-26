import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// An expandable panel that shows the AI's reasoning/thinking process.
///
/// When [isThinking] is true the label pulses with a shimmer animation to
/// indicate work in progress. Tapping the header toggles between a collapsed
/// state (label + chevron) and an expanded state that reveals the full thinking
/// text in a muted, mono-styled container.
class FlaiThinkingIndicator extends StatefulWidget {
  /// The raw thinking/reasoning text produced by the model.
  final String thinkingText;

  /// Whether the model is still actively thinking. When true, the label
  /// animates with a pulsing shimmer effect.
  final bool isThinking;

  /// Display label shown in the header row.
  final String label;

  /// If true the panel starts in the expanded state.
  final bool initiallyExpanded;

  const FlaiThinkingIndicator({
    super.key,
    required this.thinkingText,
    this.isThinking = false,
    this.label = 'Thinking...',
    this.initiallyExpanded = false,
  });

  @override
  State<FlaiThinkingIndicator> createState() => _FlaiThinkingIndicatorState();
}

class _FlaiThinkingIndicatorState extends State<FlaiThinkingIndicator>
    with TickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;

    // Expand / collapse animation
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );
    if (_expanded) _expandController.value = 1.0;

    // Shimmer / pulse animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    if (widget.isThinking) _shimmerController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FlaiThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !oldWidget.isThinking) {
      _shimmerController.repeat(reverse: true);
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _shimmerController.stop();
      _shimmerController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: EdgeInsets.all(theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  size: 14,
                  color: theme.colors.mutedForeground,
                ),
                SizedBox(width: theme.spacing.xs),
                FadeTransition(
                  opacity: widget.isThinking
                      ? _shimmerAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Text(
                    widget.label,
                    style: theme.typography.bodySmall(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
                if (widget.isThinking) ...[
                  SizedBox(width: theme.spacing.sm),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colors.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const Spacer(),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),

            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: EdgeInsets.only(top: theme.spacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(theme.spacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(theme.radius.sm),
                  ),
                  child: Text(
                    widget.thinkingText,
                    style: theme.typography.mono(
                      color: theme.colors.mutedForeground,
                      fontSize: 11,
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
