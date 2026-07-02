# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-07-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`hierarchical_state_machine` - `v2.4.0`](#hierarchical_state_machine---v240)

---

#### `hierarchical_state_machine` - `v2.4.0`

 - **FIX**: allow duplicate events with guards in blueprint (#15).
 - **FIX**: flutter's pinning of meta... (#12).
 - **FEAT**(machine): provide Serializer<S,E> from machine.
 - **FEAT**: add copyWith() functionality to blueprints (#16).
 - **FEAT**: serialization and deserialization of machines (#11).
 - **FEAT**: Export blueprints for rendering with PlantUML (#9).

## 2.4.0

 - **FIX**: allow duplicate events with guards in blueprint (#15).
 - **FIX**: flutter's pinning of meta... (#12).
 - **FEAT**(machine): provide Serializer<S,E> from machine.
 - **FEAT**: add copyWith() functionality to blueprints (#16).
 - **FEAT**: serialization and deserialization of machines (#11).
 - **FEAT**: Export blueprints for rendering with PlantUML (#9).

# Hierarchial State Machine

## 2.3.0

* feat: copyWith() extensions to blueprints
* feat: find / replace extensions for machine & state blueprints.

## 2.2.2

* fix: allow duplicate events with guards in blueprint.

## 2.2.1

* reduce dependency version for flutter stable

## 2.2.0

* serialization and deserialization of machines
* internal: moved event numbering to each machine instance.

## 2.1.1

* pub.dev points are annoying

## 2.1.0

* Optional library to produce plantuml diagrams.
* `.to()` constructor for all transition blueprints.
* All `dynamic` -> `Object?` (should be non-breaking)
* `StateType` for runtime identification.
* Documentation updates.

## 2.0.0

2.0.0: PSSM Update

* Event Deferrals
* Fork, Choice, Terminate, and Final Psuedo states
* Deep and Shallow history
* Blueprints for cleaner composition
* Validation before starting an invalid machine
* Performance boost by precalculating all LCAs, state chains, and more.

## 1.0.0

Increased version number to 1.0 as the package is fairly stable.

## 0.0.2

* Update deps for dart 3.0

## 0.0.1

* Early release publishing
