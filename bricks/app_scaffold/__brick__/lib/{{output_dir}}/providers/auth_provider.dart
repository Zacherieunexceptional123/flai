import 'dart:async';

/// Represents a user in the application.
class AppUser {
  /// Unique identifier for the user.
  final String id;

  /// User's email address.
  final String email;

  /// User's display name.
  final String? displayName;

  /// URL to the user's avatar image.
  final String? avatarUrl;

  /// When the user account was created.
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents the current authentication state of the application.
sealed class AuthState {
  const AuthState();
}

/// The user is authenticated and has an active session.
class Authenticated extends AuthState {
  /// The currently signed-in user.
  final AppUser user;

  const Authenticated(this.user);
}

/// The user is not authenticated.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication state is being determined (e.g., checking stored session).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Abstract authentication provider.
///
/// Implement this class to connect your preferred auth backend (Firebase,
/// Supabase, custom server, etc.). The app scaffold routes and screens
/// depend on this interface — no concrete implementation is included.
///
/// ```dart
/// class MyAuthProvider extends AuthProvider {
///   @override
///   Stream<AuthState> get authStateChanges => _controller.stream;
///   // ... implement remaining methods
/// }
/// ```
abstract class AuthProvider {
  /// A stream that emits the current [AuthState] whenever it changes.
  ///
  /// The app router listens to this stream to redirect between auth and
  /// main screens.
  Stream<AuthState> get authStateChanges;

  /// The current auth state (synchronous snapshot).
  AuthState get currentState;

  /// Sign in with email and password.
  ///
  /// Throws on failure (invalid credentials, network error, etc.).
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  ///
  /// Throws on failure (email already in use, weak password, etc.).
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password reset email to the given address.
  Future<void> resetPassword({required String email});

  /// Update the current user's profile information.
  Future<AppUser> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  /// Clean up resources.
  void dispose();
}
