part of 'machine.dart';

/// Serialize a hierarchial state machine for storage.
class Serializer<S, E extends Object> {
  /// Serializes [hsm] to a string for offline storage.
  ///
  /// This call waits for the machine to be settled.
  ///
  /// The [S], [E], and [D] data types are not known to this library and require
  /// "toJson()" functions to serialize.
  Future<String> encode(Machine<S, E> hsm) async {
    // Ensure we're settled
    await hsm.settled;

    final output = AccumulatorSink<Digest>();
    final fingerprint = sha1.startChunkedConversion(output);

    final eventPool = <int, EventData<E>>{};

    fingerprint.add(utf8.encode(hsm.name));
    fingerprint.add([0x0]);

    final snapshot = <String, Object?>{
      'name': hsm.name,
      'nextEventId': hsm._nextEventDataId,
    };

    final children = [...hsm._states.values]
      ..sort((a, b) => a.id.toString().compareTo(b.id.toString()));

    snapshot['states'] = [
      for (var child in children)
        _encoderVisitState(child, eventPool, fingerprint),
    ];

    snapshot['deferred'] = [
      for (final e in eventPool.values)
        {'id': e.id, 'event': e.event, 'data': e.data, 'handled': e.handled},
    ];

    fingerprint.close();
    snapshot['fingerprint'] = output.events.first.toString();

    return json.encode(snapshot);
  }

  Map<String, Object?> _encoderVisitState(
    BaseState<S, E> state,
    Map<int, EventData<E>> eventPool,
    ByteConversionSink fingerprint,
  ) {
    fingerprint.add(utf8.encode('${state.id}'));
    fingerprint.add([0x0]);
    fingerprint.add(utf8.encode('${state.type}'));
    fingerprint.add([0x0]);
    final map = <String, Object?>{
      'id': state.id,
      if (state.isActive) 'active': true,
    };

    if (state case State<S, E> composite) {
      final deferredSet = [for (final event in composite.deferEvents) '$event']
        ..sort();
      // I'm adding the deferred events set because changing the deferred queue
      // could cause serious issues with stuck events if an event removed.
      for (final event in deferredSet) {
        fingerprint.add(utf8.encode(event));
        fingerprint.add([0x0]);
      }

      if (composite.deferredQueue.isNotEmpty) {
        final deferrals = <int>[];
        for (var deferral in composite.deferredQueue) {
          deferrals.add(deferral.id);
          eventPool[deferral.id] ??= deferral;
        }
        map['deferrals'] = deferrals;
      }

      if (composite._active case BaseState<S, E> active) {
        map['activeId'] = active.id;
      }

      if (composite._history case BaseState<S, E> history) {
        map['historyId'] = history.id;
      }
    }

    return map;
  }

  Future<String> _calculateFingerprint(Machine<S, E> hsm) async {
    final output = AccumulatorSink<Digest>();
    final fingerprint = sha1.startChunkedConversion(output);

    // Replicate the exact preamble from encode
    fingerprint.add(utf8.encode(hsm.name));
    fingerprint.add([0x0]);

    // Sort and visit states exactly as encode does
    final children = [...hsm._states.values]
      ..sort((a, b) => a.id.toString().compareTo(b.id.toString()));

    for (var child in children) {
      fingerprint.add(utf8.encode('${child.id}'));
      fingerprint.add([0x0]);
      fingerprint.add(utf8.encode('${child.type}'));
      fingerprint.add([0x0]);
      if (child case State<S, E> composite) {
        final deferredSet = [
          for (final event in composite.deferEvents) '$event',
        ]..sort();
        // I'm adding the deferred events set because changing the deferred queue
        // could cause serious issues with stuck events if an event removed.
        for (final event in deferredSet) {
          fingerprint.add(utf8.encode(event));
          fingerprint.add([0x0]);
        }
      }
    }

    fingerprint.close();
    return output.events.first.toString();
  }

  /// Hydrates [source] into the non-running [hsm] and sets it running.
  ///
  /// Validates the definitions haven't changed for the machine or throws a
  /// [FingerprintException]. This could be harmless in the case you have added
  /// new states. To bypass this, set [ignoreFingerPrint] to true.
  ///
  /// The [S], [E], and [D] data types are not known to this library and require
  /// providing [stateFactory], [eventFactory], and [dataFactory] to rehydrate
  /// them.
  Future<void> decode(
    Machine<S, E> hsm,
    String source, {
    bool ignoreFingerPrint = false,
    required S Function(Object) stateFactory,
    required E Function(Object) eventFactory,
    required Object? Function(Object) dataFactory,
  }) async {
    if (hsm.isRunning) throw StateError('The machine is currently running');

    final Map<String, Object?> snapshot = json.decode(source);

    // 1. Integrity Check
    final currentFingerprint = await _calculateFingerprint(hsm);
    if (!ignoreFingerPrint) {
      if (snapshot['fingerprint'] case String storedFingerprint) {
        if (storedFingerprint != currentFingerprint) {
          throw FingerprintException(storedFingerprint, currentFingerprint);
        }
      } else {
        throw FingerprintException(
          '${snapshot['fingerprint']}',
          currentFingerprint,
        );
      }
    }

    // 2. Hydrate Event Pool
    final eventPool = <int, EventData<E>>{};
    if (snapshot['deferred'] case List differed) {
      for (var event in differed) {
        if (event case {
          'id': int id,
          'event': Object event,
          'data': Object? data,
          'handled': bool handled,
        }) {
          final hydrated = EventData<E>(
            eventFactory(event),
            data != null ? dataFactory(data) : data,
            id,
          ).._handled = handled;
          eventPool[id] = hydrated;
        }
      }
    }

    hsm._nextEventDataId = snapshot['nextEventId'] as int;

    // 3. Restore State Data
    if (snapshot['states'] case List states) {
      for (final entry in states) {
        if (entry is! Map<String, Object?>) continue;
        final stateData = entry.cast<String, Object?>();

        final id = stateFactory(stateData['id'] as Object);
        final state = hsm._states[id];
        if (state == null) {
          // This should never happy if the fingerprints matched...
          throw MissingStateError(id, id, 'unable to hydrate missing state');
        }

        if (state case State<S, E> composite) {
          composite.isActive = stateData['active'] == true;
          // Restore Deferred Queue
          if (stateData['deferrals'] case List ids) {
            state.deferredQueue.clear();
            for (final int eventId in ids) {
              if (eventPool[eventId] case var event?) {
                state.deferredQueue.add(event);
              }
            }
          }

          // Restore Pointers
          if (stateData['activeId'] != null) {
            final activeId = stateFactory(stateData['activeId'] as Object);
            state._active = hsm._states[activeId] as State<S, E>?;
          }
          if (stateData['historyId'] != null) {
            final historyId = stateFactory(stateData['historyId'] as Object);
            state._history = hsm._states[historyId] as State<S, E>?;
          }
        }
      }
    }

    _awaken(hsm);
  }

  void _awaken(Machine<S, E> hsm) {
    // We're starting the machine through a special path - calling "enter()"
    // would just corrupt the tree and trigger transitions.
    hsm._running = true;

    // Identify all active states and sort them by depth
    final activeStates = [
      for (final state in hsm._states.values)
        if (state.isActive && state is State<S, E>) state,
    ]..sort((a, b) => a.path.length.compareTo(b.path.length));

    // Trigger onEnter side-effects in top-down order
    // This handles both simple composite paths and parallel regions naturally
    for (final state in activeStates) {
      // call the observer.
      hsm.observer.onStateEnter(state);
      // call developer to handle any state initialization/
      state.onEnter?.call();
    }

    // we're not started.
    hsm.observer.onMachineStarted(hsm);
  }
}

/// Thrown when fingerprints of serialized machines and new blueprints do
/// not match.
class FingerprintException implements Exception {
  /// The fingerprint at rest.
  String stored;

  /// The fingerprint of the machine.
  String calculated;

  /// Thrown when fingerprints of serialized machines and new blueprints do
  /// not match.
  FingerprintException(this.stored, this.calculated);

  @override
  String toString() =>
      'Fingerprint Exception: the stored fingerprint($stored) does not match the machine fingerprint($calculated)';
}
