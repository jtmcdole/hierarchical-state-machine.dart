import 'package:hierarchical_state_machine/hierarchical_state_machine.dart';
import 'package:hierarchical_state_machine/plant_uml.dart';

/// Events used to drive the state transitions in the Game Blueprint.
enum GameEvent {
  /// Triggered when the initial loading sequence is complete.
  gameLoaded,

  /// Closes the settings menu and returns to the main menu.
  closeSettings,

  /// Movement region: Transitions from idling to walking.
  move,

  /// Movement region: Transitions from walking to idling.
  stop,

  /// Combat region: Initiates a fight from a peaceful state.
  attack,

  /// Combat region: Abandons a fight to return to a peaceful state.
  flee,

  /// Quits the game
  exitGame,
}

void main() async {
  final gameBlueprint = MachineBlueprint<String, GameEvent>(
    name: 'GameMachine',
    root: .composite(
      id: 'root',
      initial: 'loading',
      on: {.exitGame: .to(target: 'exitApp')},
      children: [
        .composite(
          id: 'loading',
          on: {.gameLoaded: .to(target: 'checkAuth')},
        ),

        .choice(
          id: 'checkAuth',
          defaultTransition: .to(target: 'loginScreen'),
          options: [
            .to(
              target: 'gameplay',
              guard: (e, d) => (d as Map?)?['isLoggedIn'] == true,
            ),
          ],
        ),

        .parallel(
          id: 'gameplay',
          children: [
            .composite(
              id: 'movement',
              initial: 'idle',
              children: [
                .composite(
                  id: 'idle',
                  on: {.move: .to(target: 'walking')},
                ),
                .composite(
                  id: 'walking',
                  on: {.stop: .to(target: 'idle')},
                ),
              ],
            ),
            .composite(
              id: 'combat',
              initial: 'peaceful',
              children: [
                .composite(
                  id: 'peaceful',
                  on: {.attack: .to(target: 'fighting')},
                ),
                .composite(
                  id: 'fighting',
                  on: {
                    .flee: .to(target: 'peaceful'),
                    .stop: .to(target: 'idle'),
                  },
                ),
              ],
            ),
          ],
        ),

        .composite(
          id: 'settingsMenu',
          initial: 'audio',
          on: {
            // Transition triggers shallow history restoration upon re-entry
            .closeSettings: .to(
              target: 'mainMenu',
              kind: .external,
              history: .shallow,
            ),
          },
          children: [
            .composite(id: 'audio'),
            .composite(id: 'video'),

            // Fork Pseudostate targeting multiple regions
            .fork(
              id: 'resumeGame',
              transitions: [
                .to(target: 'walking', history: .deep),
                .to(target: 'fighting', history: .deep),
              ],
            ),
          ],
        ),

        .composite(
          id: 'loginScreen',
          on: {.gameLoaded: .to(target: 'gameplay')},
        ),
        .composite(id: 'mainMenu'),
        .terminate(id: 'exitApp'),
      ],
    ),
  );

  final (machine, errors) = gameBlueprint.compile();

  if (errors.isNotEmpty) {
    print('Validation Errors:');
    for (var error in errors) {
      print('  - $error');
    }
    return;
  }

  print('Machine compiled successfully: ${machine!.name}');

  // Start the machine
  machine.start();
  print('Active states: ${machine.stateString}');

  // Simulate login
  print('Handling gameLoaded with isLoggedIn: true...');
  await machine.handle(.gameLoaded, {'isLoggedIn': true});
  print('Active states: ${machine.stateString}');

  // Move and Attack
  print('Handling move...');
  await machine.handle(.move);
  print('Active states: ${machine.stateString}');

  print('Handling attack...');
  await machine.handle(.attack);
  print('Active states: ${machine.stateString}');

  // Stop moving
  print('Handling stop...');
  await machine.handle(.stop);
  print('Active states: ${machine.stateString}');

  print('Handling flee...');
  await machine.handle(.flee);
  print('Active states: ${machine.stateString}');

  print('Alt-F4');
  await machine.handle(.exitGame);
  print('Active states: ${machine.stateString}');

  print('--- UML');
  print(gameBlueprint.toPlantUml());
}
