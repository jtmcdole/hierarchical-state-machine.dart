import 'package:hierarchical_state_machine/hierarchical_state_machine.dart';
import 'package:hierarchical_state_machine/plant_uml.dart';
import 'package:test/test.dart';

void main() {
  group('PlantUmlEncoder Foundation', () {
    test('MachineBlueprint extension toPlantUml exists', () {
      final blueprint = MachineBlueprint(
        name: 'SimpleMachine',
        root: .composite(
          id: 'Root',
          children: [.composite(id: 'State1')],
          initial: 'State1',
        ),
      );

      final plantUml = blueprint.toPlantUml();
      expect(plantUml, contains('@startuml'));
      expect(plantUml, contains('state Root {'));
      expect(plantUml, contains('state State1'));
      expect(plantUml, contains('@enduml'));
    });

    test('PlantUmlEncoder basic encoding', () {
      final blueprint = MachineBlueprint(
        name: 'SimpleMachine',
        root: .composite(
          id: 'Root',
          children: [.composite(id: 'State1')],
          initial: 'State1',
        ),
      );

      final encoder = PlantUmlEncoder();
      final result = encoder.encode(blueprint);

      expect(result, contains('@startuml'));
      expect(result, contains('title SimpleMachine'));
      expect(result, contains('state Root {'));
      expect(result, contains('state State1'));
      expect(result, contains('@enduml'));
    });

    test('PlantUmlEncoder with direction and skinparams', () {
      final blueprint = MachineBlueprint(
        root: .composite(
          id: 'Root',
          children: [.composite(id: 'State1')],
        ),
      );

      final encoder = PlantUmlEncoder(
        direction: 'left to right',
        skinparams: ['monochrome true', 'shadowing false'],
      );
      final result = encoder.encode(blueprint);

      expect(result, contains('left to right direction'));
      expect(result, contains('skinparam monochrome true'));
      expect(result, contains('skinparam shadowing false'));
      expect(result, contains('state Root {'));
      expect(result, contains('state State1'));
    });

    test('PlantUmlEncoder nested hierarchy and initial states', () {
      final blueprint = MachineBlueprint(
        name: 'NestedMachine',
        root: .composite(
          id: 'Root',
          initial: 'Parent',
          children: [
            .composite(
              id: 'Parent',
              initial: 'Child1',
              children: [
                .composite(id: 'Child1'),
                .composite(id: 'Child2'),
              ],
            ),
          ],
        ),
      );

      final result = blueprint.toPlantUml();

      expect(result, contains('state Root {'));
      expect(result, contains('[*] --> Parent'));
      expect(result, contains('  state Parent {'));
      expect(result, contains('  [*] --> Child1'));
      expect(result, contains('    state Child1'));
      expect(result, contains('    state Child2'));
      expect(result, contains('  }'));
      expect(result, contains('}'));
    });

    test('PlantUmlEncoder parallel states', () {
      final blueprint = MachineBlueprint(
        name: 'ParallelMachine',
        root: .parallel(
          id: 'Root',
          children: [
            .composite(id: 'Region1'),
            .composite(id: 'Region2'),
          ],
        ),
      );

      final result = blueprint.toPlantUml(
        parallelSeparator: ParallelSeparator.vertical,
      );

      expect(result, contains('state Root {'));
      expect(result, contains('  ||'));
      expect(result, contains('  state Region1'));
      expect(result, contains('  state Region2'));
      expect(result, contains('}'));
    });
  });

  group('Verification', () {
    test('Visualize Parallel Machine', () async {
      final blueprint = MachineBlueprint(
        name: 'ParallelMachine',
        root: .parallel(
          id: 'Root',
          children: [
            .composite(
              id: 'Region1',
              entry: () {},
              exit: () {},
              defer: {'event1', 'event2'},
              on: {'event1': .to(guard: (_, _) => true, action: (_, _) {})},
              children: [.composite(id: 'Sub1')],
            ),
            .composite(
              id: 'Region2',
              children: [.composite(id: 'Sub2')],
            ),
          ],
        ),
      );

      final result = blueprint.toPlantUml(
        parallelSeparator: ParallelSeparator.vertical,
      );
      expect(result, contains('state Root {'));
      expect(result, contains('  ||'));
    });

    test('PlantUmlEncoder transitions and labels', () {
      final blueprint = MachineBlueprint(
        name: 'TransitionMachine',
        root: .composite(
          id: 'Root',
          children: [
            .composite(
              id: 'A',
              on: {
                'E1': .to(target: 'B'),
                'E2': .to(
                  target: 'A',
                  guard: (_, data) => true,
                  action: (_, data) {},
                ),
              },
            ),
            .composite(id: 'B'),
          ],
        ),
      );

      final result = blueprint.toPlantUml();

      expect(result, contains('A --> B : E1'));
      expect(result, contains('A --> A : E2 [Guard()] / Action()'));
    });

    test('PlantUmlEncoder pseudo-states: Choice and History', () {
      final blueprint = MachineBlueprint(
        name: 'PseudoMachine',
        root: .composite(
          id: 'Root',
          initial: 'MyChoice',
          initialAction: () => {},
          children: [
            .composite(id: 'A'),
            .choice(
              id: 'MyChoice',
              defaultTransition: .to(target: 'A', action: (_, _) {}),
              options: [
                .to(
                  target: 'B',
                  guard: (_, _) => true,
                  action: (_, _) {},
                  history: HistoryType.shallow,
                ),
                .to(
                  target: 'B',
                  guard: (_, _) => true,
                  action: (_, _) {},
                  history: HistoryType.deep,
                ),
              ],
            ),
            .composite(
              id: 'B',
              children: [
                .composite(
                  id: 'B1',
                  children: [
                    .composite(id: 'B11'),
                    .composite(id: 'B12'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final result = blueprint.toPlantUml();

      expect(result, contains('state MyChoice <<choice>>'));
      expect(result, contains('MyChoice --> B[H]'));
      expect(result, contains('MyChoice --> B[H*]'));
    });

    test(
      'PlantUmlEncoder pseudo-states: Final, Terminate, Fork with History',
      () {
        final blueprint = MachineBlueprint(
          name: 'ComplexPseudoMachine',
          root: .composite(
            id: 'Root',
            children: [
              .composite(
                id: 'Source',
                on: {'ForkEvent': .to(target: 'MyFork')},
              ),
              .fork(
                id: 'MyFork',
                transitions: [
                  .to(target: 'Region1', history: HistoryType.shallow),
                  .to(target: 'Region2', history: HistoryType.deep),
                ],
              ),
              .parallel(
                id: 'DestParallel',
                children: [
                  .composite(
                    id: 'Region1',
                    children: [
                      .composite(
                        id: 'r1a',
                        on: {
                          'finish': .to(target: 'Done'),
                          'event': .to(target: 'r1b'),
                        },
                      ),
                      .composite(id: 'r1b'),
                      .finish(id: 'Done'),
                    ],
                  ),
                  .composite(
                    id: 'Region2',
                    children: [
                      .composite(
                        id: 'r2a',
                        on: {
                          'die': .to(target: 'Kill'),
                          'event': .to(target: 'r2b'),
                        },
                      ),
                      .composite(id: 'r2b'),
                      .terminate(id: 'Kill'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        final result = blueprint.toPlantUml();

        expect(result, contains('state MyFork <<fork>>'));
        expect(result, contains('state Done <<end>>'));
        expect(result, contains('state Kill <<end>>'));
        expect(result, contains('Source --> MyFork : ForkEvent'));
        expect(result, contains('MyFork --> Region1[H]'));
        expect(result, contains('MyFork --> Region2[H*]'));
      },
    );

    test('PlantUmlEncoder initial action', () {
      final blueprint = MachineBlueprint(
        name: 'InitialActionMachine',
        root: .composite(
          id: 'Root',
          initial: 'A',
          initialAction: () {},
          children: [.composite(id: 'A')],
        ),
      );

      final result = blueprint.toPlantUml();

      expect(result, contains('[*] --> A : / Action()'));
    });
  });
}
