import 'package:test/test.dart';
import 'dart:convert';
import 'package:hierarchical_state_machine/hierarchical_state_machine.dart';

void main() {
  group('Fingerprint exceptions', () {
    late Serializer<String, String> serializer;

    setUp(() {
      serializer = Serializer<String, String>();
    });

    Machine<String, String> createMachine({
      String name = 'TestMachine',
      List<BasicBlueprint<String, String>> children = const [],
      String? initial,
    }) {
      final blueprint = MachineBlueprint<String, String>(
        name: name,
        root: .composite(id: 'root', initial: initial, children: children),
      );
      final (machine, errors) = blueprint.compile();
      if (errors.isNotEmpty) {
        fail('Failed to compile machine: $errors');
      }
      return machine!;
    }

    test('Basic machine fingerprint checks', () async {
      final machine1 = createMachine(name: 'MachineA');
      final json = await serializer.encode(machine1);
      final machine2 = createMachine(name: 'MachineA');
      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        completes,
      );
    });

    test('Machine name change causes fingerprint mismatch', () async {
      final machine1 = createMachine(name: 'MachineA');
      final json = await serializer.encode(machine1);
      final machine2 = createMachine(name: 'MachineB');

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('State name (ID) change causes fingerprint mismatch', () async {
      final machine1 = createMachine(children: [.composite(id: 'StateA')]);
      final json = await serializer.encode(machine1);

      final machine2 = createMachine(children: [.composite(id: 'StateB')]);

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('Deleting and merging states causes fingerprint mismatch', () async {
      // Machine with A and B
      final machine1 = createMachine(
        children: [
          .composite(id: 'A'),
          .composite(id: 'B'),
        ],
      );
      final json = await serializer.encode(machine1);

      // Machine with merged AB
      final machine2 = createMachine(children: [.composite(id: 'AB')]);

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('State type change causes fingerprint mismatch', () async {
      // StateA is composite
      final machine1 = createMachine(children: [.composite(id: 'StateA')]);
      final json = await serializer.encode(machine1);

      // StateA is final
      final machine2 = createMachine(children: [.finish(id: 'StateA')]);

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('Deferrals change causes fingerprint mismatch', () async {
      final machine1 = createMachine(
        children: [
          .composite(id: 'StateA', defer: {'Event1'}),
        ],
      );
      final json = await serializer.encode(machine1);

      final machine2 = createMachine(
        children: [
          .composite(id: 'StateA', defer: {'Event2'}),
        ],
      );

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('Adding/removing a deferral causes fingerprint mismatch', () async {
      final machine1 = createMachine(
        children: [
          .composite(id: 'StateA', defer: {'Event1'}),
        ],
      );
      final json = await serializer.encode(machine1);

      final machine2 = createMachine(
        children: [
          .composite(id: 'StateA', defer: {'Event1', 'Event2'}),
        ],
      );

      expect(
        serializer.decode(
          machine2,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('Missing fingerprint in JSON causes mismatch', () async {
      final machine = createMachine();
      final snapshot = {
        'name': machine.name,
        'nextEventId': 0,
        'states': [],
        'deferred': [],
      };
      final json = jsonEncode(snapshot);

      expect(
        serializer.decode(
          machine,
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        ),
        throwsA(isA<FingerprintException>()),
      );
    });

    test('ignoreFingerPrint: true bypasses check', () async {
      final machine1 = createMachine(name: 'MachineA');
      final json = await serializer.encode(machine1);

      final machine2 = createMachine(name: 'MachineB');

      await serializer.decode(
        machine2,
        json,
        ignoreFingerPrint: true,
        stateFactory: (id) => id as String,
        eventFactory: (e) => e as String,
        dataFactory: (d) => d,
      );
      // No exception thrown
    });
  });
}
