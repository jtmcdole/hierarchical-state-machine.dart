# PUBLIC API FOR `library package:hierarchical_state_machine/hierarchical_state_machine.dart`
## Class: `BasicBlueprint`
### Constructors
```dart
  factory BasicBlueprint.choice({required S id, required DefaultTransitionBlueprint<S, E> defaultTransition, List<TransitionBlueprint<S, E>> options});
  factory BasicBlueprint.composite({required S id, Map<E, TransitionBlueprint<S, E>>? on, Set<E> defer, List<CompletionBlueprint<S, E>>? completion, void Function()? entry, void Function()? exit, List<BasicBlueprint<S, E>> children, S? initial, void Function()? initialAction});
  factory BasicBlueprint.finish({required S id});
  factory BasicBlueprint.fork({required S id, required List<ForkTransitionBlueprint<S, E>> transitions});
  BasicBlueprint({required S id});
  factory BasicBlueprint.parallel({required S id, Map<E, TransitionBlueprint<S, E>>? on, List<CompletionBlueprint<S, E>>? completion, void Function()? entry, void Function()? exit, List<BasicBlueprint<S, E>> children});
  factory BasicBlueprint.terminate({required S id});
```
### Fields
```dart
  S id;
```
## Extension: `BasicBlueprintHelpers` on `BasicBlueprint<S, E>`
### Fields / Accessors
```dart
  ChoiceBlueprint<S, E> get asChoice;
  CompositeBlueprint<S, E> get asComposite;
  FinalBlueprint<S, E> get asFinal;
  ForkBlueprint<S, E> get asFork;
  ParallelBlueprint<S, E> get asParallel;
  TerminateBlueprint<S, E> get asTerminate;
  bool get isChoice;
  bool get isComposite;
  bool get isFinal;
  bool get isFork;
  bool get isParallel;
  bool get isTerminate;
```
### Methods
```dart
  BasicBlueprint<S, E>? findState(S id);
  BasicBlueprint<S, E> replaceState(S id, BasicBlueprint<S, E> Function(BasicBlueprint<S, E>) transform);
```
## Class: `ChoiceBlueprint`
### Constructors
```dart
  ChoiceBlueprint({required S id, required DefaultTransitionBlueprint<S, E> defaultTransition, List<TransitionBlueprint<S, E>> options});
```
### Fields
```dart
  DefaultTransitionBlueprint<S, E> defaultTransition;
  List<TransitionBlueprint<S, E>> options;
```
## Extension: `ChoiceBlueprintX` on `ChoiceBlueprint<S, E>`
### Methods
```dart
  ChoiceBlueprint<S, E> copyWith({S? id, DefaultTransitionBlueprint<S, E>? defaultTransition, List<TransitionBlueprint<S, E>>? options});
```
## Class: `CompletionBlueprint`
### Constructors
```dart
  CompletionBlueprint({S? target, bool Function()? guard, void Function()? action, TransitionKind kind, HistoryType history});
  CompletionBlueprint.to({S? target, bool Function()? guard, void Function()? action, TransitionKind kind, HistoryType history});
```
### Fields
```dart
  void Function()? action;
  bool Function()? guard;
  HistoryType history;
  TransitionKind kind;
  S? target;
```
## Extension: `CompletionBlueprintX` on `CompletionBlueprint<S, E>`
### Methods
```dart
  CompletionBlueprint<S, E> copyWith({({S? to})? target, ({bool Function()? to})? guard, ({void Function()? to})? action, TransitionKind? kind, HistoryType? history});
```
## Class: `CompositeBlueprint`
### Constructors
```dart
  CompositeBlueprint({required S id, Map<E, TransitionBlueprint<S, E>>? on, Set<E> defer, List<CompletionBlueprint<S, E>>? completion, void Function()? entry, void Function()? exit, List<BasicBlueprint<S, E>> children, S? initial, void Function()? initialAction});
```
### Fields
```dart
  List<BasicBlueprint<S, E>> children;
  List<CompletionBlueprint<S, E>>? completion;
  Set<E> defer;
  void Function()? entry;
  void Function()? exit;
  S? initial;
  void Function()? initialAction;
  Map<E, TransitionBlueprint<S, E>>? on;
```
## Extension: `CompositeBlueprintX` on `CompositeBlueprint<S, E>`
### Methods
```dart
  CompositeBlueprint<S, E> copyWith({S? id, Set<E>? defer, List<BasicBlueprint<S, E>>? children, ({S? to})? initial, ({Map<E, TransitionBlueprint<S, E>>? to})? on, ({List<CompletionBlueprint<S, E>>? to})? completion, ({void Function()? to})? entry, ({void Function()? to})? exit, ({void Function()? to})? initialAction});
```
## Class: `DefaultTransitionBlueprint`
### Constructors
```dart
  DefaultTransitionBlueprint({required S target, void Function(E?, Object?)? action, TransitionKind kind, HistoryType history});
  DefaultTransitionBlueprint.to({required S target, void Function(E?, Object?)? action, TransitionKind kind, HistoryType history});
```
### Fields
```dart
  void Function(E?, Object?)? action;
  HistoryType history;
  TransitionKind kind;
  S target;
```
## Extension: `DefaultTransitionBlueprintX` on `DefaultTransitionBlueprint<S, E>`
### Methods
```dart
  DefaultTransitionBlueprint<S, E> copyWith({S? target, ({void Function(E?, Object?)? to})? action, TransitionKind? kind, HistoryType? history});
```
## Class: `DuplicateStateIdError`
### Constructors
```dart
  DuplicateStateIdError(S id);
```
### Fields
```dart
  S id;
```
## Class: `FinalBlueprint`
### Constructors
```dart
  FinalBlueprint({required S id});
```
## Class: `FingerprintException`
### Constructors
```dart
  FingerprintException(String stored, String calculated);
```
### Fields
```dart
  String calculated;
  String stored;
```
### Methods
```dart
  String toString();
```
## Class: `ForkBlueprint`
### Constructors
```dart
  ForkBlueprint({required S id, required List<ForkTransitionBlueprint<S, E>> transitions});
```
### Fields
```dart
  List<ForkTransitionBlueprint<S, E>> transitions;
```
## Extension: `ForkBlueprintX` on `ForkBlueprint<S, E>`
### Methods
```dart
  ForkBlueprint<S, E> copyWith({S? id, List<ForkTransitionBlueprint<S, E>>? transitions});
```
## Class: `ForkTransitionBlueprint`
### Constructors
```dart
  ForkTransitionBlueprint({required S target, void Function(E?, Object?)? action, HistoryType history});
  ForkTransitionBlueprint.to({required S target, void Function(E?, Object?)? action, HistoryType history});
```
### Fields
```dart
  void Function(E?, Object?)? action;
  HistoryType history;
  S target;
```
## Extension: `ForkTransitionBlueprintX` on `ForkTransitionBlueprint<S, E>`
### Methods
```dart
  ForkTransitionBlueprint<S, E> copyWith({S? target, ({void Function(E?, Object?)? to})? action, HistoryType? history});
```
## Class: `ForkValidationError`
### Constructors
```dart
  ForkValidationError(S forkId, String details);
```
### Fields
```dart
  String details;
  S forkId;
```
## Enum: `HistoryType`
### Values
`none, shallow, deep`
### Fields
```dart
  List<HistoryType> values;
```
## Class: `HsmState`
### Fields
```dart
  S id;
  bool isActive;
  HsmState<S, E>? parent;
  List<HsmState<S, E>> path;
```
## Class: `InvalidInitialStateError`
### Constructors
```dart
  InvalidInitialStateError(S initialStateId, S parentId);
```
### Fields
```dart
  S initialStateId;
  S parentId;
```
## Class: `InvalidRootError`
### Constructors
```dart
  InvalidRootError();
```
## Class: `Machine`
### Fields
```dart
  bool isHandlingEvent;
  bool isRunning;
  String name;
  MachineObserver<S, E> observer;
  Stream<Machine<S, E>> onSettled;
  void Function()? onTerminated;
  HsmState<S, E> root;
  Future<void> settled;
  String stateString;
```
### Methods
```dart
  HsmState<S, E>? getState(S id);
  Future<bool> handle(E event, [Object? data]);
  bool start();
  bool stop();
  String toString();
```
## Class: `MachineBlueprint`
### Constructors
```dart
  MachineBlueprint({String? name, required BasicBlueprint<S, E> root});
```
### Fields
```dart
  String? name;
  BasicBlueprint<S, E> root;
```
### Methods
```dart
  (Machine<S, E>?, List<ValidationError>) compile({void Function()? onTerminated, MachineObserver<S, E>? observer});
```
## Extension: `MachineBlueprintX` on `MachineBlueprint<S, E>`
### Methods
```dart
  MachineBlueprint<S, E> copyWith({({String? to})? name, BasicBlueprint<S, E>? root});
  BasicBlueprint<S, E>? findState(S id);
  MachineBlueprint<S, E> replaceState(S id, BasicBlueprint<S, E> Function(BasicBlueprint<S, E>) transform);
```
## Class: `MachineObserver`
### Constructors
```dart
  MachineObserver();
```
### Methods
```dart
  void onEventDeferred(HsmState<S, E> state, E event, Object? data);
  void onEventDropped(HsmState<S, E> state, E event, Object? data);
  void onEventError(Machine<S, E> machine, E event, Object? data, Object error, StackTrace stackTrace);
  void onEventHandled(HsmState<S, E> state, E event, Object? data);
  void onEventHandling(Machine<S, E> machine, E event, Object? data);
  void onEventQueued(Machine<S, E> machine, E event, Object? data);
  void onEventUnhandled(HsmState<S, E> state, E event, Object? data);
  void onInternalTransition(HsmState<S, E> state, E? event, Object? data);
  void onMachineStarted(Machine<S, E> machine);
  void onMachineStarting(Machine<S, E> machine);
  void onMachineStopped(Machine<S, E> machine);
  void onMachineTerminated(Machine<S, E> machine);
  void onStateEnter(HsmState<S, E> state);
  void onStateExit(HsmState<S, E> state);
  void onTransition(HsmState<S, E> source, HsmState<S, E> target, E? event, Object? data, TransitionKind kind);
```
## Class: `MissingStateError`
### Constructors
```dart
  MissingStateError(S id, S sourceId, String context);
```
### Fields
```dart
  String context;
  S id;
  S sourceId;
```
## Class: `ParallelBlueprint`
### Constructors
```dart
  ParallelBlueprint({required S id, List<BasicBlueprint<S, E>> children, void Function()? entry, void Function()? exit, Map<E, TransitionBlueprint<S, E>>? on, List<CompletionBlueprint<S, E>>? completion});
```
## Extension: `ParallelBlueprintX` on `ParallelBlueprint<S, E>`
### Methods
```dart
  ParallelBlueprint<S, E> copyWith({S? id, List<BasicBlueprint<S, E>>? children, ({Map<E, TransitionBlueprint<S, E>>? to})? on, ({List<CompletionBlueprint<S, E>>? to})? completion, ({void Function()? to})? entry, ({void Function()? to})? exit});
```
## Class: `PrintObserver`
### Constructors
```dart
  PrintObserver({String Function(String) formatter});
```
### Fields
```dart
  String Function(String) formatter;
```
### Methods
```dart
  void onEventDeferred(HsmState<S, E> state, E event, Object? data);
  void onEventDropped(HsmState<S, E> state, E event, Object? data);
  void onEventError(Machine<S, E> machine, E event, Object? data, Object error, StackTrace stackTrace);
  void onEventHandled(HsmState<S, E> state, E event, Object? data);
  void onEventHandling(Machine<S, E> machine, E event, Object? data);
  void onEventQueued(Machine<S, E> machine, E event, Object? data);
  void onEventUnhandled(HsmState<S, E> state, E event, Object? data);
  void onInternalTransition(HsmState<S, E> state, E? event, Object? data);
  void onMachineStarted(Machine<S, E> machine);
  void onMachineStarting(Machine<S, E> machine);
  void onMachineStopped(Machine<S, E> machine);
  void onMachineTerminated(Machine<S, E> machine);
  void onStateEnter(HsmState<S, E> state);
  void onStateExit(HsmState<S, E> state);
  void onTransition(HsmState<S, E> source, HsmState<S, E> target, E? event, Object? data, TransitionKind kind);
```
## Class: `Serializer`
### Constructors
```dart
  Serializer();
```
### Methods
```dart
  Future<void> decode(Machine<S, E> hsm, String source, {bool ignoreFingerPrint, required S Function(Object) stateFactory, required E Function(Object) eventFactory, required Object? Function(Object) dataFactory});
  Future<String> encode(Machine<S, E> hsm);
```
## Enum: `StateType`
### Values
`composite, parallel, choice, fork, finish, terminate`
### Fields
```dart
  List<StateType> values;
```
## Extension: `StateTypeExtension` on `HsmState<dynamic, dynamic>`
### Fields / Accessors
```dart
  StateType get type;
```
## Class: `TerminateBlueprint`
### Constructors
```dart
  TerminateBlueprint({required S id});
```
## Class: `TransitionBlueprint`
### Constructors
```dart
  factory TransitionBlueprint.any(List<TransitionBlueprint<S, E>> targets);
  TransitionBlueprint({S? target, bool Function(E?, Object?)? guard, void Function(E?, Object?)? action, TransitionKind kind, HistoryType history});
  TransitionBlueprint.to({S? target, bool Function(E?, Object?)? guard, void Function(E?, Object?)? action, TransitionKind kind, HistoryType history});
```
### Fields
```dart
  void Function(E?, Object?)? action;
  bool Function(E?, Object?)? guard;
  HistoryType history;
  TransitionKind kind;
  S? target;
```
## Extension: `TransitionBlueprintX` on `TransitionBlueprint<S, E>`
### Methods
```dart
  TransitionBlueprint<S, E> copyWith({({S? to})? target, ({bool Function(E?, Object?)? to})? guard, ({void Function(E?, Object?)? to})? action, TransitionKind? kind, HistoryType? history});
```
## Enum: `TransitionKind`
### Values
`external, local`
### Fields
```dart
  List<TransitionKind> values;
```
## Class: `UnknownDefinitionTypeError`
### Constructors
```dart
  UnknownDefinitionTypeError(Type type, S id);
```
### Fields
```dart
  S id;
  Type type;
```
## Class: `ValidationError`
### Constructors
```dart
  ValidationError(String message);
```
### Fields
```dart
  String message;
```
### Methods
```dart
  String toString();
```
# PUBLIC API FOR `library package:hierarchical_state_machine/plant_uml.dart`
## Enum: `ParallelSeparator`
### Values
`horizontal, vertical`
### Fields
```dart
  String value;
  List<ParallelSeparator> values;
```
## Class: `PlantUmlEncoder`
### Constructors
```dart
  PlantUmlEncoder({String? direction, List<String> skinparams, ParallelSeparator parallelSeparator});
```
### Fields
```dart
  String? direction;
  ParallelSeparator parallelSeparator;
  List<String> skinparams;
```
### Methods
```dart
  String encode(MachineBlueprint<S, E> blueprint);
```
## Extension: `PlantUmlExtension` on `MachineBlueprint<S, E>`
### Methods
```dart
  String toPlantUml({String? direction, List<String> skinparams, ParallelSeparator parallelSeparator});
```
