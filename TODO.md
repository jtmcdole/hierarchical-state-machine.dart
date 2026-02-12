# TODO work

- [ ] Remove logging package requirement. Offer some other, optional observer.
- [ ] Expand docs folder with examples
- [ ] Review exposed API for leaking information / responsibility
- [x] Review formal UML features (e.g. history, event deferral)
- [ ] Ensure FinalState is not delivered any messages or transitions
- [ ] Ensure Regions that enter a final state notify Parallel state
- [ ] Ensure that all regions entering final state triggers completion handlers in parallel parent.