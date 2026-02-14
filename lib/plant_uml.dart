import 'hierarchical_state_machine.dart';

/// Supported separators for parallel regions in PlantUML.
enum ParallelSeparator {
  /// Horizontal separator (`--`).
  horizontal('--'),

  /// Vertical separator (`||`).
  vertical('||');

  /// The PlantUML string representation of the separator.
  final String value;

  const ParallelSeparator(this.value);
}

/// An encoder that converts a [MachineBlueprint] into a PlantUML string.
class PlantUmlEncoder<S, E> {
  /// Options for configuring the layout direction (e.g., 'left to right').
  final String? direction;

  /// Custom PlantUML skin parameters to include in the output.
  final List<String> skinparams;

  /// The separator to use for parallel regions.
  final ParallelSeparator parallelSeparator;

  bool _hasForks = false;

  /// Creates a new [PlantUmlEncoder] with the specified options.
  PlantUmlEncoder({
    this.direction,
    this.skinparams = const [],
    this.parallelSeparator = ParallelSeparator.horizontal,
  });

  /// Encodes the given [blueprint] into a PlantUML string.
  String encode(MachineBlueprint<S, E> blueprint) {
    _hasForks = false;

    scanForForks(BasicBlueprint<S, E> bp) {
      if (bp is ForkBlueprint) {
        return _hasForks = true;
      }
      if (bp is CompositeBlueprint) {
        for (final child in (bp as CompositeBlueprint<S, E>).children) {
          scanForForks(child);
        }
      } else if (bp is ParallelBlueprint) {
        for (final child in (bp as ParallelBlueprint<S, E>).children) {
          scanForForks(child);
        }
      }
    }

    scanForForks(blueprint.root);

    final buffer = StringBuffer();
    buffer.writeln('@startuml');

    if (blueprint.name != null) {
      buffer.writeln('title ${blueprint.name}');
    }

    if (direction != null) {
      buffer.writeln('$direction direction');
    }

    for (final param in skinparams) {
      buffer.writeln('skinparam $param');
    }

    _encodeState(blueprint.root, buffer, 0);
    _encodeTransitions(blueprint.root, buffer);

    buffer.writeln('@enduml');
    return buffer.toString();
  }

  void _encodeState(
    BasicBlueprint<S, E> definition,
    StringBuffer buffer,
    int indent,
  ) {
    final spaces = '  ' * indent;

    if (definition is ChoiceBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} <<choice>>');
    } else if (definition is ForkBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} <<fork>>');
    } else if (definition is FinalBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} <<end>>');
    } else if (definition is TerminateBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} <<end>>');
    } else if (definition is ParallelBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} {');
      _encodeStateDetails(definition, buffer, indent + 1);
      for (var i = 0; i < definition.children.length; i++) {
        if (i > 0 && !_hasForks) {
          buffer.writeln('$spaces  ${parallelSeparator.value}');
        }
        _encodeState(definition.children[i], buffer, indent + 1);
      }
      buffer.writeln('$spaces}');
    } else if (definition is CompositeBlueprint<S, E>) {
      buffer.writeln('${spaces}state ${definition.id} {');
      _encodeStateDetails(definition, buffer, indent + 1);
      if (definition.initial != null) {
        buffer.write('$spaces  [*] --> ${definition.initial}');
        if (definition.initialAction != null) {
          buffer.write(' : / Action()');
        }
        buffer.writeln();
      }
      for (final child in definition.children) {
        _encodeState(child, buffer, indent + 1);
      }
      buffer.writeln('$spaces}');
    } else {
      buffer.writeln('${spaces}state ${definition.id}');
    }
  }

  void _encodeStateDetails(
    BasicBlueprint<S, E> definition,
    StringBuffer buffer,
    int indent,
  ) {
    final spaces = '  ' * indent;
    final id = definition.id;

    if (definition is CompositeBlueprint<S, E>) {
      if (definition.entry != null) {
        buffer.writeln('$spaces$id : onEnter: Action()');
      }
      if (definition.exit != null) {
        buffer.writeln('$spaces$id : onExit: Action()');
      }

      final on = definition.on ?? {};
      for (final entry in on.entries) {
        final event = entry.key;
        final trans = entry.value;
        if (trans.target == null) {
          // Internal transition
          buffer.write('$spaces$id : $event: ');
          if (trans.guard != null) buffer.write(' [Guard()]');
          if (trans.action != null) buffer.write(' / Action()');
          buffer.writeln();
        }
      }

      if (definition.defer.isNotEmpty) {
        buffer.write('$spaces$id : defer:');
        for (final event in definition.defer) {
          buffer.write('\\l  $event,');
        }
        buffer.writeln();
      }
    }
  }

  void _encodeTransitions(
    BasicBlueprint<S, E> definition,
    StringBuffer buffer,
  ) {
    if (definition is ChoiceBlueprint<S, E>) {
      // Default transition
      final def = definition.defaultTransition;
      _writeTransition(buffer, definition.id, def, isDefault: true);

      // Options
      for (final option in definition.options) {
        _writeTransition(buffer, definition.id, option);
      }
    } else if (definition is ForkBlueprint<S, E>) {
      for (final trans in definition.transitions) {
        _writeTransition(buffer, definition.id, trans);
      }
    } else if (definition is CompositeBlueprint<S, E>) {
      final on = definition.on ?? {};
      for (final entry in on.entries) {
        final event = entry.key;
        final trans = entry.value;
        if (trans.target != null) {
          _writeTransition(
            buffer,
            definition.id,
            trans,
            eventLabel: event.toString(),
          );
        }
      }

      for (final child in definition.children) {
        _encodeTransitions(child, buffer);
      }
    }
  }

  void _writeTransition(
    StringBuffer buffer,
    S sourceId,
    dynamic trans, {
    String? eventLabel,
    bool isDefault = false,
  }) {
    if (trans.target == null) return;

    String target = '${trans.target}';

    // Check history type safely
    HistoryType history = switch (trans) {
      TransitionBlueprint<S, E> _ ||
      DefaultTransitionBlueprint<S, E> _ ||
      ForkTransitionBlueprint<S, E> _ ||
      CompletionBlueprint<S, E> _ => trans.history,
      _ => HistoryType.none,
    };

    if (history == HistoryType.deep) {
      target += '[H*]';
    } else if (history == HistoryType.shallow) {
      target += '[H]';
    }

    buffer.write('$sourceId --> $target');

    final labelParts = <String>[];
    if (isDefault) labelParts.add('[else]');
    if (eventLabel != null) labelParts.add(eventLabel);

    // Check guards
    if (trans is TransitionBlueprint<S, E> && trans.guard != null) {
      labelParts.add('[Guard()]');
    } else if (trans is CompletionBlueprint<S, E> && trans.guard != null) {
      labelParts.add('[Guard()]');
    }

    // Check actions
    if (switch (trans) {
      TransitionBlueprint<S, E> _ ||
      DefaultTransitionBlueprint<S, E> _ ||
      ForkTransitionBlueprint<S, E> _ ||
      CompletionBlueprint<S, E> _ => trans.action != null,
      _ => false,
    }) {
      labelParts.add('/ Action()');
    }

    if (labelParts.isNotEmpty) {
      buffer.write(' : ${labelParts.join(' ')}');
    }

    buffer.writeln();
  }
}

/// Extension on [MachineBlueprint] to provide easy PlantUML generation.
extension PlantUmlExtension<S, E> on MachineBlueprint<S, E> {
  /// Converts this blueprint into a PlantUML string representation.
  String toPlantUml({
    String? direction,
    List<String> skinparams = const [],
    ParallelSeparator parallelSeparator = ParallelSeparator.horizontal,
  }) {
    return PlantUmlEncoder<S, E>(
      direction: direction,
      skinparams: skinparams,
      parallelSeparator: parallelSeparator,
    ).encode(this);
  }
}
