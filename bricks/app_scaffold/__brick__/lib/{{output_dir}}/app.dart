import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/flai_theme.dart';

/// Root widget for the FlAI app scaffold.
///
/// Wraps [MaterialApp.router] with [FlaiTheme] so all descendants can access
/// the theme via `FlaiTheme.of(context)`. Accepts a pre-configured [GoRouter]
/// (created with [createAppRouter]) and a [FlaiThemeData] instance.
///
/// ```dart
/// runApp(
///   FlaiApp(
///     theme: FlaiThemeData.dark(),
///     router: createAppRouter(
///       authProvider: myAuthProvider,
///       loginBuilder: ...,
///       chatListBuilder: ...,
///       // ...
///     ),
///   ),
/// );
/// ```
class FlaiApp extends StatelessWidget {
  /// The FlAI theme data applied to the entire app.
  final FlaiThemeData theme;

  /// The [GoRouter] instance configured with app routes and auth redirects.
  final GoRouter router;

  /// Optional app title shown in the OS task switcher.
  final String title;

  const FlaiApp({
    super.key,
    required this.theme,
    required this.router,
    this.title = 'FlAI Chat',
  });

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: theme,
      child: MaterialApp.router(
        title: title,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(
          brightness: _brightness,
          scaffoldBackgroundColor: theme.colors.background,
          colorScheme: ColorScheme(
            brightness: _brightness,
            primary: theme.colors.primary,
            onPrimary: theme.colors.primaryForeground,
            secondary: theme.colors.secondary,
            onSecondary: theme.colors.secondaryForeground,
            error: theme.colors.destructive,
            onError: theme.colors.destructiveForeground,
            surface: theme.colors.card,
            onSurface: theme.colors.cardForeground,
          ),
        ),
      ),
    );
  }

  /// Infer brightness from the background luminance to set correct status
  /// bar icon color.
  Brightness get _brightness =>
      theme.colors.background.computeLuminance() > 0.5
          ? Brightness.light
          : Brightness.dark;
}
