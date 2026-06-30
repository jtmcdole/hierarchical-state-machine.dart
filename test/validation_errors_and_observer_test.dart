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

class TestObserver<S, E> extends MachineObserver<S, E> {}

Machine<States, Events> createTestMachine() {
  final blueprint = MachineBlueprint<States, Events>(
    root: .composite(
      id: States.root,
      children: [
        .composite(id: States.sub),
        .parallel(
          id: States.parallel,
          children: [
            .composite(id: States.region1),
            .composite(id: States.region2),
          ],
        ),
      ],
    ),
  );
  final (compiled, errors) = blueprint.compile();
  expect(errors, isEmpty);
  return compiled!;
}

void main() {
  group('Validation Errors', () {
    test('InvalidRootError formatting and properties', () {
      final error = InvalidRootError();
      expect(error.message, 'Root must be a State or ParallelState');
      expect(
        error.toString(),
        'ValidationError: Root must be a State or ParallelState',
      );
    });

    test('UnknownDefinitionTypeError formatting and properties', () {
      final error = UnknownDefinitionTypeError<States>(String, States.sub);
      expect(error.type, String);
      expect(error.id, States.sub);
      expect(
        error.toString(),
        'ValidationError: Unknown definition type "String" for state "States.sub"',
      );
    });
  });

  group('toString() representations', () {
    test('EventHandler.toString() internal and external', () {
      final machine = createTestMachine();
      final targetState =
          machine.getState(States.sub) as BaseState<States, Events>;

      final handlerInternal = EventHandler<States, Events>(
        guard: (e, d) => true,
        action: (e, d) {},
      );
      expect(handlerInternal.toString(), contains('internal'));

      final handlerExternal = EventHandler<States, Events>(
        target: targetState,
        kind: TransitionKind.external,
      );
      expect(handlerExternal.toString(), contains('TransitionKind.external'));
    });

    test('ForkTransition.toString()', () {
      final machine = createTestMachine();
      final targetState =
          machine.getState(States.region1) as BaseState<States, Events>;
      final transition = ForkTransition<States, Events>(
        target: targetState,
        history: HistoryType.shallow,
      );
      expect(transition.toString(), contains('ForkTransition'));
      expect(transition.toString(), contains('shallow'));
    });
  });

  group('MachineObserver Default Methods', () {
    test('Base MachineObserver empty callbacks invoke cleanly', () {
      final observer = TestObserver<States, Events>();
      final machine = createTestMachine();
      final st = machine.getState(States.root) as BaseState<States, Events>;

      expect(() {
        observer.onMachineStarting(machine);
        observer.onMachineStarted(machine);
        observer.onMachineStopped(machine);
        observer.onMachineTerminated(machine);
        observer.onEventQueued(machine, Events.next, null);
        observer.onEventHandling(machine, Events.next, null);
        observer.onEventHandled(st, Events.next, null);
        observer.onEventUnhandled(st, Events.next, null);
        observer.onEventDeferred(st, Events.next, null);
        observer.onEventDropped(st, Events.next, null);
        observer.onEventError(
          machine,
          Events.next,
          null,
          Exception('test'),
          StackTrace.current,
        );
        observer.onStateEnter(st);
        observer.onStateExit(st);
        observer.onTransition(st, st, Events.next, null, TransitionKind.local);
        observer.onInternalTransition(st, Events.next, null);
      }, returnsNormally);
    });
  });
}
