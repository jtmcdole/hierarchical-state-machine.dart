import 'package:test/test.dart';
import 'package:hierarchical_state_machine/src/machine.dart';

void main() {
  group('Blueprint replaceState and findState Tests', () {
    final complexBlueprint = MachineBlueprint<String, String>(
      name: 'Complex Machine',
      root: .composite(
        id: 'root',
        children: [
          .composite(
            id: 'c1',
            children: [
              .finish(id: 'f1'),
              .choice(
                id: 'choice1',
                defaultTransition: .to(target: 'f1'),
              ),
            ],
          ),
          .parallel(
            id: 'p1',
            children: [
              .composite(id: 'r1'),
              .composite(id: 'r2'),
            ],
          ),
          .fork(
            id: 'fork1',
            transitions: [
              .to(target: 'r1'),
              .to(target: 'r2'),
            ],
          ),

          .terminate(id: 't1'),
        ],
      ),
    );

    group('findState', () {
      test('should find states at various depths', () {
        expect(complexBlueprint.root.findState('root')?.id, equals('root'));
        expect(complexBlueprint.root.findState('c1')?.id, equals('c1'));
        expect(complexBlueprint.root.findState('f1')?.id, equals('f1'));
        expect(
          complexBlueprint.root.findState('choice1')?.id,
          equals('choice1'),
        );
        expect(complexBlueprint.root.findState('p1')?.id, equals('p1'));
        expect(complexBlueprint.root.findState('r1')?.id, equals('r1'));
        expect(complexBlueprint.root.findState('fork1')?.id, equals('fork1'));
        expect(complexBlueprint.root.findState('t1')?.id, equals('t1'));
      });

      test('should return null if state not found', () {
        expect(complexBlueprint.root.findState('missing'), isNull);
      });
    });

    group('replaceState', () {
      test('should replace a leaf state (Final)', () {
        final updated = complexBlueprint.replaceState(
          'f1',
          (found) => .finish(id: 'f1_updated'),
        );

        expect(updated.root.findState('f1'), isNull);
        expect(updated.root.findState('f1_updated'), isNotNull);
        // Verify structure remains
        expect(updated.root.findState('c1'), isNotNull);
      });

      test('should replace a Choice state and preserve parent structure', () {
        final updated = complexBlueprint.replaceState(
          'choice1',
          (found) => found.asChoice.copyWith(id: 'choice1_updated'),
        );

        expect(updated.root.findState('choice1'), isNull);
        expect(updated.root.findState('choice1_updated'), isNotNull);
        expect(updated.root.findState('c1'), isNotNull);
      });

      test(
        'should replace a state inside a Parallel region and preserve Parallel type',
        () {
          final updated = complexBlueprint.replaceState(
            'r1',
            (found) => found.asComposite.copyWith(id: 'r1_updated'),
          );

          expect(updated.root.findState('r1'), isNull);
          expect(updated.root.findState('r1_updated'), isNotNull);
          final p1 = updated.root.findState('p1');
          expect(p1, isNotNull);
          expect(
            p1,
            isA<ParallelBlueprint>(),
            reason: 'Parallel state should not be demoted to Composite',
          );
        },
      );

      test('should replace a Fork state', () {
        final updated = complexBlueprint.replaceState(
          'fork1',
          (found) => found.asFork.copyWith(id: 'fork1_updated'),
        );

        expect(updated.root.findState('fork1'), isNull);
        expect(updated.root.findState('fork1_updated'), isNotNull);
      });

      test('should replace a Terminate state', () {
        final updated = complexBlueprint.replaceState(
          't1',
          (found) => .terminate(id: 't1_updated'),
        );

        expect(updated.root.findState('t1'), isNull);
        expect(updated.root.findState('t1_updated'), isNotNull);
      });

      test('should update multiple attributes via copyWith in transform', () {
        final updated = complexBlueprint.replaceState(
          'c1',
          (found) => found.asComposite.copyWith(
            initial: (to: 'f1'),
            defer: {'EVENT_A'},
          ),
        );

        final c1 = updated.root.findState('c1')!.asComposite;
        expect(c1.initial, equals('f1'));
        expect(c1.defer, contains('EVENT_A'));
      });

      test('should return identical blueprint if id not found', () {
        final updated = complexBlueprint.replaceState(
          'missing',
          (found) => .composite(id: 'should_not_happen'),
        );

        expect(identical(updated, complexBlueprint), isTrue);
      });

      test('should maintain immutability (original is unchanged)', () {
        complexBlueprint.replaceState(
          'root',
          (found) => .composite(id: 'new_root'),
        );

        expect(complexBlueprint.root.id, equals('root'));
      });
    });
  });
}
