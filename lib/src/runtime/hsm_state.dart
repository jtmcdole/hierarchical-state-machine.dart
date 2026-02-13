part of '../machine.dart';

/// The read-only view of a state within a [Machine].
sealed class HsmState<S, E> {
  HsmState._();

  /// The unique identifier for this state.
  S get id;

  /// The parent state, if any.
  HsmState<S, E>? get parent;

  /// Whether this state is currently active.
  bool get isActive;

  /// Returns the state path from root to this state.
  List<HsmState<S, E>> get path;
}

/// The type of a state within a [Machine].
enum StateType {
  /// A basic state which can have at most one active child.
  composite,

  /// A compound state in which all direct descendants are active at once.
  parallel,

  /// A pseudostate that chooses a transition based on guards.
  choice,

  /// A pseudostate that splits a transition into multiple simultaneous paths.
  fork,

  /// A state representing a final node in a region.
  finish,

  /// A state representing a terminate node for the whole machine.
  terminate,
}

/// Provides access to the [StateType] of an [HsmState].
extension StateTypeExtension on HsmState {
  /// The specific type of this state.
  StateType get type => switch (this) {
    FinalState _ => .finish,
    ParallelState _ => .parallel,
    State _ => .composite,
    ChoiceState _ => .choice,
    ForkState _ => .fork,
    TerminateState _ => .terminate,
    _ => throw StateError('Unknown state type $runtimeType'),
  };
}
