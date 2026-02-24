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

/// Provides convenient type-checking and casting for [BasicBlueprint].
///
/// These helpers simplify working with blueprints in a polymorphic context,
/// such as when iterating over children or modifying a deep blueprint tree.
extension BasicBlueprintHelpers<S, E> on BasicBlueprint<S, E> {
  /// Returns `true` if this blueprint is a [CompositeBlueprint].
  bool get isComposite => this is CompositeBlueprint<S, E>;

  /// Casts this blueprint to a [CompositeBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [CompositeBlueprint].
  CompositeBlueprint<S, E> get asComposite => this as CompositeBlueprint<S, E>;

  /// Returns `true` if this blueprint is a [ParallelBlueprint].
  bool get isParallel => this is ParallelBlueprint<S, E>;

  /// Casts this blueprint to a [ParallelBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [ParallelBlueprint].
  ParallelBlueprint<S, E> get asParallel => this as ParallelBlueprint<S, E>;

  /// Returns `true` if this blueprint is a [ChoiceBlueprint].
  bool get isChoice => this is ChoiceBlueprint<S, E>;

  /// Casts this blueprint to a [ChoiceBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [ChoiceBlueprint].
  ChoiceBlueprint<S, E> get asChoice => this as ChoiceBlueprint<S, E>;

  /// Returns `true` if this blueprint is a [ForkBlueprint].
  bool get isFork => this is ForkBlueprint<S, E>;

  /// Casts this blueprint to a [ForkBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [ForkBlueprint].
  ForkBlueprint<S, E> get asFork => this as ForkBlueprint<S, E>;

  /// Returns `true` if this blueprint is a [FinalBlueprint].
  bool get isFinal => this is FinalBlueprint<S, E>;

  /// Casts this blueprint to a [FinalBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [FinalBlueprint].
  FinalBlueprint<S, E> get asFinal => this as FinalBlueprint<S, E>;

  /// Returns `true` if this blueprint is a [TerminateBlueprint].
  bool get isTerminate => this is TerminateBlueprint<S, E>;

  /// Casts this blueprint to a [TerminateBlueprint].
  ///
  /// Throws a [TypeError] if this blueprint is not a [TerminateBlueprint].
  TerminateBlueprint<S, E> get asTerminate => this as TerminateBlueprint<S, E>;
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

/// Extension to provide [copyWith] for [CompositeBlueprint].
extension CompositeBlueprintX<S, E> on CompositeBlueprint<S, E> {
  /// Creates a copy of this [CompositeBlueprint] with the specified fields
  /// replaced.
  CompositeBlueprint<S, E> copyWith({
    S? id,
    Set<E>? defer,
    List<BasicBlueprint<S, E>>? children,
    ({S? to})? initial,
    ({Map<E, TransitionBlueprint<S, E>>? to})? on,
    ({List<CompletionBlueprint<S, E>>? to})? completion,
    ({StateFunction? to})? entry,
    ({StateFunction? to})? exit,
    ({StateFunction? to})? initialAction,
  }) {
    return CompositeBlueprint(
      id: id ?? this.id,
      on: on != null ? on.to : this.on,
      defer: defer ?? this.defer,
      completion: completion != null ? completion.to : this.completion,
      entry: entry != null ? entry.to : this.entry,
      exit: exit != null ? exit.to : this.exit,
      children: children ?? this.children,
      initial: initial != null ? initial.to : this.initial,
      initialAction: initialAction != null
          ? initialAction.to
          : this.initialAction,
    );
  }
}

/// Extension to provide [copyWith] for [ParallelBlueprint].
extension ParallelBlueprintX<S, E> on ParallelBlueprint<S, E> {
  /// Creates a copy of this [ParallelBlueprint] with the specified fields
  /// replaced.
  ParallelBlueprint<S, E> copyWith({
    S? id,
    List<BasicBlueprint<S, E>>? children,
    ({Map<E, TransitionBlueprint<S, E>>? to})? on,
    ({List<CompletionBlueprint<S, E>>? to})? completion,
    ({StateFunction? to})? entry,
    ({StateFunction? to})? exit,
  }) {
    return ParallelBlueprint(
      id: id ?? this.id,
      children: children ?? this.children,
      on: on != null ? on.to : this.on,
      completion: completion != null ? completion.to : this.completion,
      entry: entry != null ? entry.to : this.entry,
      exit: exit != null ? exit.to : this.exit,
    );
  }
}

/// Extension to provide [copyWith] for [ChoiceBlueprint].
extension ChoiceBlueprintX<S, E> on ChoiceBlueprint<S, E> {
  /// Creates a copy of this [ChoiceBlueprint] with the specified fields
  /// replaced.
  ChoiceBlueprint<S, E> copyWith({
    S? id,
    DefaultTransitionBlueprint<S, E>? defaultTransition,
    List<TransitionBlueprint<S, E>>? options,
  }) {
    return ChoiceBlueprint(
      id: id ?? this.id,
      defaultTransition: defaultTransition ?? this.defaultTransition,
      options: options ?? this.options,
    );
  }
}

/// Extension to provide [copyWith] for [ForkBlueprint].
extension ForkBlueprintX<S, E> on ForkBlueprint<S, E> {
  /// Creates a copy of this [ForkBlueprint] with the specified fields
  /// replaced.
  ForkBlueprint<S, E> copyWith({
    S? id,
    List<ForkTransitionBlueprint<S, E>>? transitions,
  }) {
    return ForkBlueprint(
      id: id ?? this.id,
      transitions: transitions ?? this.transitions,
    );
  }
}
