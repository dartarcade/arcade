import 'package:arcade_orm/arcade_orm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdapter extends Mock implements ArcadeOrmAdapterBase {}

void main() {
  group('getArcadeOrmInstance', () {
    tearDown(clearOrms);
    
    test('should throw error if ArcadeOrm is not initialized', () {
      expect(() => getArcadeOrmInstance(), throwsStateError);
    });

    test('should return an instance if init() was called', () async {
      final arcadeOrm = await ArcadeOrm.init(adapter: MockAdapter());
      expect(getArcadeOrmInstance(), arcadeOrm);
    });

    test('should return the correct instance if name is provided', () async {
      final arcadeOrm = await ArcadeOrm.init(
        adapter: MockAdapter(),
        name: 'test',
      );
      expect(getArcadeOrmInstance('test'), arcadeOrm);
    });

    test('should return correct instance if multiple ORMs exist', () async {
      final defaultArcadeOrm = await ArcadeOrm.init(adapter: MockAdapter());
      final namedArcadeOrm = await ArcadeOrm.init(
        adapter: MockAdapter(),
        name: 'test',
      );
      expect(getArcadeOrmInstance(), defaultArcadeOrm);
      expect(getArcadeOrmInstance('test'), namedArcadeOrm);
    });
  });
}
