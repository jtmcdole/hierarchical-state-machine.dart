import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:hierarchical_state_machine/hierarchical_state_machine.dart';

enum StateId {
  root,
  s1,
  s2,
  end;

  const StateId();

  String toJson() => name;
}

enum EventId {
  toS2,
  deferMe,
  finish;

  const EventId();

  String toJson() => name;
}

class CustomData {
  final String message;
  CustomData(this.message);
  Map<String, dynamic> toJson() => {'msg': message};

  @override
  bool operator ==(Object other) =>
      other is CustomData && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'CustomData($message)';
}

class TestObserver<S, E> extends MachineObserver<S, E> {
  final void Function(Machine<S, E> m, E event, Object? data) eventHandling;

  TestObserver({required this.eventHandling});

  @override
  void onEventHandling(Machine<S, E> machine, E event, Object? data) {
    eventHandling(machine, event, data);
  }
}

void main() {
  group('Serializer Factories', () {
    late Serializer<StateId, EventId> serializer;

    setUp(() {
      serializer = Serializer<StateId, EventId>();
    });

    Machine<StateId, EventId> createMachine({
      MachineObserver<StateId, EventId>? observer,
    }) {
      final blueprint = MachineBlueprint<StateId, EventId>(
        name: 'FactoryTestMachine',
        root: .composite(
          id: StateId.root,
          initial: StateId.s1,
          children: [
            .composite(
              id: StateId.s1,
              defer: {EventId.deferMe},
              on: {EventId.toS2: .to(target: StateId.s2)},
            ),
            .composite(
              id: StateId.s2,
              on: {EventId.finish: .to(target: StateId.end)},
            ),
            .finish(id: StateId.end),
          ],
        ),
      );
      final (machine, errors) = blueprint.compile(observer: observer);
      if (errors.isNotEmpty) {
        fail('Failed to compile machine: $errors');
      }
      return machine!;
    }

    test('Hydrates enum states, enum events, and complex data', () async {
      final m1 = createMachine();
      m1.start();

      // Defer an event with custom data
      final customData = CustomData('Hello HSM');
      await m1.handle(EventId.deferMe, customData);

      // Defer an event with raw bytes (base64)
      final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
      await m1.handle(EventId.deferMe, base64Encode(rawBytes));

      final json = await serializer.encode(m1);

      // Create a fresh machine to decode into
      final handledEvents = <(EventId, Object?)>[];
      final observer = TestObserver<StateId, EventId>(
        eventHandling: (m, e, d) {
          handledEvents.add((e, d));
        },
      );

      final m2 = createMachine(observer: observer);

      await serializer.decode(
        m2,
        json,
        stateFactory: (obj) => StateId.values.byName(obj as String),
        eventFactory: (obj) => EventId.values.byName(obj as String),
        dataFactory: (obj) {
          if (obj is Map<String, dynamic> && obj.containsKey('msg')) {
            return CustomData(obj['msg'] as String);
          }
          if (obj is String && obj.length == 8) {
            try {
              return base64Decode(obj);
            } catch (_) {}
          }
          return obj;
        },
      );

      // Verify m2 state
      expect(m2.isRunning, isFalse);
      m2.start();

      expect(m2.stateString, contains('s1'));
      handledEvents.clear();

      // Transition to s2 to trigger replay of deferred events
      await m2.handle(EventId.toS2);
      expect(m2.stateString, contains('s2'));

      // Wait for replayed events to settle
      await m2.settled;

      // WTF: why are the deferred events queued up first?

      // We expect: toS2, then the two deferred events replayed
      expect(handledEvents.length, equals(3));
      expect(handledEvents[0].$1, equals(EventId.toS2));
      expect(handledEvents[1].$1, equals(EventId.deferMe));
      expect(handledEvents[1].$2, isA<CustomData>());
      expect((handledEvents[1].$2 as CustomData).message, equals('Hello HSM'));

      expect(handledEvents[2].$1, equals(EventId.deferMe));
      expect(handledEvents[2].$2, isA<Uint8List>());
      expect(handledEvents[2].$2 as Uint8List, equals(rawBytes));
    });

    test('dataFactory with null data', () async {
      final m1 = createMachine();
      m1.start();
      await m1.handle(EventId.deferMe, null);

      final json = await serializer.encode(m1);
      final m2 = createMachine();

      await serializer.decode(
        m2,
        json,
        stateFactory: (obj) => StateId.values.byName(obj as String),
        eventFactory: (obj) => EventId.values.byName(obj as String),
        dataFactory: (obj) => obj,
      );

      m2.start();
      // Verify it doesn't crash and handled null
    });
  });
}
