enum HomeAvailabilityState { checking, online, offline, unavailable }

class HomeAvailability {
  const HomeAvailability({required this.state, this.hasLocalData = false});

  const HomeAvailability.checking()
    : state = HomeAvailabilityState.checking,
      hasLocalData = false;

  final HomeAvailabilityState state;
  final bool hasLocalData;
}
