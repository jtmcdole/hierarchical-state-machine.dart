part of '../machine.dart';

/// Base class for all state definitions in a [MachineBlueprint].
abstract class BasicBlueprint<S, E> {
  /// The unique identifier for this state.
  final S id;

  /// Creates a new [BasicBlueprint] with the specified [id].
  BasicBlueprint({required this.id});

  /// A compound state that may contain children.
  ///
  /// Composite states have one region - that is, at most one child may be active
  /// at any one time.
  ///
  /// Composite states can have handlers, completion, entry and exit behaviors,
  /// record history, and define an initial state. This is the basis of nearly
  /// all machines.
  factory BasicBlueprint.composite({
    required S id,
    Map<E, TransitionBlueprint<S, E>>? on,
    Set<E> defer,
    List<CompletionBlueprint<S, E>>? completion,
    StateFunction? entry,
    StateFunction? exit,
    List<BasicBlueprint<S, E>> children,
    S? initial,
    StateFunction? initialAction,
  }) = CompositeBlueprint;

  /// A compound state in which each direct child forms a region.
  ///
  /// A parallel state is like a [CompositeState] except that all direct children
  /// are active at the same time - meaning they each have the ability to handle
  /// events.
  factory BasicBlueprint.parallel({
    required S id,
    Map<E, TransitionBlueprint<S, E>>? on,
    List<CompletionBlueprint<S, E>>? completion,
    StateFunction? entry,
    StateFunction? exit,
    List<BasicBlueprint<S, E>> children,
  }) = ParallelBlueprint;

  /// A pseudostate that chooses a transition based on guards.
  factory BasicBlueprint.choice({
    required S id,
    required DefaultTransitionBlueprint<S, E> defaultTransition,
    List<TransitionBlueprint<S, E>> options,
  }) = ChoiceBlueprint;

  /// A pseudostate that splits a transition into multiple simultaneous paths
  /// targeting different regions of a [ParallelBlueprint].
  ///
  /// Forks serve to enter a [ParallelBlueprint] at specific, non-default
  /// states in its orthogonal regions.
  ///
  /// Validation is performed during compilation. A valid fork must:
  /// 1. Have at least two target transitions.
  /// 2. Have a [ParallelBlueprint] as the Lowest Common Ancestor (LCA)
  ///    of all targets.
  /// 3. Have no more targets than there are regions in
  ///    that [ParallelBlueprint].
  /// 4. Target each orthogonal region at most once.
  factory BasicBlueprint.fork({
    required S id,
    required List<ForkTransitionBlueprint<S, E>> transitions,
  }) = ForkBlueprint;

  /// A state representing a final node in a region.
  ///
  /// grumble: .final cannot be used?
  factory BasicBlueprint.finish({required S id}) = FinalBlueprint;

  /// A state representing a terminate node for the whole machine.
  factory BasicBlueprint.terminate({required S id}) = TerminateBlueprint;
}

/// A compound state that may contain children.
///
/// Composite states have one region - that is, at most one child may be active
/// at any one time.
///
/// Composite states can have handlers, completion, entry and exit behaviors,
/// record history, and define an initial state. This is the basis of nearly
/// all machines.
class CompositeBlueprint<S, E> extends BasicBlueprint<S, E> {
  /// The map of event handlers for this state.
  final Map<E, TransitionBlueprint<S, E>>? on;

  /// The set of events that this state defers for later processing.
  ///
  /// Deferrals are only evaluated if there are no [on] handlers that pass,
  /// allowing for optional deferral.
  final Set<E> defer;

  /// Completion handlers are evaluated when a substate enters this state's
  /// [FinalBlueprint] child.
  final List<CompletionBlueprint<S, E>>? completion;

  /// The effect behavior executed when this state is entered.
  final StateFunction? entry;

  /// The effect behavior executed when this state is exited.
  final StateFunction? exit;

  /// The list of direct descendants of this state.
  final List<BasicBlueprint<S, E>> children;

  /// Optional unique identifier of the default state to transition to when entered
  /// via the default entry mechanism (i.e. not history).
  final S? initial;

  /// The effect behavior executed when the [initial] state is entered.
  final StateFunction? initialAction;

  /// Creates a new [CompositeBlueprint] with the specified configuration.
  ///
  /// Composite states have one region - that is, at most one child may be active
  /// at any one time.
  ///
  /// Composite states can have handlers, completion, entry and exit behaviors,
  /// record history, and define an initial state. This is the basis of nearly
  /// all machines.
  CompositeBlueprint({
    required super.id,
    this.on,
    this.defer = const {},
    this.completion,
    this.entry,
    this.exit,
    this.children = const [],
    this.initial,
    this.initialAction,
  });
}

/// A compound state in which each direct child forms a region.
///
/// A parallel state is like a [CompositeState] except that all direct children
/// are active at the same time - meaning they each have the ability to handle
/// events.
class ParallelBlueprint<S, E> extends CompositeBlueprint<S, E> {
  /// Creates a new [ParallelBlueprint] with the specified configuration.
  ///
  /// A parallel state is like a [CompositeState] except that all direct children
  /// are active at the same time - meaning they each have the ability to handle
  /// events.
  ParallelBlueprint({
    required super.id,
    super.children = const [],
    super.entry,
    super.exit,
    super.on,
    super.completion,
  });
}

/// A pseudostate that chooses a transition based on guards.
class ChoiceBlueprint<S, E> extends BasicBlueprint<S, E> {
  /// The transition to take if none of the [options] guards evaluate to true.
  final DefaultTransitionBlueprint<S, E> defaultTransition;

  /// The list of guarded transition options.
  final List<TransitionBlueprint<S, E>> options;

  /// Creates a new [ChoiceBlueprint] with the specified default and options.
  ChoiceBlueprint({
    required super.id,
    required this.defaultTransition,
    this.options = const [],
  });
}

/// A pseudostate that splits a transition into multiple simultaneous paths
/// targeting different regions of a [ParallelBlueprint].
///
/// Forks serve to enter a [ParallelBlueprint] at specific, non-default
/// states in its orthogonal regions.
///
/// Validation is performed during compilation. A valid fork must:
/// 1. Have at least two target transitions.
/// 2. Have a [ParallelBlueprint] as the Lowest Common Ancestor (LCA)
///    of all targets.
/// 3. Have no more targets than there are regions in
///    that [ParallelBlueprint].
/// 4. Target each orthogonal region at most once.
class ForkBlueprint<S, E> extends BasicBlueprint<S, E> {
  /// The list of transitions to take simultaneously.
  final List<ForkTransitionBlueprint<S, E>> transitions;

  /// A pseudostate that splits a transition into multiple simultaneous paths
  /// targeting different regions of a [ParallelBlueprint].
  ///
  /// Forks serve to enter a [ParallelBlueprint] at specific, non-default
  /// states in its orthogonal regions.
  ///
  /// Validation is performed during compilation. A valid fork must:
  /// 1. Have at least two target transitions.
  /// 2. Have a [ParallelBlueprint] as the Lowest Common Ancestor (LCA)
  ///    of all targets.
  /// 3. Have no more targets than there are regions in
  ///    that [ParallelBlueprint].
  /// 4. Target each orthogonal region at most once.
  ForkBlueprint({required super.id, required this.transitions});
}

/// A state representing a final node in a region.
class FinalBlueprint<S, E> extends BasicBlueprint<S, E> {
  /// Creates a new [FinalBlueprint] with the specified [id].
  FinalBlueprint({required super.id});
}

/// A state representing a terminate node for the whole machine.
class TerminateBlueprint<S, E> extends BasicBlueprint<S, E> {
  /// Creates a new [TerminateBlueprint] with the specified [id].
  TerminateBlueprint({required super.id});
}
