import 'package:test/test.dart';
import 'package:hierarchical_state_machine/src/machine.dart';

enum States {
  root,
  sub,
  choice,
  fork,
  parallel,
  region1,
  region2,
  ending,
  term,
}

enum Events { next, alt }

void main() {
  group('BasicBlueprintHelpers', () {
    final composite = BasicBlueprint<States, Events>.composite(id: States.sub);
    final parallel = BasicBlueprint<States, Events>.parallel(
      id: States.parallel,
    );
    final choice = BasicBlueprint<States, Events>.choice(
      id: States.choice,
      defaultTransition: DefaultTransitionBlueprint.to(target: States.sub),
    );
    final fork = BasicBlueprint<States, Events>.fork(
      id: States.fork,
      transitions: [
        ForkTransitionBlueprint.to(target: States.region1),
        ForkTransitionBlueprint.to(target: States.region2),
      ],
    );
    final finalState = BasicBlueprint<States, Events>.finish(id: States.ending);
    final terminateState = BasicBlueprint<States, Events>.terminate(
      id: States.term,
    );

    test('isComposite and asComposite', () {
      expect(composite.isComposite, isTrue);
      expect(parallel.isComposite, isTrue); // Parallel inherits Composite
      expect(choice.isComposite, isFalse);

      expect(composite.asComposite.id, States.sub);
    });

    test('isParallel and asParallel', () {
      expect(parallel.isParallel, isTrue);
      expect(composite.isParallel, isFalse);

      expect(parallel.asParallel.id, States.parallel);
      expect(() => composite.asParallel, throwsA(isA<TypeError>()));
    });

    test('isChoice and asChoice', () {
      expect(choice.isChoice, isTrue);
      expect(composite.isChoice, isFalse);

      expect(choice.asChoice.id, States.choice);
      expect(() => composite.asChoice, throwsA(isA<TypeError>()));
    });

    test('isFork and asFork', () {
      expect(fork.isFork, isTrue);
      expect(composite.isFork, isFalse);

      expect(fork.asFork.id, States.fork);
      expect(() => composite.asFork, throwsA(isA<TypeError>()));
    });

    test('isFinal and asFinal', () {
      expect(finalState.isFinal, isTrue);
      expect(composite.isFinal, isFalse);

      expect(finalState.asFinal.id, States.ending);
      expect(() => composite.asFinal, throwsA(isA<TypeError>()));
    });

    test('isTerminate and asTerminate', () {
      expect(terminateState.isTerminate, isTrue);
      expect(composite.isTerminate, isFalse);

      expect(terminateState.asTerminate.id, States.term);
      expect(() => composite.asTerminate, throwsA(isA<TypeError>()));
    });
  });

  group('Blueprint copyWith methods', () {
    test('DefaultTransitionBlueprintX.copyWith', () {
      final original = DefaultTransitionBlueprint<States, Events>.to(
        target: States.sub,
        kind: TransitionKind.local,
      );

      final copy = original.copyWith(
        target: States.ending,
        action: (to: (e, d) {}),
        kind: TransitionKind.external,
        history: HistoryType.shallow,
      );

      expect(copy.target, States.ending);
      expect(copy.action, isNotNull);
      expect(copy.kind, TransitionKind.external);
      expect(copy.history, HistoryType.shallow);

      final copyNullAction = copy.copyWith(action: (to: null));
      expect(copyNullAction.action, isNull);
    });

    test('ForkTransitionBlueprintX.copyWith', () {
      final original = ForkTransitionBlueprint<States, Events>.to(
        target: States.region1,
      );

      final copy = original.copyWith(
        target: States.region2,
        action: (to: (e, d) {}),
        history: HistoryType.deep,
      );

      expect(copy.target, States.region2);
      expect(copy.action, isNotNull);
      expect(copy.history, HistoryType.deep);

      final copyNullAction = copy.copyWith(action: (to: null));
      expect(copyNullAction.action, isNull);
    });

    test('CompletionBlueprintX.copyWith', () {
      final original = CompletionBlueprint<States, Events>.to(
        target: States.sub,
        guard: () => true,
      );

      final copy = original.copyWith(
        target: (to: States.ending),
        guard: (to: () => false),
        action: (to: () {}),
        kind: TransitionKind.external,
        history: HistoryType.shallow,
      );

      expect(copy.target, States.ending);
      expect(copy.guard?.call(), isFalse);
      expect(copy.action, isNotNull);
      expect(copy.kind, TransitionKind.external);
      expect(copy.history, HistoryType.shallow);

      final copyNull = copy.copyWith(
        target: (to: null),
        guard: (to: null),
        action: (to: null),
      );
      expect(copyNull.target, isNull);
      expect(copyNull.guard, isNull);
      expect(copyNull.action, isNull);
    });

    test('ChoiceBlueprintX.copyWith', () {
      final original = ChoiceBlueprint<States, Events>(
        id: States.choice,
        defaultTransition: DefaultTransitionBlueprint.to(target: States.sub),
      );

      final updatedDefault = DefaultTransitionBlueprint<States, Events>.to(
        target: States.ending,
      );
      final copy = original.copyWith(
        id: States.root,
        defaultTransition: updatedDefault,
        options: [TransitionBlueprint.to(target: States.parallel)],
      );

      expect(copy.id, States.root);
      expect(copy.defaultTransition.target, States.ending);
      expect(copy.options.length, 1);
    });

    test('ForkBlueprintX.copyWith', () {
      final original = ForkBlueprint<States, Events>(
        id: States.fork,
        transitions: [ForkTransitionBlueprint.to(target: States.region1)],
      );

      final copy = original.copyWith(
        id: States.root,
        transitions: [
          ForkTransitionBlueprint.to(target: States.region1),
          ForkTransitionBlueprint.to(target: States.region2),
        ],
      );

      expect(copy.id, States.root);
      expect(copy.transitions.length, 2);
    });
  });
}
