# Specification: PlantUML Visualization Bridge

## Overview
This track implements a visualization bridge for the `hierarchical_state_machine` library. It provides a way to convert a `MachineBlueprint` into a PlantUML string representation, allowing developers to generate statechart diagrams.

## Functional Requirements
- **Location:** The library will be located at `lib/plant_uml.dart`.
- **API Surface:**
    - `PlantUmlEncoder` class for manual encoding.
    - Extension on `MachineBlueprint` (`toPlantUml()`) for convenience.
- **State Representation:**
    - Recursive traversal of the state tree.
    - Composite states rendered using `state Name { ... }`.
    - **Parallel Regions:** Regions within a parallel state must be separated by a configurable separator.
        - Supported separators: Horizontal (`--`) and Vertical (`||`).
    - Initial states rendered as `[*] --> InitialState`.
- **Transition Mapping:**
    - Format: `Source --> Target : Event [Guard] / Action`.
    - Labels: Use `"Guard()"` if a guard function is present and `"Action()"` if an action is present.
- **Pseudo-state Support:**
    - Choice states mapped to `<<choice>>`.
    - History states mapped to `[H]` (shallow) and `[H*]` (deep).
    - Final states mapped to `[*]`.
    - Terminate states mapped to `<<end>>`.
    - Forks/Joins mapped to `<<fork>>` and `<<join>>`.
- **Formatting Options:**
    - Support for layout direction (Top-to-bottom vs. Left-to-right).
    - Support for custom `skinparam` blocks.
    - **Parallel Separator:** Flag to choose between `--` (default) and `||`.

## Non-Functional Requirements
- **Zero Dependencies:** No external dependencies other than the core HSM library and Dart SDK.
- **Unique IDs:** Assume state IDs are unique and can be used directly as PlantUML identifiers.

## Acceptance Criteria
- [ ] A `MachineBlueprint` can be converted to a valid PlantUML string.
- [ ] Nested hierarchies are correctly represented.
- [ ] Parallel regions are correctly separated using the configured separator.
- [ ] Transitions include event names and placeholders for guards and actions.
- [ ] All pseudo-states (Choice, History, Final, Terminate, Fork/Join) are correctly mapped.
