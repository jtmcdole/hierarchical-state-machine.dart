part of '../machine.dart';

/// Observer interface for monitoring state machine execution.
///
/// Implement this class to hook into lifecycle events, transitions, and error handling.
/// Default implementations are empty, so you can override only the methods you need.
abstract class MachineObserver<S, E> {
  /// Creates a new [MachineObserver].
  const MachineObserver();

  // Lifecycle
  /// Called when the machine is starting.
  void onMachineStarting(Machine<S, E> machine) {}

  /// Called when the machine has successfully started and entered its root state.
  void onMachineStarted(Machine<S, E> machine) {}

  /// Called when the machine has been stopped and all states have been exited.
  void onMachineStopped(Machine<S, E> machine) {}

  /// Called when the machine enters a [TerminateState].
  void onMachineTerminated(Machine<S, E> machine) {}

  // Event Handling
  /// Called when an event is added to the machine's event queue.
  void onEventQueued(Machine<S, E> machine, E event, Object? data) {}

  /// Called when the machine begins processing an event.
  void onEventHandling(Machine<S, E> machine, E event, Object? data) {}

  /// Called when an event has been successfully handled.
  void onEventHandled(HsmState<S, E> state, E event, Object? data) {}

  /// Called when an event was not handled by any active state.
  void onEventUnhandled(HsmState<S, E> state, E event, Object? data) {}

  /// Called when an event is deferred by a state.
  void onEventDeferred(HsmState<S, E> state, E event, Object? data) {}

  /// Called when a deferred event is dropped.
  void onEventDropped(HsmState<S, E> state, E event, Object? data) {}

  /// Called when an error occurs during event processing.
  void onEventError(
    Machine<S, E> machine,
    E event,
    Object? data,
    Object error,
    StackTrace stackTrace,
  ) {}

  // State Lifecycle
  /// Called when a state is entered.
  void onStateEnter(HsmState<S, E> state) {}

  /// Called when a state is exited.
  void onStateExit(HsmState<S, E> state) {}

  // Transitions
  /// Called when a transition between two states occurs.
  void onTransition(
    HsmState<S, E> source,
    HsmState<S, E> target,
    E? event,
    Object? data,
    TransitionKind kind,
  ) {}

  /// Called when an internal transition (no state change) occurs.
  void onInternalTransition(HsmState<S, E> state, E? event, Object? data) {}
}

/// A no-op observer that does nothing.
final class NoOpObserver<S, E> extends MachineObserver<S, E> {
  /// Creates a new [NoOpObserver].
  const NoOpObserver();
}

/// A default observer that prints machine activity to the console.
class PrintObserver<S, E> extends MachineObserver<S, E> {
  /// An optional function to format the output strings.
  final String Function(String) formatter;

  /// Creates a new [PrintObserver] with an optional [formatter].
  const PrintObserver({this.formatter = _defaultFormatter});

  static String _defaultFormatter(String msg) => msg;

  void _log(String message) {
    print(formatter(message));
  }

  @override
  void onMachineStarting(Machine<S, E> machine) => _log('$machine: starting');

  @override
  void onMachineStarted(Machine<S, E> machine) => _log('$machine: started');

  @override
  void onMachineStopped(Machine<S, E> machine) => _log('$machine: stopped');

  @override
  void onMachineTerminated(Machine<S, E> machine) =>
      _log('$machine: terminated');

  @override
  void onEventQueued(Machine<S, E> machine, E event, Object? data) =>
      _log('$machine: queueing event $event data: $data');

  @override
  void onEventHandling(Machine<S, E> machine, E event, Object? data) =>
      _log('$machine: handling event $event data: $data');

  @override
  void onEventHandled(HsmState<S, E> state, E event, Object? data) =>
      _log('$state: handled event $event');

  @override
  void onEventUnhandled(HsmState<S, E> state, E event, Object? data) =>
      _log('$state: unhandled event $event');

  @override
  void onEventDeferred(HsmState<S, E> state, E event, Object? data) =>
      _log('$state: deferring event $event');

  @override
  void onEventDropped(HsmState<S, E> state, E event, Object? data) =>
      _log('$state: dropping deferral $event');

  @override
  void onEventError(
    Machine<S, E> machine,
    E event,
    Object? data,
    Object error,
    StackTrace stackTrace,
  ) => _log('$machine: error handling $event: $error\n$stackTrace');

  @override
  void onStateEnter(HsmState<S, E> state) => _log('$state: enter');

  @override
  void onStateExit(HsmState<S, E> state) => _log('$state: exit');

  @override
  void onTransition(
    HsmState<S, E> source,
    HsmState<S, E> target,
    E? event,
    Object? data,
    TransitionKind kind,
  ) => _log('$source: transition to $target (${kind.name})');

  @override
  void onInternalTransition(HsmState<S, E> state, E? event, Object? data) =>
      _log('$state: internal transition');
}
