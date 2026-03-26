import 'brick_registry.dart';

/// Resolves the full, ordered dependency graph for a component.
///
/// Given a component [name], returns a list of all components that must be
/// installed (dependencies first, then the component itself), excluding any
/// components listed in [alreadyInstalled].
///
/// Throws [ArgumentError] if the component or any transitive dependency is not
/// found in the [BrickRegistry].
class DependencyResolver {
  const DependencyResolver();

  /// Returns an ordered installation list for [componentName].
  ///
  /// The list is topologically sorted so that dependencies appear before the
  /// components that need them. Components already present in
  /// [alreadyInstalled] are excluded from the result.
  List<String> resolve(
    String componentName, {
    Set<String> alreadyInstalled = const {},
  }) {
    final brick = BrickRegistry.lookup(componentName);
    if (brick == null) {
      throw ArgumentError('Unknown component: $componentName');
    }

    final ordered = <String>[];
    final visited = <String>{};

    void visit(String name) {
      if (visited.contains(name)) return;
      visited.add(name);

      final info = BrickRegistry.lookup(name);
      if (info == null) {
        throw ArgumentError(
          'Unknown dependency "$name" referenced by the dependency graph.',
        );
      }

      for (final dep in info.dependencies) {
        visit(dep);
      }

      if (!alreadyInstalled.contains(name)) {
        ordered.add(name);
      }
    }

    visit(componentName);
    return ordered;
  }

  /// Collects all pub.dev dependencies required by [componentNames].
  ///
  /// Returns a deduplicated list of package names.
  List<String> collectPubDependencies(List<String> componentNames) {
    final deps = <String>{};
    for (final name in componentNames) {
      final brick = BrickRegistry.lookup(name);
      if (brick != null) {
        deps.addAll(brick.pubDependencies);
      }
    }
    return deps.toList(growable: false);
  }
}
