/// Travel mode — independent of accessibility needs.
enum TravelMode {
  solo,
  paAssisted;

  String get displayName {
    switch (this) {
      case TravelMode.solo:
        return 'Solo';
      case TravelMode.paAssisted:
        return 'PA Assisted';
    }
  }

  String get description {
    switch (this) {
      case TravelMode.solo:
        return "I'm travelling independently.";
      case TravelMode.paAssisted:
        return "I'm travelling with a personal assistant, caregiver, friend, or someone helping me.";
    }
  }

  String get iconLabel {
    switch (this) {
      case TravelMode.solo:
        return '🧑';
      case TravelMode.paAssisted:
        return '🤝';
    }
  }
}
