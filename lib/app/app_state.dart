import 'dart:async';

import 'package:access_map/core/services/geocoding_service.dart';
import 'package:access_map/core/services/navigation_service.dart';
import 'package:access_map/core/services/voice_search_service.dart';
import 'package:access_map/features/map/data/mock_place_repository.dart';
import 'package:access_map/features/map/domain/live_map_explorer.dart';
import 'package:access_map/features/summaries/domain/community_summary.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  AppState({
    PlaceRepository? placeRepository,
    VoiceSearchService? voiceSearchService,
    NavigationService? navigationService,
    GeocodingService? geocodingService,
    CommunitySummaryService? communitySummaryService,
  }) : _placeRepository = placeRepository ?? MockPlaceRepository(),
       _voiceSearchService = voiceSearchService ?? SpeechToTextService(),
       _navigationService = navigationService ?? NavigationService(),
       _geocodingService = geocodingService ?? const GeocodingService(),
       _communitySummaryService =
           communitySummaryService ??
           const UnconfiguredCommunitySummaryService();

  final PlaceRepository _placeRepository;
  final VoiceSearchService _voiceSearchService;
  final NavigationService _navigationService;
  final GeocodingService _geocodingService;
  final CommunitySummaryService _communitySummaryService;

  GeocodingService get geocodingService => _geocodingService;
  PlaceRepository get placeRepository => _placeRepository;
  Future<CommunitySummary> communitySummary(String placeId) =>
      _communitySummaryService.forPlace(placeId);

  UserProfile _profile = UserProfile.mockUser().copyWith(
    onboardingComplete: false,
    accessibilityNeeds: const [],
  );
  List<Place> _places = [];
  List<Place> _visiblePlaces = [];
  Place? _selectedPlace;
  String _searchQuery = '';
  bool _isLoadingPlaces = true;
  bool _isSearching = false;
  bool _hasSelectedTravelMode = false;
  String? _errorMessage;
  int _tabIndex = 0;
  final Set<String> _reportedPlaceIds = {};
  final Map<String, String> _lastReportReasons = {};
  final Set<AccessibilityCriterion> _essentialRequirements = {};
  bool _verifiedEssentialsOnly = false;
  double _mapLatitude = 15.4909;
  double _mapLongitude = 73.8278;

  UserProfile get profile => _profile;
  List<Place> get places => _places;
  List<Place> get visiblePlaces => _visiblePlaces;
  Place? get selectedPlace => _selectedPlace;
  String get searchQuery => _searchQuery;
  bool get isLoadingPlaces => _isLoadingPlaces;
  bool get isSearching => _isSearching;
  bool get isListening => _voiceSearchService.isListening;
  bool get hasSelectedTravelMode => _hasSelectedTravelMode;
  String? get errorMessage => _errorMessage;
  int get tabIndex => _tabIndex;
  Set<AccessibilityCriterion> get essentialRequirements =>
      Set.unmodifiable(_essentialRequirements);
  bool get verifiedEssentialsOnly => _verifiedEssentialsOnly;
  double get mapLatitude => _mapLatitude;
  double get mapLongitude => _mapLongitude;

  // --- Live Accessibility Explorer -------------------------------------
  ExplorerRadius _explorerRadius = ExplorerRadius.fiveKm;
  ExplorerCategory? _explorerCategory;
  double? _userLatitude;
  double? _userLongitude;
  LocationLookupStatus? _locationStatus;
  bool _isLocating = false;
  LiveUpdatesStatus _liveUpdatesStatus = LiveUpdatesStatus.unsupported;
  Future<void> Function()? _cancelLiveUpdates;
  Timer? _liveRefreshDebounce;
  bool _liveRefreshFailed = false;
  DateTime? _lastLiveRefresh;

  ExplorerRadius get explorerRadius => _explorerRadius;
  ExplorerCategory? get explorerCategory => _explorerCategory;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;

  /// Null until a lookup has been attempted.
  LocationLookupStatus? get locationStatus => _locationStatus;
  bool get isLocating => _isLocating;
  LiveUpdatesStatus get liveUpdatesStatus => _liveUpdatesStatus;
  bool get liveRefreshFailed => _liveRefreshFailed;
  DateTime? get lastLiveRefresh => _lastLiveRefresh;

  /// Accessibility criteria that matter for the current profile.
  Set<AccessibilityCriterion> get relevantCriteria =>
      const SuitabilityEvaluator().relevantCriteria(
        _profile.accessibilityNeeds,
        essentials: _essentialRequirements,
      );

  SuitabilityResult suitabilityFor(Place place) =>
      const SuitabilityEvaluator().evaluate(place, relevantCriteria);

  /// Places (or current search results) inside the selected radius and
  /// category, nearest first.
  List<Place> get explorerPlaces => rankForRequirements(
    filterExplorerPlaces(
      _visiblePlaces,
      centerLatitude: _mapLatitude,
      centerLongitude: _mapLongitude,
      radius: _explorerRadius,
      category: _explorerCategory,
    ),
  );

  void setExplorerRadius(ExplorerRadius radius) {
    _explorerRadius = radius;
    notifyListeners();
  }

  void setExplorerCategory(ExplorerCategory? category) {
    _explorerCategory = category;
    notifyListeners();
  }

  /// Reads the device location and reloads nearby places around it.
  Future<LocationLookupStatus> locateUser() async {
    if (_isLocating) return _locationStatus ?? LocationLookupStatus.unavailable;
    _isLocating = true;
    notifyListeners();
    final lookup = await _geocodingService.locate(resolveAddress: false);
    _locationStatus = lookup.status;
    _isLocating = false;
    final selection = lookup.selection;
    if (selection != null) {
      _userLatitude = selection.latitude;
      _userLongitude = selection.longitude;
      _mapLatitude = selection.latitude;
      _mapLongitude = selection.longitude;
      await loadPlaces();
    } else {
      notifyListeners();
    }
    return lookup.status;
  }

  Future<bool> openLocationSettings() =>
      _locationStatus == LocationLookupStatus.serviceDisabled
      ? _geocodingService.openLocationSettings()
      : _geocodingService.openAppSettings();

  void _startLiveUpdates() {
    final repository = _placeRepository;
    if (_cancelLiveUpdates != null || repository is! LivePlaceUpdates) return;
    final live = repository as LivePlaceUpdates;
    try {
      _cancelLiveUpdates = live.subscribeToPlaceChanges(
        onChange: _scheduleLiveRefresh,
        onStatus: (status) {
          _liveUpdatesStatus = status;
          notifyListeners();
        },
      );
    } catch (_) {
      _liveUpdatesStatus = LiveUpdatesStatus.error;
    }
  }

  void _scheduleLiveRefresh() {
    _liveRefreshDebounce?.cancel();
    _liveRefreshDebounce = Timer(
      const Duration(milliseconds: 600),
      refreshFromBackend,
    );
  }

  /// Re-fetches places without clearing the map; keeps the selection.
  Future<void> refreshFromBackend() async {
    try {
      final refreshed = await _placeRepository.getNearbyPlaces(
        _mapLatitude,
        _mapLongitude,
      );
      _places = refreshed;
      if (_searchQuery.trim().isEmpty) _visiblePlaces = refreshed;
      final selectedId = _selectedPlace?.id;
      if (selectedId != null) {
        _selectedPlace = refreshed
            .where((place) => place.id == selectedId)
            .firstOrNull;
      }
      _liveRefreshFailed = false;
      _lastLiveRefresh = DateTime.now();
    } catch (_) {
      _liveRefreshFailed = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _liveRefreshDebounce?.cancel();
    _cancelLiveUpdates?.call();
    super.dispose();
  }

  Future<void> loadPlaces() async {
    _isLoadingPlaces = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _places = await _placeRepository.getNearbyPlaces(
        _mapLatitude,
        _mapLongitude,
      );
      _visiblePlaces = _places;
      _selectedPlace = _places.isNotEmpty ? _places.first : null;
      _liveRefreshFailed = false;
      _startLiveUpdates();
    } catch (_) {
      _errorMessage = "Couldn't load nearby places. Please try again.";
    } finally {
      _isLoadingPlaces = false;
      notifyListeners();
    }
  }

  void selectTravelMode(TravelMode mode) {
    _hasSelectedTravelMode = true;
    _profile = _profile.copyWith(travelMode: mode);
    notifyListeners();
  }

  void toggleNeed(AccessibilityNeed need) {
    final needs = List<AccessibilityNeed>.from(_profile.accessibilityNeeds);
    if (needs.contains(need)) {
      needs.remove(need);
    } else {
      needs.add(need);
    }
    _profile = _profile.copyWith(accessibilityNeeds: needs);
    notifyListeners();
  }

  void completeOnboarding() {
    _profile = _profile.copyWith(onboardingComplete: true);
    notifyListeners();
  }

  void updateDemoProfile({
    TravelMode? travelMode,
    List<AccessibilityNeed>? needs,
  }) {
    _profile = _profile.copyWith(
      travelMode: travelMode,
      accessibilityNeeds: needs,
      onboardingComplete: true,
    );
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _visiblePlaces = _places;
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _visiblePlaces = await _placeRepository.searchPlaces(query);
    _isSearching = false;
    notifyListeners();
  }

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void clearSelectedPlace() {
    _selectedPlace = null;
    notifyListeners();
  }

  void toggleEssentialRequirement(AccessibilityCriterion criterion) {
    if (!_essentialRequirements.add(criterion)) {
      _essentialRequirements.remove(criterion);
    }
    notifyListeners();
  }

  void setVerifiedEssentialsOnly(bool value) {
    _verifiedEssentialsOnly = value;
    notifyListeners();
  }

  List<Place> rankForRequirements(Iterable<Place> places) {
    final ranked = places.where((place) {
      if (!_verifiedEssentialsOnly || _essentialRequirements.isEmpty) {
        return true;
      }
      return _essentialRequirements.every(
        (criterion) =>
            place.accessibilityScore.evidenceFor(criterion) ==
            RequirementEvidence.verified,
      );
    }).toList();
    if (_essentialRequirements.isEmpty) return ranked;
    int rank(Place place) => _essentialRequirements.fold(0, (total, criterion) {
      final score = place.accessibilityScore.categoryScores[criterion];
      return total +
          switch (place.accessibilityScore.evidenceFor(criterion)) {
            RequirementEvidence.verified => (score ?? 0).round(),
            RequirementEvidence.unverified => -100,
            RequirementEvidence.notApplicable => -150,
            RequirementEvidence.unavailable => -200,
          };
    });
    ranked.sort((a, b) => rank(b).compareTo(rank(a)));
    return ranked;
  }

  Future<bool> useCurrentLocation() async =>
      await locateUser() == LocationLookupStatus.found;

  void changeTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  Future<String?> startVoiceSearch() async {
    String? userMessage;
    await _voiceSearchService.startListening(
      onResult: (text) => search(text),
      onDone: notifyListeners,
      onError: (error) {
        userMessage = error;
        notifyListeners();
      },
    );
    notifyListeners();
    return userMessage;
  }

  Future<bool> openDirections(Place place) {
    return _navigationService.openExternalDirections(place);
  }

  Future<void> addReview({
    required Place place,
    required Map<AccessibilityCriterion, AccessibilityRating> ratings,
    required String comment,
  }) async {
    final score = const AccessibilityScoreCalculator().calculate([ratings]);
    final overall = (score.overall ?? 0) / 10;
    final review = PlaceReview(
      id: 'review-${DateTime.now().microsecondsSinceEpoch}',
      placeId: place.id,
      userId: _profile.id,
      userName: _profile.displayName,
      overallRating: overall,
      physicalAccessibilityRating:
          score.categoryScores[AccessibilityCriterion.stepFreeAccess] == null
          ? null
          : score.categoryScores[AccessibilityCriterion.stepFreeAccess]! / 10,
      facilitiesRating:
          score.categoryScores[AccessibilityCriterion.accessibleWashrooms] ==
              null
          ? null
          : score.categoryScores[AccessibilityCriterion.accessibleWashrooms]! /
                10,
      comment: comment,
      createdAt: DateTime.now(),
      reviewerContext: AccessibilityContext(
        travelMode: _profile.travelMode,
        accessibilityNeeds: _profile.accessibilityNeeds,
      ),
      accessibilityRatings: ratings,
    );
    await _placeRepository.addReview(place.id, review);
    await _refreshPlaces(selectPlaceId: place.id);
    _recalculateScores(place.id);
    final contribution = CommunityContribution(
      id: 'contribution-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.review,
      description: 'Reviewed ${place.name}',
      pointsEarned: ContributionType.review.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.review.pointsEarned,
      reviewCount: _profile.reviewCount + 1,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void markReviewHelpful(Place place, PlaceReview review) {
    final updatedReviews = place.reviews
        .map(
          (item) => item.id == review.id
              ? item.copyWith(helpfulVotes: item.helpfulVotes + 1)
              : item,
        )
        .toList();
    _replacePlace(place.copyWith(reviews: updatedReviews));
    final contribution = CommunityContribution(
      id: 'helpful-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.helpfulVote,
      description: 'Marked a review helpful at ${place.name}',
      pointsEarned: ContributionType.helpfulVote.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.helpfulVote.pointsEarned,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void reportReview(Place place, PlaceReview review) {
    final updatedReviews = place.reviews
        .map(
          (item) => item.id == review.id ? item.copyWith(reported: true) : item,
        )
        .toList();
    _replacePlace(place.copyWith(reviews: updatedReviews));
    notifyListeners();
  }

  /// Confirms an accessibility feature at a place and rewards community points.
  void confirmFeature(Place place, AccessibilityFeature feature) {
    final updatedFeatures = place.accessibilityFeatures
        .map(
          (item) => item.id == feature.id
              ? item.copyWith(
                  status: FeatureStatus.available,
                  confirmationCount: item.confirmationCount + 1,
                  lastConfirmed: DateTime.now(),
                )
              : item,
        )
        .toList();
    _replacePlace(place.copyWith(accessibilityFeatures: updatedFeatures));
    final contribution = CommunityContribution(
      id: 'confirm-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.confirmation,
      description: 'Confirmed ${feature.name} at ${place.name}',
      pointsEarned: ContributionType.confirmation.pointsEarned,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.confirmation.pointsEarned,
      accessibilityUpdates: _profile.accessibilityUpdates + 1,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  void _replacePlace(Place updatedPlace) {
    _places = _places
        .map((place) => place.id == updatedPlace.id ? updatedPlace : place)
        .toList();
    _visiblePlaces = _visiblePlaces
        .map((place) => place.id == updatedPlace.id ? updatedPlace : place)
        .toList();
    if (_selectedPlace?.id == updatedPlace.id) {
      _selectedPlace = updatedPlace;
    }
    _placeRepository.updatePlace(updatedPlace);
  }

  Future<void> _refreshPlaces({String? selectPlaceId}) async {
    final refreshed = await _placeRepository.getNearbyPlaces(
      _mapLatitude,
      _mapLongitude,
    );
    _places = refreshed;
    _visiblePlaces = _searchQuery.trim().isEmpty
        ? refreshed
        : await _placeRepository.searchPlaces(_searchQuery);
    if (selectPlaceId != null) {
      _selectedPlace = refreshed.firstWhere(
        (p) => p.id == selectPlaceId,
        orElse: () => refreshed.first,
      );
    }
    notifyListeners();
  }

  /// Recomputes a place's category scores from its actual review data.
  /// Community places grow real scores as the community reviews them.
  void _recalculateScores(String placeId) {
    final index = _places.indexWhere((p) => p.id == placeId);
    if (index == -1) return;
    final place = _places[index];
    if (place.reviews.isEmpty) return;
    double avg(double? Function(PlaceReview) pick) {
      final values = place.reviews.map(pick).whereType<double>().toList();
      if (values.isEmpty) return place.friendlyScore;
      return values.reduce((a, b) => a + b) / values.length;
    }

    final friendly = avg((r) => r.overallRating);
    final updated = place.copyWith(
      friendlyScore: double.parse(friendly.toStringAsFixed(1)),
      wheelchairScore: double.parse(
        avg((r) => r.physicalAccessibilityRating).toStringAsFixed(1),
      ),
      visualAccessibilityScore: double.parse(
        avg((r) => r.physicalAccessibilityRating).toStringAsFixed(1),
      ),
      hearingAccessibilityScore: double.parse(
        avg((r) => r.communicationRating).toStringAsFixed(1),
      ),
      communicationScore: double.parse(
        avg((r) => r.communicationRating).toStringAsFixed(1),
      ),
    );
    _replacePlace(updated);
    notifyListeners();
  }

  /// Records a community report about a place's accessibility information.
  void reportPlaceInfo(Place place, String reason) {
    _reportedPlaceIds.add(place.id);
    _lastReportReasons[place.id] = reason;
    final contribution = CommunityContribution(
      id: 'report-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.accessibilityUpdate,
      description: 'Reported $reason at ${place.name}',
      pointsEarned: 0,
      timestamp: DateTime.now(),
      placeId: place.id,
      placeName: place.name,
    );
    _profile = _profile.copyWith(
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
  }

  /// Whether the current user has reported this place's info.
  bool hasReportedPlace(String placeId) => _reportedPlaceIds.contains(placeId);

  /// The most recent report reason for a place, if any.
  String? reportReasonFor(String placeId) => _lastReportReasons[placeId];

  /// Adds a community-contributed place to the repository, updates the map
  /// state, awards points, and returns the stored place.
  Future<Place> addLocation(Place place) async {
    final stored = await _placeRepository.addPlace(place);
    await _refreshPlaces(selectPlaceId: stored.id);
    final contribution = CommunityContribution(
      id: 'location-${DateTime.now().microsecondsSinceEpoch}',
      type: ContributionType.locationAdd,
      description: 'Added ${stored.name}',
      pointsEarned: ContributionType.locationAdd.pointsEarned,
      timestamp: DateTime.now(),
      placeId: stored.id,
      placeName: stored.name,
    );
    _profile = _profile.copyWith(
      communityPoints:
          _profile.communityPoints + ContributionType.locationAdd.pointsEarned,
      locationCount: _profile.locationCount + 1,
      recentActivity: [contribution, ..._profile.recentActivity],
    );
    notifyListeners();
    return stored;
  }
}
