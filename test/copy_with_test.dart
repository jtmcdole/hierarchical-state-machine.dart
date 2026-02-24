import 'package:test/test.dart';
import 'package:hierarchical_state_machine/src/machine.dart';

void main() {
  group('Blueprint copyWith Tests', () {
    group('TransitionBlueprint.copyWith', () {
      test('should copy simple fields', () {
        final original = TransitionBlueprint<String, String>(
          target: 's1',
          kind: TransitionKind.external,
          history: HistoryType.shallow,
        );

        final copied = original.copyWith(
          kind: TransitionKind.local,
          history: HistoryType.deep,
        );

        expect(copied.target, equals('s1'));
        expect(copied.kind, equals(TransitionKind.local));
        expect(copied.history, equals(HistoryType.deep));
      });

      test('should update nullable fields using Record', () {
        final original = TransitionBlueprint<String, String>(target: 's1');

        final copied = original.copyWith(target: (to: 's2'));
        expect(copied.target, equals('s2'));

        final nullTarget = copied.copyWith(target: (to: null));
        expect(nullTarget.target, isNull);
      });
    });

    group('CompositeBlueprint.copyWith', () {
      test('should copy simple fields', () {
        final original = CompositeBlueprint<String, String>(
          id: 's1',
          defer: {'e1'},
          children: [.composite(id: 'c1')],
        );

        final copied = original.copyWith(id: 's2', defer: {'e2'});

        expect(copied.id, equals('s2'));
        expect(copied.defer, equals({'e2'}));
        expect(copied.children.length, equals(1));
        expect(copied.children.first.id, equals('c1'));
      });

      test('should update nullable fields using Record', () {
        final original = CompositeBlueprint<String, String>(
          id: 's1',
          on: {'e1': .to(target: 's2')},
          initial: 's2',
        );

        final copied = original.copyWith(
          on: (to: {'e2': .to(target: 's3')}),
          initial: (to: 's3'),
        );

        expect(copied.on?.containsKey('e2'), isTrue);
        expect(copied.on?.containsKey('e1'), isFalse);
        expect(copied.initial, equals('s3'));

        final nullified = copied.copyWith(on: (to: null), initial: (to: null));
        expect(nullified.on, isNull);
        expect(nullified.initial, isNull);
      });
    });

    group('ParallelBlueprint.copyWith', () {
      test('should copy fields', () {
        final original = ParallelBlueprint<String, String>(
          id: 'p1',
          children: [.composite(id: 'c1')],
        );

        final copied = original.copyWith(id: 'p2');

        expect(copied.id, equals('p2'));
        expect(copied.children.length, equals(1));
        expect(copied.children.first.id, equals('c1'));
      });
    });

    group('ChoiceBlueprint.copyWith', () {
      test('should copy fields', () {
        final original = ChoiceBlueprint<String, String>(
          id: 'c1',
          defaultTransition: .to(target: 's1'),
        );

        final copied = original.copyWith(
          id: 'c2',
          defaultTransition: .to(target: 's2'),
        );

        expect(copied.id, equals('c2'));
        expect(copied.defaultTransition.target, equals('s2'));
      });
    });

    group('ForkBlueprint.copyWith', () {
      test('should copy fields', () {
        final original = ForkBlueprint<String, String>(
          id: 'f1',
          transitions: [
            .to(target: 's1'),
            .to(target: 's2'),
          ],
        );

        final copied = original.copyWith(id: 'f2');

        expect(copied.id, equals('f2'));
        expect(copied.transitions.length, equals(2));
      });
    });

    group('MachineBlueprint.copyWith', () {
      test('should copy fields', () {
        final original = MachineBlueprint<String, String>(
          name: 'M1',
          root: .composite(id: 'root'),
        );

        final copied = original.copyWith(name: (to: 'M2'));

        expect(copied.name, equals('M2'));
        expect(copied.root.id, equals('root'));

        final nullName = copied.copyWith(name: (to: null));
        expect(nullName.name, isNull);
      });
    });
  });
}
