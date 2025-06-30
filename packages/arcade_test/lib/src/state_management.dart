// ignore_for_file: invalid_use_of_internal_member

import 'package:arcade/arcade.dart';

/// Manages global Arcade state for testing purposes.
///
/// This class provides utilities to reset all global state in Arcade
/// between tests to ensure test isolation.
class ArcadeTestState {
  const ArcadeTestState._();

  /// Resets all global Arcade state for clean testing.
  ///
  /// This method should be called before and after each test to ensure
  /// complete state isolation. It clears:
  /// - All registered routes
  /// - Global hooks (before, after, and WebSocket after hooks)
  /// - WebSocket connections and storage
  /// - Server state (static file serving flag)
  /// - Route caches and optimizations
  static void resetAll() {
    clearRoutes();
    clearGlobalHooks();
    clearWebSocketState();
    resetServerState();
    invalidateRouteCache();
  }

  /// Clears all registered routes and route building state.
  ///
  /// This removes all routes from the global routes list and resets
  /// the route group prefix and current processing route.
  static void clearRoutes() {
    routes.clear();
    routeGroupPrefix = '';
    currentProcessingRoute = null;
  }

  /// Clears all global hooks.
  ///
  /// This removes all globally registered hooks:
  /// - Before hooks that run before route handlers
  /// - After hooks that run after route handlers
  /// - After WebSocket hooks that run after WebSocket handlers
  static void clearGlobalHooks() {
    globalBeforeHooks.clear();
    globalAfterHooks.clear();
    globalAfterWebSocketHooks.clear();
  }

  /// Clears WebSocket connection state.
  ///
  /// This clears the backward compatibility WebSocket map.
  /// Note: This does not clear the WebSocket storage manager as it
  /// might not be initialized in test environments.
  static void clearWebSocketState() {
    wsMap.clear();
    // Note: We don't clear wsStorageManager here as it may not be initialized
    // and clearing it could cause issues. The storage manager should handle
    // its own cleanup when connections are closed.
  }

  /// Resets server-related global state.
  ///
  /// This resets the flag that indicates whether static files can be served.
  static void resetServerState() {
    canServeStaticFiles = false;
  }

  /// Gets a snapshot of the current global state for debugging.
  ///
  /// Returns a map containing information about the current state
  /// of all global Arcade objects. Useful for debugging test issues.
  static Map<String, dynamic> getStateSnapshot() {
    return {
      'routeCount': routes.length,
      'routeGroupPrefix': routeGroupPrefix,
      'hasCurrentProcessingRoute': currentProcessingRoute != null,
      'globalBeforeHooksCount': globalBeforeHooks.length,
      'globalAfterHooksCount': globalAfterHooks.length,
      'globalAfterWebSocketHooksCount': globalAfterWebSocketHooks.length,
      'wsMapSize': wsMap.length,
      'canServeStaticFiles': canServeStaticFiles,
      'normalizedPathCacheSize': normalizedPathCache.length,
    };
  }

  /// Validates that the state is clean (useful for debugging).
  ///
  /// Throws an exception if any global state is not in its initial state.
  /// This can be useful to ensure tests are properly cleaning up after themselves.
  static void validateCleanState() {
    final state = getStateSnapshot();
    final errors = <String>[];

    if (state['routeCount'] != 0) {
      errors.add('Routes not cleared: ${state['routeCount']} routes remaining');
    }

    if (state['routeGroupPrefix'] != '') {
      errors.add(
          'Route group prefix not cleared: "${state['routeGroupPrefix']}"');
    }

    if (state['hasCurrentProcessingRoute'] == true) {
      errors.add('Current processing route not cleared');
    }

    if (state['globalBeforeHooksCount'] != 0) {
      errors.add(
          'Global before hooks not cleared: ${state['globalBeforeHooksCount']} hooks remaining');
    }

    if (state['globalAfterHooksCount'] != 0) {
      errors.add(
          'Global after hooks not cleared: ${state['globalAfterHooksCount']} hooks remaining');
    }

    if (state['globalAfterWebSocketHooksCount'] != 0) {
      errors.add(
          'Global after WebSocket hooks not cleared: ${state['globalAfterWebSocketHooksCount']} hooks remaining');
    }

    if (state['wsMapSize'] != 0) {
      errors.add(
          'WebSocket map not cleared: ${state['wsMapSize']} connections remaining');
    }

    if (errors.isNotEmpty) {
      throw StateError('Arcade state is not clean:\n${errors.join('\n')}');
    }
  }
}
