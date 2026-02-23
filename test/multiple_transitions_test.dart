import 'package:test/test.dart';
import 'package:hierarchical_state_machine/src/machine.dart';

import 'test_observer.dart';

enum Event { one, two, three }

enum States { root, on, off, test }

void main() {
  late Machine<States, Event> hsm;
  late MachineBlueprint<States, Event> blueprint;

  setUp(() {
    blueprint = .new(
      root: .composite(
        id: .root,
        initial: .on,
        children: [
          .composite(
            id: .on,
            on: {
              .one: .any([
                .to(target: .off, guard: (_, data) => data == 1),
                .to(target: .test, guard: (_, data) => data == -1),
              ]),
            },
          ),
          .composite(id: .off),
          .composite(id: .test),
        ],
      ),
    );
    final (machine, errors) = blueprint.compile(
      observer: const TestPrintObserver(),
    );
    expect(errors, isEmpty, reason: 'machine is valid');
    hsm = machine!;
    hsm.start();
  });

  test('transitions to "off" for 1', () async {
    expect(hsm.getState(.off)!.isActive, isFalse);
    await hsm.handle(.one, 1);
    expect(hsm.getState(.off)!.isActive, isTrue);
  });
  test('transitions to "test" for -1', () async {
    expect(hsm.getState(.off)!.isActive, isFalse);
    await hsm.handle(.one, -1);
    expect(hsm.getState(.test)!.isActive, isTrue);
  });
  test('transitions nowhere for failing guards', () async {
    expect(hsm.getState(.off)!.isActive, isFalse);
    await hsm.handle(.one, 42);
    expect(hsm.getState(.test)!.isActive, isFalse);
    expect(hsm.getState(.off)!.isActive, isFalse);
    expect(hsm.getState(.on)!.isActive, isTrue);
  });
}
