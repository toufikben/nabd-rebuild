// Session access — the single rule for what the runner may start.

/// Whether the runner must show the paywall for a session. The entitlement
/// comes from the store-backed `MonetizationState`, never from a compile-time
/// constant, so a paying customer reaches the paid catalogue.
bool sessionIsLocked({required bool isFree, required bool isPro}) =>
    !isFree && !isPro;
