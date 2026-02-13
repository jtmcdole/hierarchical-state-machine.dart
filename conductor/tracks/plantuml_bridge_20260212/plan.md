# Implementation Plan: PlantUML Visualization Bridge

This plan outlines the implementation of a PlantUML encoder for `MachineBlueprint`, allowing visual representation of hierarchical state machines.

## Phase 1: Foundation & Basic States

- [ ] Task: Create `lib/plant_uml.dart` with basic `PlantUmlEncoder` and `MachineBlueprint` extension.
- [ ] Task: Implement `encode` method header/footer logic (`@startuml` / `@enduml`).
- [ ] Task: Implement basic configuration options (Direction, Skinparams).
- [ ] Task: Write tests for a single-state machine visualization.
- [ ] Task: Implement leaf state declaration logic.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Foundation & Basic States' (Protocol in workflow.md)

## Phase 2: Hierarchy & Parallel Regions

- [ ] Task: Implement recursive traversal for composite states using `state Name { ... }`.
- [ ] Task: Implement initial state representation (`[*] --> Initial`).
- [ ] Task: Implement parallel state support with configurable separators (`--` or `||`).
- [ ] Task: Write tests for nested hierarchies and parallel regions.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Hierarchy & Parallel Regions' (Protocol in workflow.md)

## Phase 3: Transitions & Labels

- [ ] Task: Implement transition mapping pass.
- [ ] Task: Implement event label formatting.
- [ ] Task: Implement guard and action placeholder logic (`Guard()` / `Action()`).
- [ ] Task: Write tests for various transition types (internal, external, cross-hierarchy).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Transitions & Labels' (Protocol in workflow.md)

## Phase 4: Pseudo-states & Metadata

- [ ] Task: Implement mapping for `ChoiceState` (`<<choice>>`).
- [ ] Task: Implement mapping for `HistoryState` (`[H]`, `[H*]`).
- [ ] Task: Implement mapping for `FinalState` (`[*]`).
- [ ] Task: Implement mapping for `TerminateState` (`<<end>>`).
- [ ] Task: Implement mapping for `ForkState` and `Join` semantics.
- [ ] Task: Write integration tests covering all pseudo-states.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Pseudo-states & Metadata' (Protocol in workflow.md)
