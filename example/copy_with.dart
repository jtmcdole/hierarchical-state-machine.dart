import 'package:hierarchical_state_machine/src/machine.dart';

enum State { root, source, build, test, deploy, approval, promote, terminate }

enum Trigger { next }

void main() async {
  final stagingCiCd = MachineBlueprint<State, Trigger>(
    name: 'staging cicd',
    root: .composite(
      id: .root,
      initial: .source,
      children: [
        .terminate(id: .terminate),
        .composite(
          id: .source,
          entry: () => print('checkout'),
          on: {.next: .to(target: .build)},
        ),
        .composite(
          id: .build,
          entry: () => print('build'),
          on: {.next: .to(target: .test)},
        ),
        .composite(
          id: .test,
          entry: () => print('test'),
          on: {.next: .to(target: .deploy)},
        ),
        .composite(
          id: .deploy,
          entry: () => print('deploy to staging'),
          on: {
            .next: .to(
              target: .terminate,
              action: (_, _) => print('terminate'),
            ),
          },
        ),
      ],
    ),
  );

  final (staging, _) = stagingCiCd.compile();
  await runCiCd(staging!);

  final root = stagingCiCd.findState(.root)!.asComposite;
  final prodCiCd = stagingCiCd
      .copyWith(
        name: (to: 'prod cicd'),
        // Add the new children
        root: root.copyWith(
          children: [
            ...root.children,
            .composite(
              id: State.approval,
              entry: () => print('approval'),
              on: {.next: .to(target: State.promote)},
            ),
            .composite(
              id: State.promote,
              entry: () => print('promote to prod'),
              on: {
                .next: .to(
                  target: State.terminate,
                  action: (_, _) => print('terminate'),
                ),
              },
            ),
          ],
        ),
      )
      // Re-link the existing deploy state to the new approval state.
      .replaceState(
        State.deploy,
        (found) => found.asComposite.copyWith(
          on: (to: {.next: .to(target: State.approval)}),
        ),
      );

  final (prod, _) = prodCiCd.compile();
  await runCiCd(prod!);
}

Future<void> runCiCd(Machine<State, Trigger> hsm) async {
  print('--- starting ${hsm.name} ---');
  hsm.start();
  while (hsm.isRunning) {
    await hsm.handle(.next);
  }
}
