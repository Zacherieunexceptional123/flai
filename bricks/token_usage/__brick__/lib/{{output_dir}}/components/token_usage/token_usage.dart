import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/flai_theme.dart';

/// Displays token usage statistics with optional cost estimation and a
/// progress bar showing utilisation against a maximum token limit.
class FlaiTokenUsage extends StatelessWidget {
  /// Token usage data (input, output, cache tokens, and total).
  final UsageInfo usage;

  /// Cost per input token in dollars. When provided, cost is displayed.
  final double? costPerInputToken;

  /// Cost per output token in dollars. When provided, cost is displayed.
  final double? costPerOutputToken;

  /// Maximum token limit. When provided, a progress bar is shown.
  final int? maxTokens;

  /// Whether to show the expanded breakdown view.
  final bool expanded;

  const FlaiTokenUsage({
    super.key,
    required this.usage,
    this.costPerInputToken,
    this.costPerOutputToken,
    this.maxTokens,
    this.expanded = false,
  });

  double? get _totalCost {
    if (costPerInputToken == null && costPerOutputToken == null) return null;
    final inputCost = (costPerInputToken ?? 0) * usage.inputTokens;
    final outputCost = (costPerOutputToken ?? 0) * usage.outputTokens;
    return inputCost + outputCost;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    if (!expanded) {
      return _CompactView(
        usage: usage,
        totalCost: _totalCost,
        theme: theme,
      );
    }

    return _ExpandedView(
      usage: usage,
      costPerInputToken: costPerInputToken,
      costPerOutputToken: costPerOutputToken,
      totalCost: _totalCost,
      maxTokens: maxTokens,
      theme: theme,
    );
  }
}

// ---------------------------------------------------------------------------
// Compact inline view: "↑ 1,234 ↓ 5,678"
// ---------------------------------------------------------------------------

class _CompactView extends StatelessWidget {
  final UsageInfo usage;
  final double? totalCost;
  final FlaiThemeData theme;

  const _CompactView({
    required this.usage,
    required this.totalCost,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input tokens
        Text(
          '\u2191 ${_formatNumber(usage.inputTokens)}',
          style: theme.typography.mono(
            color: theme.colors.mutedForeground,
            fontSize: 12,
          ),
        ),
        SizedBox(width: theme.spacing.sm),

        // Output tokens
        Text(
          '\u2193 ${_formatNumber(usage.outputTokens)}',
          style: theme.typography.mono(
            color: theme.colors.mutedForeground,
            fontSize: 12,
          ),
        ),

        // Cost
        if (totalCost != null) ...[
          SizedBox(width: theme.spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.xs + 2,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: theme.colors.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(theme.radius.sm),
            ),
            child: Text(
              _formatCost(totalCost!),
              style: theme.typography.mono(
                color: theme.colors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded breakdown view
// ---------------------------------------------------------------------------

class _ExpandedView extends StatelessWidget {
  final UsageInfo usage;
  final double? costPerInputToken;
  final double? costPerOutputToken;
  final double? totalCost;
  final int? maxTokens;
  final FlaiThemeData theme;

  const _ExpandedView({
    required this.usage,
    required this.costPerInputToken,
    required this.costPerOutputToken,
    required this.totalCost,
    required this.maxTokens,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Token Usage',
            style: theme.typography.bodyBase(
              color: theme.colors.foreground,
            ),
          ),
          SizedBox(height: theme.spacing.sm),

          // Progress bar
          if (maxTokens != null && maxTokens! > 0) ...[
            _ProgressBar(
              current: usage.totalTokens,
              max: maxTokens!,
              theme: theme,
            ),
            SizedBox(height: theme.spacing.sm),
          ],

          // Breakdown rows
          _BreakdownRow(
            label: 'Input',
            icon: '\u2191',
            tokens: usage.inputTokens,
            cost: costPerInputToken != null
                ? costPerInputToken! * usage.inputTokens
                : null,
            theme: theme,
          ),
          SizedBox(height: theme.spacing.xs),
          _BreakdownRow(
            label: 'Output',
            icon: '\u2193',
            tokens: usage.outputTokens,
            cost: costPerOutputToken != null
                ? costPerOutputToken! * usage.outputTokens
                : null,
            theme: theme,
          ),

          // Cache tokens
          if (usage.cacheReadTokens != null && usage.cacheReadTokens! > 0) ...[
            SizedBox(height: theme.spacing.xs),
            _BreakdownRow(
              label: 'Cache Read',
              icon: '\u21BB',
              tokens: usage.cacheReadTokens!,
              theme: theme,
            ),
          ],
          if (usage.cacheCreationTokens != null &&
              usage.cacheCreationTokens! > 0) ...[
            SizedBox(height: theme.spacing.xs),
            _BreakdownRow(
              label: 'Cache Write',
              icon: '\u21BA',
              tokens: usage.cacheCreationTokens!,
              theme: theme,
            ),
          ],

          // Divider + total
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
            child: Divider(
              height: 1,
              color: theme.colors.border.withValues(alpha: 0.4),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.typography.bodyBase(
                  color: theme.colors.foreground,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatNumber(usage.totalTokens),
                    style: theme.typography.mono(
                      color: theme.colors.foreground,
                      fontSize: 13,
                    ),
                  ),
                  if (totalCost != null) ...[
                    SizedBox(width: theme.spacing.sm),
                    Text(
                      _formatCost(totalCost!),
                      style: theme.typography.mono(
                        color: theme.colors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final FlaiThemeData theme;

  const _ProgressBar({
    required this.current,
    required this.max,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (current / max).clamp(0.0, 1.0);
    final percentage = (ratio * 100).toStringAsFixed(1);
    final isHigh = ratio > 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatNumber(current)} / ${_formatNumber(max)}',
              style: theme.typography.mono(
                color: theme.colors.mutedForeground,
                fontSize: 11,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.typography.mono(
                color: isHigh
                    ? theme.colors.destructive
                    : theme.colors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(theme.radius.full),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background track
                Container(
                  width: double.infinity,
                  color: theme.colors.muted,
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHigh
                          ? theme.colors.destructive
                          : theme.colors.primary,
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Breakdown row
// ---------------------------------------------------------------------------

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String icon;
  final int tokens;
  final double? cost;
  final FlaiThemeData theme;

  const _BreakdownRow({
    required this.label,
    required this.icon,
    required this.tokens,
    required this.theme,
    this.cost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: theme.typography.mono(
            color: theme.colors.mutedForeground,
            fontSize: 12,
          ),
        ),
        SizedBox(width: theme.spacing.xs),
        Text(
          label,
          style: theme.typography.bodySmall(
            color: theme.colors.mutedForeground,
          ),
        ),
        const Spacer(),
        Text(
          _formatNumber(tokens),
          style: theme.typography.mono(
            color: theme.colors.foreground,
            fontSize: 12,
          ),
        ),
        if (cost != null) ...[
          SizedBox(width: theme.spacing.sm),
          Text(
            _formatCost(cost!),
            style: theme.typography.mono(
              color: theme.colors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatNumber(int value) {
  if (value < 1000) return '$value';
  final str = value.toString();
  final buffer = StringBuffer();
  final remainder = str.length % 3;

  if (remainder > 0) {
    buffer.write(str.substring(0, remainder));
    if (str.length > remainder) buffer.write(',');
  }

  for (var i = remainder; i < str.length; i += 3) {
    buffer.write(str.substring(i, i + 3));
    if (i + 3 < str.length) buffer.write(',');
  }

  return buffer.toString();
}

String _formatCost(double cost) {
  if (cost < 0.0001) return '<\$0.0001';
  if (cost < 0.01) return '\$${cost.toStringAsFixed(4)}';
  if (cost < 1.0) return '\$${cost.toStringAsFixed(3)}';
  return '\$${cost.toStringAsFixed(2)}';
}
