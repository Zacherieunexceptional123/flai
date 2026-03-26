# Custom Theme Creation

FlAI uses an InheritedWidget-based theme system with semantic color tokens inspired by shadcn/ui. This guide covers creating custom themes, modifying presets, and building theme-aware widgets.

Docs: https://getflai.dev

## Built-in Presets

FlAI ships with four presets, each with its own icon style:

```dart
FlaiThemeData.light()    // Zinc light -- material rounded icons
FlaiThemeData.dark()     // Zinc dark -- material rounded icons
FlaiThemeData.ios()      // Apple Messages -- cupertino icons, larger radii
FlaiThemeData.premium()  // Linear-inspired -- sharp material icons, indigo accents
```

## FlaiThemeData Structure

`FlaiThemeData` composes five sub-systems: colors, icons, typography, radius, and spacing.

```dart
FlaiThemeData(
  colors: FlaiColors(...),
  icons: FlaiIconData.material(),   // or .cupertino(), .sharp()
  typography: FlaiTypography(...),
  radius: FlaiRadius(...),
  spacing: FlaiSpacing(...),
)
```

## Modifying a Preset with copyWith

The fastest way to create a branded theme is to start from a preset and override specific tokens:

```dart
import 'package:flutter/material.dart';
import 'flai/flai.dart';

// Emerald-accented dark theme with Cupertino icons
final emeraldDark = FlaiThemeData.dark().copyWith(
  colors: FlaiColors.dark().copyWith(
    primary: Color(0xFF10B981),
    primaryForeground: Color(0xFFFFFFFF),
    accent: Color(0xFF10B981),
    accentForeground: Color(0xFFFFFFFF),
    ring: Color(0xFF10B981),
    userBubble: Color(0xFF10B981),
    userBubbleForeground: Color(0xFFFFFFFF),
  ),
  icons: FlaiIconData.cupertino(),
);

// Use it:
FlaiTheme(
  data: emeraldDark,
  child: MaterialApp(...),
)
```

## Building a Theme from Scratch

For full control, construct `FlaiThemeData` directly with all five sub-systems:

### Slate Blue Dark Theme

```dart
final slateBlue = FlaiThemeData(
  colors: FlaiColors(
    // Surface colors
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF1E293B),
    cardForeground: Color(0xFFF8FAFC),
    popover: Color(0xFF1E293B),
    popoverForeground: Color(0xFFF8FAFC),

    // Brand colors
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF334155),
    secondaryForeground: Color(0xFFF8FAFC),

    // Neutral tones
    muted: Color(0xFF334155),
    mutedForeground: Color(0xFF94A3B8),
    accent: Color(0xFF3B82F6),
    accentForeground: Color(0xFFFFFFFF),

    // Semantic colors
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),

    // Borders and inputs
    border: Color(0xFF334155),
    input: Color(0xFF334155),
    ring: Color(0xFF3B82F6),

    // Chat-specific bubble colors
    userBubble: Color(0xFF3B82F6),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFF1E293B),
    assistantBubbleForeground: Color(0xFFF8FAFC),
  ),
  icons: FlaiIconData.sharp(),  // sharp icons for a modern look
  typography: FlaiTypography(
    fontFamily: 'Inter',
    monoFontFamily: 'Fira Code',
    sm: 12.0,
    base: 15.0,
    lg: 17.0,
    xl: 22.0,
    xxl: 28.0,
  ),
  radius: FlaiRadius(
    sm: 6,
    md: 10,
    lg: 16,
    xl: 20,
    full: 9999,
  ),
  spacing: FlaiSpacing(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  ),
);
```

### Warm Light Theme

```dart
final warmLight = FlaiThemeData(
  colors: FlaiColors(
    background: Color(0xFFFFFBEB),
    foreground: Color(0xFF1C1917),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF1C1917),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF1C1917),
    primary: Color(0xFFD97706),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFFEF3C7),
    secondaryForeground: Color(0xFF1C1917),
    muted: Color(0xFFFEF3C7),
    mutedForeground: Color(0xFF78716C),
    accent: Color(0xFFD97706),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFDC2626),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFFDE68A),
    input: Color(0xFFFDE68A),
    ring: Color(0xFFD97706),
    userBubble: Color(0xFFD97706),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFFFEF3C7),
    assistantBubbleForeground: Color(0xFF1C1917),
  ),
  icons: FlaiIconData.material(),  // rounded material icons
);
```

## FlaiIconData -- Semantic Icon System

FlAI provides 20 semantic icon fields so components never hardcode icon references. Three presets are available:

| Preset | Factory | Used By |
|---|---|---|
| Material Rounded | `FlaiIconData.material()` | light(), dark() |
| Apple Cupertino | `FlaiIconData.cupertino()` | ios() |
| Material Sharp | `FlaiIconData.sharp()` | premium() |

Override individual icons with `copyWith`:

```dart
final customIcons = FlaiIconData.material().copyWith(
  send: Icons.arrow_upward_rounded,
  chat: Icons.forum_rounded,
  thinking: Icons.lightbulb_outline_rounded,
);

final theme = FlaiThemeData.dark().copyWith(icons: customIcons);
```

**All icon fields:** toolCall, thinking, citation, image, brokenImage, code, copy, check, close, send, attach, search, delete, add, expand, collapse, chat, model, refresh, error

## Dynamic Theme Switching

```dart
class ThemedChatApp extends StatefulWidget {
  const ThemedChatApp({super.key});

  @override
  State<ThemedChatApp> createState() => _ThemedChatAppState();
}

class _ThemedChatAppState extends State<ThemedChatApp> {
  static final _themes = {
    'light': FlaiThemeData.light(),
    'dark': FlaiThemeData.dark(),
    'ios': FlaiThemeData.ios(),
    'premium': FlaiThemeData.premium(),
  };

  String _currentTheme = 'dark';

  FlaiThemeData get _themeData => _themes[_currentTheme]!;

  @override
  Widget build(BuildContext context) {
    final isDark = _currentTheme == 'dark' || _currentTheme == 'premium';

    return FlaiTheme(
      data: _themeData,
      child: MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Theme Demo'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (theme) => setState(() => _currentTheme = theme),
                itemBuilder: (_) => _themes.keys
                    .map((t) => PopupMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
            ],
          ),
          body: FlaiChatScreen(
            controller: _controller,
            title: 'AI Assistant',
          ),
        ),
      ),
    );
  }
}
```

## Using Theme Tokens in Custom Widgets

All FlAI widgets read their styling via `FlaiTheme.of(context)`. You can do the same in your own widgets:

```dart
class CustomHeader extends StatelessWidget {
  final String title;
  final String model;

  const CustomHeader({super.key, required this.title, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(
          bottom: BorderSide(color: theme.colors.border),
        ),
      ),
      child: Row(
        children: [
          // Avatar with accent color -- uses theme icons
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colors.primary,
            child: Icon(
              theme.icons.model,
              size: 18,
              color: theme.colors.primaryForeground,
            ),
          ),
          SizedBox(width: theme.spacing.sm),

          // Title and subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.bodyBase(
                  color: theme.colors.foreground,
                ),
              ),
              Text(
                model,
                style: theme.typography.bodySmall(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Token count badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.sm,
              vertical: theme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
            child: Text(
              '1.2k tokens',
              style: theme.typography.mono(
                color: theme.colors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Color Token Reference

| Token | Purpose |
|---|---|
| `background` | Page/screen background |
| `foreground` | Primary text color |
| `card` / `cardForeground` | Card surfaces and their text |
| `popover` / `popoverForeground` | Dropdown/modal surfaces |
| `primary` / `primaryForeground` | Brand color (buttons, links) |
| `secondary` / `secondaryForeground` | Secondary surfaces |
| `muted` / `mutedForeground` | Disabled/subtle elements |
| `accent` / `accentForeground` | Highlights, active states |
| `destructive` / `destructiveForeground` | Errors, delete actions |
| `border` | Borders and dividers |
| `input` | Input field borders |
| `ring` | Focus ring color |
| `userBubble` / `userBubbleForeground` | User message bubble |
| `assistantBubble` / `assistantBubbleForeground` | Assistant message bubble |
