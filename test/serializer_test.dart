import 'package:test/test.dart';
import 'package:hierarchical_state_machine/hierarchical_state_machine.dart';

void main() {
  late Serializer<String, String> serializer;

  setUp(() {
    serializer = Serializer<String, String>();
  });
  test('Parallel regions preserve active states and history', () async {
    final blueprint = MachineBlueprint<String, String>(
      name: 'ParallelTest',
      root: .composite(
        id: 'root',
        initial: 'p',
        children: [
          .parallel(
            id: 'p',
            children: [
              .composite(
                id: 'r1',
                initial: 'r1_a',
                children: [
                  .composite(
                    id: 'r1_a',
                    on: {'go_r1_b': .to(target: 'r1_b')},
                  ),
                  .composite(id: 'r1_b'),
                ],
              ),
              .composite(
                id: 'r2',
                initial: 'r2_a',
                children: [
                  .composite(
                    id: 'r2_a',
                    on: {'go_r2_b': .to(target: 'r2_b')},
                  ),
                  .composite(id: 'r2_b'),
                ],
              ),
            ],
          ),
          .composite(id: 'other'),
        ],
      ),
    );

    final (m1, _) = blueprint.compile();
    m1!.start();

    // Move r1 to 'b', leave r2 at 'a'
    await m1.handle('go_r1_b');
    expect(m1.stateString, contains('r1_b'));
    expect(m1.stateString, contains('r2_a'));

    final json = await serializer.encode(m1);

    // Fresh machine
    final (m2, _) = blueprint.compile();
    await serializer.decode(
      m2!,
      json,
      stateFactory: (id) => id as String,
      eventFactory: (e) => e as String,
      dataFactory: (d) => d,
    );

    expect(m2.isRunning, isTrue);
    expect(m2.stateString, contains('r1_b'));
    expect(m2.stateString, contains('r2_a'));
  });
}
