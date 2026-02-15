# **PRD: HSM Serialization & Restoration (v3)**

## **1. Executive Summary**

This document defines the implementation for state persistence in the HSM library. The goal is to allow a "steady-state" machine to be captured in a JSON format and restored into a new instance, maintaining the exact execution context. This is critical for long-running workflows and cross-session persistence on Mobile, Web, and Server.

## **2. Core Requirements**

### **R1: Steady-State Enforcement**

* **Constraint**: Serialization is only permitted when the machine is "steady".
* **Condition**: `isRunning == true`, `isHandlingEvent == false`, and the `_eventQueue` is empty.
* **Behavior**: Attempting to serialize during a transition will result in a `StateError`.

### **R2: Instance-Scoped Identity**

* **Requirement**: Move `EventData._nextId` from a static context to the `Machine` instance.
* **Rationale**: This ensures that restored machines can continue generating unique IDs without colliding with other machine instances in the same process.

### **R3: Referential Integrity via Global Event Pool**

* **Structure**: The JSON snapshot will contain a "Global Event Pool" mapping `integer ID` to `EventData`.
* **Mapping**: Deferral queues in `State` and the machine's `_eventQueue` will store only the IDs.
* **Rationale**: Ensures that if an event is deferred across multiple regions of a `ParallelState`, it remains a single object reference upon restoration.

### **R4: Data Encoding & JSON Format**

* **Direct JSON**: The final output will be a JSON string to maximize performance and avoid secondary string-to-string conversion overhead.
* **Data Strategy**: `E event` and `D data` will be converted to JSON. If a type does not support `toJson()`, it will be stored as a string.
* **Escaping**: Payloads will be treated as raw strings within the JSON structure to prevent schema clashing.

### **R5: Completer & Future Policy**

* **Policy**: Restored `_eventQueue` items will not have active `Completers`.
* **Guidance**: Documentation will clarify that for UI-bound logic, developers should rely on the `MachineObserver` for event lifecycle updates rather than the `Future` returned by `handle()`.

---

## **3. Technical Specification**

### **3.1 Snapshot Schema (Linear Hierarchy Map)**

The `states` section uses a flattened map keyed by the unique state `id`. This allows the machine to leverage its pre-compiled `_states` map for instant lookup.

```json
{
    "name": "FactoryTestMachine",
    "nextEventId": 2,
    "states": [
        {
            "id": "end"
        },
        {
            "id": "root",
            "active": true,
            "activeId": "s1",
            "historyId": "s1"
        },
        {
            "id": "s1",
            "active": true,
            "deferrals": [
                0,
                1
            ]
        },
        {
            "id": "s2"
        }
    ],
    "deferred": [
        {
            "id": 0,
            "event": "deferMe",
            "data": {
                "msg": "Hello HSM"
            },
            "handled": false
        },
        {
            "id": 1,
            "event": "deferMe",
            "data": "AQIDBA==",
            "handled": false
        }
    ],
    "fingerprint": "93f3b5ac6f68663bf22cb999e58584b39f1ff0a9"
}
```

### **3.2 Restoration Protocol**

1. **Pool Reconstitution**: Hydrate the `EventData` objects from the `eventPool` and initialize the machine's internal `_nextId`.
2. **State Mapping**: Iterate through the snapshot's `states` map. For each entry, locate the corresponding `BaseState` via the machine's pre-compiled `_states[id]`.
3. **Linear Hierarchy Restoration**:

* Set `isActive` and `deferredQueue` (mapping IDs back to the hydrated event pool).
* If `activeChildId` is present, set the state's internal `_active` pointer to the child instance.
* If `historyId` is present, set the state's internal `_history` pointer to that instance.

4. **Work Queue Injection**: Populate the `_eventQueue` with the hydrated events in the order specified.

---

## **4. Safety & Integrity (Phase 2)**

* **Checksum Validation**: Compare the hierarchy fingerprint generated at boot time with the snapshot's checksum to ensure the state machine definition hasn't changed.
* **Blueprint Discrepancy**: Issue a warning if a restored event refers to a state or event type that has been removed from the current machine definition.
