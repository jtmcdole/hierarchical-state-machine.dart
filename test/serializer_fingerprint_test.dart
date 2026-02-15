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

      try {
        await serializer.decode(
          createMachine(name: 'MachineB'),
          json,
          stateFactory: (id) => id as String,
          eventFactory: (e) => e as String,
          dataFactory: (d) => d,
        );
      } catch (e) {
        expect(
          '$e',
          contains(
            'fingerprint(abadc2e48d8f7b48823125d6ed79ea6ed0f395b0) does not match the machine fingerprint(aaf26f27b891df4dc1e120194e9702073c25f01f)',
          ),
        );
      }
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

    test(
      'Hydration fails if state is missing from machine (corrupted JSON)',
      () async {
        final machine1 = createMachine(children: [.composite(id: 'state_a')]);
        final json = await serializer.encode(machine1);

        // Manually corrupt the JSON by changing 'state_a' to 'STATE_A'.
        // This bypasses the fingerprint check because the machine structure
        // (machine2) still matches the fingerprint in the JSON, but the
        // data itself is now inconsistent.
        final corruptedJson = json.replaceFirst('"state_a"', '"STATE_A"');

        final machine2 = createMachine(children: [.composite(id: 'state_a')]);

        expect(
          () => serializer.decode(
            machine2,
            corruptedJson,
            stateFactory: (id) => id as String,
            eventFactory: (e) => e as String,
            dataFactory: (d) => d,
          ),
          throwsA(isA<MissingStateError>()),
        );
      },
    );
  });
}
