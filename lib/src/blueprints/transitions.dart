part of '../machine.dart';

/// Defines a transition to a target state.
final class TransitionBlueprint<S, E> {
  /// An optional unique identifier of the destination state.
  ///
  /// If this is null, the transition is considered "internal"
  final S? target;

  /// An optional guard function that must return true for the transition to be taken.
  final GuardFunction<E?, Object?>? guard;

  /// An optional effect behavior executed when this transition is taken.
  final ActionFunction<E?, Object?>? action;

  /// Whether the transition is local or external.
  final TransitionKind kind;

  /// The history restoration strategy to use when entering the [target].
  final HistoryType history;

  /// Defines a transition to a target state.
  TransitionBlueprint({
    this.target,
    this.guard,
    this.action,
    this.kind = TransitionKind.local,
    this.history = HistoryType.none,
  });

  /// Defines a transition to a target state.
  TransitionBlueprint.to({
    S? target,
    GuardFunction<E?, Object?>? guard,
    ActionFunction<E?, Object?>? action,
    TransitionKind kind = TransitionKind.local,
    HistoryType history = HistoryType.none,
  }) : this(
         target: target,
         guard: guard,
         action: action,
         kind: kind,
         history: history,
       );

  /// Defines multiple transitions to a target state.
  factory TransitionBlueprint.any(List<TransitionBlueprint<S, E>> targets) =
      _MultiTransitionBlueprint;
}

final class _MultiTransitionBlueprint<S, E> extends TransitionBlueprint<S, E> {
  final List<TransitionBlueprint<S, E>> transitions;
  _MultiTransitionBlueprint(this.transitions);
}

/// Specialized transition for choice states (no guard).
final class DefaultTransitionBlueprint<S, E> {
  /// The unique identifier of the destination state.
  final S target;

  /// An optional effect behavior executed when this transition is taken.
  final ActionFunction<E?, Object?>? action;

  /// Whether the transition is local or external.
  final TransitionKind kind;

  /// The history restoration strategy to use when entering the [target].
  final HistoryType history;

  /// Specialized transition for choice states (no guard).
  DefaultTransitionBlueprint({
    required this.target,
    this.action,
    this.kind = TransitionKind.local,
    this.history = HistoryType.none,
  });

  /// Specialized transition for choice states (no guard).
  ///
  /// Shorthand for defining a fork transition.
  DefaultTransitionBlueprint.to({
    required S target,
    ActionFunction<E?, Object?>? action,
    TransitionKind kind = TransitionKind.local,
    HistoryType history = HistoryType.none,
  }) : this(target: target, action: action, kind: kind, history: history);
}

/// Specialized transition for fork states.
final class ForkTransitionBlueprint<S, E> {
  /// The unique identifier of the destination state.
  final S target;

  /// An optional effect behavior executed when this transition is taken.
  final ActionFunction<E?, Object?>? action;

  /// The history restoration strategy to use when entering the [target].
  final HistoryType history;

  /// Specialized transition for fork states.
  ForkTransitionBlueprint({
    required this.target,
    this.action,
    this.history = HistoryType.none,
  });

  /// Specialized transition for fork states.
  ///
  /// Shorthand for defining a fork transition.
  ForkTransitionBlueprint.to({
    required S target,
    ActionFunction<E?, Object?>? action,
    HistoryType history = HistoryType.none,
  }) : this(target: target, action: action, history: history);
}

/// Defines a completion transition (no event).
///
/// A Completion Event is an internal control signal, not an external
/// data carrier. It signifies solely that "all Behaviors associated with
/// the source State... have completed execution". They execute with dispatching
/// priority. UML 14.2.3.8.3
final class CompletionBlueprint<S, E> {
  /// Optional unique identifier of the destination state.
  ///
  /// If this is not provided, the state is considered "at rest"
  final S? target;

  /// An optional guard function that must return true for the transition to be taken.
  final bool Function()? guard;

  /// An optional effect behavior executed when this transition is taken.
  final void Function()? action;

  /// Whether the transition is local or external.
  final TransitionKind kind;

  /// The history restoration strategy to use when entering the [target].
  final HistoryType history;

  /// Defines a completion transition (no event).
  ///
  /// A Completion Event is an internal control signal, not an external
  /// data carrier. It signifies solely that "all Behaviors associated with
  /// the source State... have completed execution". They execute with dispatching
  /// priority. UML 14.2.3.8.3
  CompletionBlueprint({
    this.target,
    this.guard,
    this.action,
    this.kind = TransitionKind.local,
    this.history = HistoryType.none,
  });

  /// Defines a completion transition (no event).
  ///
  /// A Completion Event is an internal control signal, not an external
  /// data carrier. It signifies solely that "all Behaviors associated with
  /// the source State... have completed execution". They execute with dispatching
  /// priority. UML 14.2.3.8.3
  ///
  /// Shorthand for defining a fork transition.
  CompletionBlueprint.to({
    S? target,
    bool Function()? guard,
    void Function()? action,
    TransitionKind kind = TransitionKind.local,
    HistoryType history = HistoryType.none,
  }) : this(
         target: target,
         guard: guard,
         action: action,
         kind: kind,
         history: history,
       );
}
