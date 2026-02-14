part of '../machine.dart';

/// Base class for validation errors.
sealed class ValidationError {
  /// A human-readable message describing the error.
  final String message;

  /// Creates a new [ValidationError] with the specified message.
  ValidationError(this.message);

  @override
  String toString() => 'ValidationError: $message';
}

/// Thrown when multiple states share the same ID.
final class DuplicateStateIdError<S> extends ValidationError {
  /// The identifier that was duplicated.
  final S id;

  /// Thrown when multiple states share the same ID.
  DuplicateStateIdError(this.id) : super('Duplicate state ID found: $id');
}

/// Thrown when a transition or initial state targets a non-existent state.
final class MissingStateError<S> extends ValidationError {
  /// The identifier of the missing state.
  final S id;

  /// The identifier of the state containing the invalid target.
  final S sourceId;

  /// A string describing the context of the missing state (e.g. 'initial state').
  final String context;

  /// Thrown when a transition or initial state targets a non-existent state.
  MissingStateError(this.id, this.sourceId, this.context)
    : super('Missing state "$id" in $context of state "$sourceId"');
}

/// Thrown when a ForkState fails structural validation.
final class ForkValidationError<S> extends ValidationError {
  /// The identifier of the invalid fork state.
  final S forkId;

  /// Additional details about the validation failure.
  final String details;

  /// Thrown when a ForkState fails structural validation.
  ForkValidationError(this.forkId, this.details)
    : super('ForkState "$forkId" validation failed: $details');
}

/// Thrown when a transition configuration is invalid.
final class TransitionError<S> extends ValidationError {
  /// The identifier of the source state.
  final S baseId;

  /// The identifier of the target state.
  final S targetId;

  /// Additional details about the validation failure.
  final String details;

  /// Thrown when a transition configuration is invalid.
  TransitionError(this.baseId, this.targetId, this.details)
    : super('Transition "$baseId -> $targetId" validation failed: $details');
}

/// Thrown when an initial state is not a proper descendant of its parent state.
final class InvalidInitialStateError<S> extends ValidationError {
  /// The identifier of the invalid initial state.
  final S initialStateId;

  /// The identifier of the parent state.
  final S parentId;

  /// Thrown when an initial state is not a proper descendant of its parent state.
  InvalidInitialStateError(this.initialStateId, this.parentId)
    : super(
        'Initial state "$initialStateId" is not a proper descendant of "$parentId"',
      );
}

/// Thrown when the root state is not a composite or parallel state.
final class InvalidRootError extends ValidationError {
  /// Thrown when the root state is not a composite or parallel state.
  InvalidRootError() : super('Root must be a State or ParallelState');
}

/// Thrown when an unknown definition type is encountered.
final class UnknownDefinitionTypeError<S> extends ValidationError {
  /// The runtime type of the invalid definition.
  final Type type;

  /// The identifier of the definition.
  final S id;

  /// Thrown when an unknown definition type is encountered.
  UnknownDefinitionTypeError(this.type, this.id)
    : super('Unknown definition type "$type" for state "$id"');
}
