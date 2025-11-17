## 1.2.0

- Updated dependencies

## 1.1.1

- Updated dependencies

## 1.1.0

- Updated dependencies

## 1.0.2

- Updated dependencies

## 1.0.0

- Updated dependencies

## 0.6.0

- **FEAT**: Implemented Redis pub-sub support:
  - Creates separate Redis connections for each subscription (as required by Redis protocol)
  - Supports JSON message encoding/decoding for complex data types
  - Handles connection lifecycle and cleanup properly
- **FIX**: Fixed `getJson()` to return null for invalid JSON instead of throwing exceptions
- **FIX**: Added support for serializing double values to Redis (converts to string)
- **FIX**: Improved stream controller management to prevent "Cannot add events after close" errors
- **TEST**: Added comprehensive integration tests for all Redis cache operations

## 0.5.0

- **CHORE**: Update version to 0.5.0 to align with core arcade package.

## 0.0.2

- **FEAT**: redis implementation.

## 0.0.1

- Initial version.
