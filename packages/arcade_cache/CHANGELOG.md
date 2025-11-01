## 1.1.1

- Updated dependencies

## 1.1.0

- Updated dependencies

## 1.0.2

- Updated dependencies

## 1.0.0

- Updated dependencies

## 0.6.0

- **BREAKING**: Changed `BaseCacheManager` interface methods to return `Future` instead of `FutureOr`
- **FEAT**: Added pub-sub support to cache interface with typed event-based API:
  - `subscribe()` returns `Stream<PubSubEvent<T>>` with optional message mapper
  - `publish()` publishes messages to channels and returns subscriber count
  - `unsubscribe()` removes subscriptions from channels
  - Added typed event classes: `PubSubMessage<T>`, `PubSubSubscribed`, `PubSubUnsubscribed`
- **FEAT**: Implemented pub-sub in `MemoryCacheManager` with channel tracking and message broadcasting

## 0.5.0

- **CHORE**: Update version to 0.5.0 to align with core arcade package.

## 0.0.3

- **FEAT**: add MemoryCacheManager implementation for in-memory caching with TTL support.

## 0.0.2

- **REFACTOR**: fix samples and examples.
- **FEAT**: redis implementation.
- **FEAT**: make ready for publishing.
- **FEAT**: export BaseCacheManager.
- **FEAT**: rename to arcade.

## 0.0.1

- Initial version.
