import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/geocoding_service.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/accessibility_feature_catalog.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Multi-step community location submission:
/// 1 Choose location - 2 Basic info - 3 Accessibility - 4 Photos - 5 Review.
class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  int _step = 0;
  final _searchController = TextEditingController();

  // Step 1 — location
  GeoSelection? _selection;
  bool _resolving = false;
  String? _searchError;

  // Step 2 — basic info
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  PlaceCategory? _category;
  String? _nameError;
  String? _categoryError;

  // Step 3 — accessibility (tri-state per feature)
  final Map<String, FeatureStatus> _featureStatus = {};
  StaffAssistanceLevel _staffAssistance = StaffAssistanceLevel.notSure;
  final _notesController = TextEditingController();

  // Step 4 — photos (placeholder entries for the MVP; real uploads need a
  // backend — see spec #20/#23)
  final List<_PhotoEntry> _photos = [];
  static const _maxPhotos = 5;

  // Step 5 — submission
  bool _submitting = false;
  String? _submitError;
  Place? _submitted;

  static const _stepLabels = ['Location', 'Details', 'Accessibility', 'Photos', 'Review'];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation with discard-protection (#48)
  // ---------------------------------------------------------------------------

  Future<bool> _confirmDiscard() async {
    final hasProgress = _selection != null ||
        _nameController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _featureStatus.isNotEmpty ||
        _photos.isNotEmpty;
    if (!hasProgress) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard your contribution?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ---------------------------------------------------------------------------
  // Step 1 — choose location (#7, #8, #65, #67)
  // ---------------------------------------------------------------------------

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _resolving = true;
      _searchError = null;
    });
    final result = await context.read<AppState>().geocodingService.searchPlace(query);
    if (!mounted) return;
    setState(() {
      _resolving = false;
      if (result == null) {
        _searchError = 'Could not find that place. Try another search or pick on the map.';
      } else {
        _applySelection(result);
      }
    });
  }

  void _applySelection(GeoSelection selection) {
    _selection = selection;
    if (_addressController.text.isEmpty) {
      _addressController.text = selection.address;
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _resolving = true;
      _searchError = null;
    });
    final result = await context.read<AppState>().geocodingService.currentPosition();
    if (!mounted) return;
    setState(() {
      _resolving = false;
      if (result == null) {
        _searchError = 'Location unavailable. Please check location permission, or pick the place on the map.';
      } else {
        _applySelection(result);
      }
    });
  }

  Future<void> _confirmStep1() async {
    if (_selection == null) return;
    final state = context.read<AppState>();
    // Duplicate detection (#9, #67) — a nearby place already exists.
    final nearby = await state.placeRepository
        .findNearbyPlace(_selection!.latitude, _selection!.longitude);
    if (!mounted) return;
    if (nearby != null) {
      final km = nearby.distanceKmFrom(_selection!.latitude, _selection!.longitude);
      final meters = (km * 1000).round();
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A place already exists nearby'),
          content: Text(
            '$meters m away:\n\n${nearby.name}\n\nIs this the same place?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('update'),
              child: const Text('Yes, Update Existing Place'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('new'),
              child: const Text('No, Add New Location'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      switch (choice) {
        case 'update':
          // Route into the existing place's details where the user can
          // confirm/update accessibility information (#66, #67).
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => PlaceDetailsScreen(placeId: nearby.id),
            ),
          );
          return;
        case 'cancel':
        case null:
          return;
        case 'new':
          break;
      }
    }
    setState(() => _step = 1);
  }

  // ---------------------------------------------------------------------------
  // Step 2 — basic info (#10, #11, #12, #13, #47)
  // ---------------------------------------------------------------------------

  bool _validateStep2() {
    var valid = true;
    if (_nameController.text.trim().isEmpty) {
      _nameError = 'Place name is required.';
      valid = false;
    } else {
      _nameError = null;
    }
    if (_category == null) {
      _categoryError = 'Choose a category.';
      valid = false;
    } else {
      _categoryError = null;
    }
    setState(() {});
    return valid;
  }

  // ---------------------------------------------------------------------------
  // Submit (#26, #27, #28, #68)
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_selection == null || _category == null || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final profile = context.read<AppState>().profile;
      final now = DateTime.now();
      final features = _featureStatus.entries
          .where((entry) => entry.value != FeatureStatus.unknown)
          .map((entry) {
        final option = AccessibilityFeatureCatalog.byId(entry.key)!;
        return AccessibilityFeature(
          id: 'community-${option.id}-${now.millisecondsSinceEpoch}',
          name: option.name,
          icon: option.icon,
          category: option.category,
          status: entry.value,
          confirmationCount: entry.value == FeatureStatus.available ? 1 : 0,
          lastConfirmed: entry.value == FeatureStatus.available ? now : null,
        );
      }).toList();

      final notes = _notesController.text.trim();
      final description = _descriptionController.text.trim();

      final place = Place(
        id: 'community-${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _category!,
        address: _addressController.text.trim().isEmpty
            ? '${_selection!.latitude.toStringAsFixed(4)}, ${_selection!.longitude.toStringAsFixed(4)}'
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        description: description.isEmpty
            ? (notes.isEmpty
                ? 'Community-added place. Accessibility information contributed by the community.'
                : notes)
            : description,
        latitude: _selection!.latitude,
        longitude: _selection!.longitude,
        // New places start unrated (#40, #41) — provisional scores until the
        // community reviews them. Neutral 0 shows as "New" in the UI.
        friendlyScore: 0,
        wheelchairScore: 0,
        visualAccessibilityScore: 0,
        hearingAccessibilityScore: 0,
        communicationScore: 0,
        accessibilityFeatures: features,
        reviews: const [],
        photos: _photos
            .map((p) => PlacePhoto(
                  id: 'photo-${now.millisecondsSinceEpoch}-${p.hashCode}',
                  url: p.url,
                  caption: p.caption,
                  accessibilityCategory: p.accessibilityCategory,
                  uploadedBy: profile.displayName,
                  uploadedAt: now,
                ))
            .toList(),
        source: PlaceSource.community,
        createdBy: profile.id,
        createdAt: now,
        lastCommunityUpdate: now,
      );

      final stored = await context.read<AppState>().addLocation(place);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = stored;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = "Couldn't add this location. Please try again.";
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_submitted != null) return _buildSuccess(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add a New Location')),
        body: Column(
          children: [
            _StepIndicator(step: _step, labels: _stepLabels),
            Expanded(
              child: _submitting
                  ? const Center(child: _SubmittingView())
                  : switch (_step) {
                      0 => _buildChooseLocation(context),
                      1 => _buildBasicInfo(context),
                      2 => _buildAccessibility(context),
                      3 => _buildPhotos(context),
                      4 => _buildReview(context),
                      _ => const SizedBox.shrink(),
                    },
            ),
          ],
        ),
      ),
    );
  }

  // -- Step 1 UI -------------------------------------------------------------

  Widget _buildChooseLocation(BuildContext context) {
    return ListView(
      key: const ValueKey('choose-location-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Where is this place?', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Search for it, drop a pin on the map, or use your current location.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _searchController,
          onSubmitted: (_) => _searchAddress(),
          decoration: InputDecoration(
            hintText: 'Search location...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _resolving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Search',
                    onPressed: _searchAddress,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _resolving ? null : _useCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Use My Current Location'),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchError!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _MapPickerCard(
          initialSelection: _selection,
          onConfirmed: (selection) {
            setState(() => _applySelection(selection));
          },
        ),
        if (_selection != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _LocationConfirmationCard(
            selection: _selection!,
            onChange: () => setState(() {
              _selection = null;
              _searchController.clear();
            }),
            onConfirm: _confirmStep1,
          ),
        ],
      ],
    );
  }

  // -- Step 2 UI -------------------------------------------------------------

  Widget _buildBasicInfo(BuildContext context) {
    return ListView(
      key: const ValueKey('basic-info-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          key: const ValueKey('place-name-field'),
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Place name *',
            errorText: _nameError,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<PlaceCategory>(
          key: const ValueKey('category-dropdown'),
          initialValue: _category,
          decoration: InputDecoration(
            labelText: 'Category *',
            errorText: _categoryError,
          ),
          items: PlaceCategory.values
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(category.displayName),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Address',
            helperText: 'Pre-filled from the map — edit if needed.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          buildCounter: (context,
                  {int? currentLength,
                  int? maxLength,
                  bool? isFocused}) =>
              Text(
                '${currentLength ?? 0} / ${maxLength ?? 500}',
                style: AppTypography.labelSmall,
              ),
          decoration: const InputDecoration(
            labelText: 'Tell the community about this place',
            hintText: 'What is this place? Who is it for?',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Website (optional)',
            prefixIcon: Icon(Icons.language),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _NavButtons(
          onBack: () => _showDiscardOrBack(),
          onNext: () {
            if (_validateStep2()) setState(() => _step = 2);
          },
          nextLabel: 'Next: Accessibility',
        ),
      ],
    );
  }

  Future<void> _showDiscardOrBack() async {
    if (_step == 0) {
      if (await _confirmDiscard() && mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  // -- Step 3 UI (#15–#22) ----------------------------------------------------

  Widget _buildAccessibility(BuildContext context) {
    return ListView(
      key: const ValueKey('accessibility-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'What accessibility features exist here?',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Only mark what you have seen yourself. "Not sure" is always okay — '
          'the community can confirm later.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        _FeatureGroup(
          title: AccessibilityCategory.physical.displayName,
          options: AccessibilityFeatureCatalog.physical,
          statusMap: _featureStatus,
          onChanged: (id, status) => setState(() => _featureStatus[id] = status),
        ),
        _FeatureGroup(
          title: AccessibilityCategory.visual.displayName,
          options: AccessibilityFeatureCatalog.visual,
          statusMap: _featureStatus,
          onChanged: (id, status) => setState(() => _featureStatus[id] = status),
        ),
        _FeatureGroup(
          title: AccessibilityCategory.hearing.displayName,
          options: AccessibilityFeatureCatalog.hearing,
          statusMap: _featureStatus,
          onChanged: (id, status) => setState(() => _featureStatus[id] = status),
        ),
        _FeatureGroup(
          title: AccessibilityCategory.communication.displayName,
          options: AccessibilityFeatureCatalog.communication,
          statusMap: _featureStatus,
          onChanged: (id, status) => setState(() => _featureStatus[id] = status),
        ),
        const SectionHeader('Staff assistance'),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderRadiusMd,
            side: const BorderSide(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: RadioGroup<StaffAssistanceLevel>(
              groupValue: _staffAssistance,
              onChanged: (value) => setState(
                  () => _staffAssistance = value ?? StaffAssistanceLevel.notSure),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: StaffAssistanceLevel.values
                    .map((level) => RadioListTile<StaffAssistanceLevel>(
                          value: level,
                          title: Text(level.label),
                          dense: true,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        const SectionHeader('Anything else the community should know?'),
        TextField(
          key: const ValueKey('accessibility-notes-field'),
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'e.g. Ramp is at the side entrance; restroom door is heavy.',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _NavButtons(
          onBack: () => setState(() => _step = 1),
          onNext: () => setState(() => _step = 3),
          nextLabel: 'Next: Photos',
        ),
      ],
    );
  }

  // -- Step 4 UI (#23–#25) -----------------------------------------------------

  Widget _buildPhotos(BuildContext context) {
    return ListView(
      key: const ValueKey('photos-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Photos', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Show the community what accessibility looks like here — entrances, '
          'ramps, restrooms, parking, signage.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          key: const ValueKey('add-photo-button'),
          onPressed: _photos.length >= _maxPhotos ? null : _addPhoto,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            _photos.length >= _maxPhotos
                ? 'Maximum $_maxPhotos photos'
                : '+ Add Photo',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_photos.length} / $_maxPhotos photos',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        ..._photos.asMap().entries.map((entry) => _PhotoEntryCard(
              entry: entry.value,
              onCaptionChanged: (value) =>
                  setState(() => entry.value.caption = value),
              onRemove: () => setState(() => _photos.remove(entry.value)),
            )),
        const SizedBox(height: AppSpacing.lg),
        _NavButtons(
          onBack: () => setState(() => _step = 2),
          onNext: () => setState(() => _step = 4),
          nextLabel: 'Next: Review',
        ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    // Real camera/gallery capture requires image_picker + permissions; the
    // MVP records the contribution as a placeholder entry (#20, #25).
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose From Gallery'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _photos.add(_PhotoEntry(source: choice));
    });
  }

  // -- Step 5 UI (#26) ----------------------------------------------------------

  Widget _buildReview(BuildContext context) {
    final available = _featureStatus.entries
        .where((e) => e.value == FeatureStatus.available)
        .map((e) => AccessibilityFeatureCatalog.byId(e.key)!.name)
        .toList();
    final unavailable = _featureStatus.entries
        .where((e) => e.value == FeatureStatus.unavailable)
        .map((e) => AccessibilityFeatureCatalog.byId(e.key)!.name)
        .toList();
    final notSure = _featureStatus.entries
        .where((e) => e.value == FeatureStatus.unknown)
        .map((e) => AccessibilityFeatureCatalog.byId(e.key)!.name)
        .toList();

    return ListView(
      key: const ValueKey('review-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Review Your Location', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  title: _nameController.text.trim().isEmpty
                      ? 'Unnamed place'
                      : _nameController.text.trim(),
                  subtitle: _category?.displayName ?? 'No category',
                  onEdit: () => setState(() => _step = 1),
                ),
                const Divider(height: AppSpacing.xl),
                _ReviewRow(
                  title: 'Location',
                  subtitle: _selection == null
                      ? 'Not selected'
                      : _selection!.address,
                  onEdit: () => setState(() => _step = 0),
                ),
                const Divider(height: AppSpacing.xl),
                _ReviewRow(
                  title: 'Accessibility',
                  subtitle: _featureStatus.isEmpty
                      ? 'No features marked'
                      : [
                          ...available.map((f) => '✓ $f'),
                          ...unavailable.map((f) => '✗ $f'),
                          ...notSure.map((f) => '? $f'),
                        ].join('\n'),
                  onEdit: () => setState(() => _step = 2),
                ),
                const Divider(height: AppSpacing.xl),
                _ReviewRow(
                  title: 'Staff assistance',
                  subtitle: _staffAssistance.label,
                  onEdit: () => setState(() => _step = 2),
                ),
                const Divider(height: AppSpacing.xl),
                _ReviewRow(
                  title: 'Photos',
                  subtitle: _photos.isEmpty
                      ? 'No photos added'
                      : '${_photos.length} photo${_photos.length == 1 ? '' : 's'}',
                  onEdit: () => setState(() => _step = 3),
                ),
                if (_notesController.text.trim().isNotEmpty) ...[
                  const Divider(height: AppSpacing.xl),
                  _ReviewRow(
                    title: 'Notes',
                    subtitle: _notesController.text.trim(),
                    onEdit: () => setState(() => _step = 2),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _submitError!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          key: const ValueKey('submit-location-button'),
          label: _submitting ? 'Adding location...' : 'Submit Location',
          icon: Icons.check_circle_outline,
          onPressed: _submitting ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _submitting ? null : () => setState(() => _step = 3),
          child: const Text('Back to Photos'),
        ),
      ],
    );
  }

  // -- Success (#27) ------------------------------------------------------------

  Widget _buildSuccess(BuildContext context) {
    final points = ContributionTypeHelpers.locationAddPoints;
    return Scaffold(
      appBar: AppBar(title: const Text('Location Added!'), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 72, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Location Added!', style: AppTypography.headlineLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Thank you for helping make accessibility\ninformation better for the community.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadii.borderRadiusFull,
                ),
                child: Text(
                  '+$points Community Points',
                  style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                key: const ValueKey('view-location-button'),
                label: 'View Location',
                icon: Icons.place,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaceDetailsScreen(placeId: _submitted!.id),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                key: const ValueKey('back-to-map-button'),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class ContributionTypeHelpers {
  static int get locationAddPoints => 10;
}

// =============================================================================
// Step indicator (#6)
// =============================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Semantics(
        label: 'Step ${step + 1} of ${labels.length}: ${labels[step]}',
        child: Row(
          children: List.generate(labels.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Expanded(
                child: Container(
                  height: 2,
                  color: (index ~/ 2) < step
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              );
            }
            final i = index ~/ 2;
            final done = i < step;
            final current = i == step;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || current
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    border: Border.all(
                      color: current ? AppColors.primaryDark : AppColors.divider,
                      width: current ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
                      : Text(
                          '${i + 1}',
                          style: AppTypography.labelMedium.copyWith(
                            color: current
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[i],
                  style: AppTypography.labelSmall.copyWith(
                    color: current ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// =============================================================================
// Map picker card (#7 Option B, #8)
// =============================================================================

class _MapPickerCard extends StatefulWidget {
  const _MapPickerCard({
    required this.initialSelection,
    required this.onConfirmed,
  });

  final GeoSelection? initialSelection;
  final ValueChanged<GeoSelection> onConfirmed;

  @override
  State<_MapPickerCard> createState() => _MapPickerCardState();
}

class _MapPickerCardState extends State<_MapPickerCard> {
  final MapController _mapController = MapController();
  static const _goa = LatLng(15.4909, 73.8278);
  LatLng? _picked;

  /// Latest camera center, kept up to date via onPositionChanged. Used as a
  /// fallback when the controller camera is not yet linked (e.g. tests).
  LatLng _lastKnownCenter = _goa;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _picked = LatLng(
        widget.initialSelection!.latitude,
        widget.initialSelection!.longitude,
      );
      _lastKnownCenter = _picked!;
    }
  }

  Future<void> _confirm() async {
    LatLng center;
    try {
      center = _mapController.camera.center;
    } catch (_) {
      // Controller not linked yet (widget rendered but camera unavailable) —
      // use the last known position from onPositionChanged instead.
      center = _lastKnownCenter;
    }
    setState(() => _picked = center);
    final address = await context.read<AppState>().geocodingService.reverseGeocode(
          center.latitude,
          center.longitude,
        );
    widget.onConfirmed(GeoSelection(
      latitude: center.latitude,
      longitude: center.longitude,
      address: address,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _picked ?? _goa,
                    initialZoom: _picked != null ? 16 : 12,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
                    onMapEvent: (event) {
                      if (event.camera.center != _lastKnownCenter) {
                        setState(() => _lastKnownCenter = event.camera.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.access_map',
                    ),
                  ],
                ),
                const Center(
                  child: Icon(Icons.location_on, size: 44, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move the map so the pin sits on the place.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const ValueKey('confirm-map-location-button'),
                  onPressed: _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Location confirmation (#8)
// =============================================================================

class _LocationConfirmationCard extends StatelessWidget {
  const _LocationConfirmationCard({
    required this.selection,
    required this.onChange,
    required this.onConfirm,
  });

  final GeoSelection selection;
  final VoidCallback onChange;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  selection.address,
                  style: AppTypography.bodyMedium,
                ),
              ),
              TextButton(onPressed: onChange, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.borderRadiusMd,
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: _StaticPreviewMap(selection: selection),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: const ValueKey('confirm-chosen-location-button'),
            label: 'Confirm This Location',
            icon: Icons.check,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _StaticPreviewMap extends StatelessWidget {
  const _StaticPreviewMap({required this.selection});

  final GeoSelection selection;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(selection.latitude, selection.longitude),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.access_map',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(selection.latitude, selection.longitude),
              width: 36,
              height: 36,
              child: const Icon(Icons.location_on, size: 36, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Feature tri-state group (#15–#18, #21, #22, #50)
// =============================================================================

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({
    required this.title,
    required this.options,
    required this.statusMap,
    required this.onChanged,
  });

  final String title;
  final List<FeatureOption> options;
  final Map<String, FeatureStatus> statusMap;
  final void Function(String id, FeatureStatus status) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        ...options.map((option) {
          final status = statusMap[option.id] ?? FeatureStatus.unknown;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: status == FeatureStatus.unknown
                  ? AppColors.surface
                  : AppColors.primarySurface.withValues(alpha: 0.5),
              borderRadius: AppRadii.borderRadiusMd,
              border: Border.all(
                color: status == FeatureStatus.unknown
                    ? AppColors.divider
                    : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(option.icon, size: 22, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(option.name, style: AppTypography.bodyMedium),
                ),
                _TriStateToggle(
                  optionId: option.id,
                  value: status,
                  onChanged: (value) => onChanged(option.id, value),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Yes / No / Not sure — never force a false binary (#21, #22, #50).
class _TriStateToggle extends StatelessWidget {
  const _TriStateToggle({
    required this.optionId,
    required this.value,
    required this.onChanged,
  });

  final String optionId;
  final FeatureStatus value;
  final ValueChanged<FeatureStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(FeatureStatus status, String symbol, String label) {
      final selected = value == status;
      final color = switch (status) {
        FeatureStatus.available => AppColors.success,
        FeatureStatus.unavailable => AppColors.error,
        FeatureStatus.unknown => AppColors.textSecondary,
      };
      return Semantics(
        label: '$optionId: $label',
        button: true,
        child: InkWell(
          key: ValueKey('feature-$optionId-${status.name}'),
          borderRadius: AppRadii.borderRadiusFull,
          onTap: () => onChanged(status),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(
                color: selected ? color : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              symbol,
              style: AppTypography.titleMedium.copyWith(
                color: selected ? color : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(FeatureStatus.available, '✓', 'Available'),
        option(FeatureStatus.unavailable, '✗', 'Not available'),
        option(FeatureStatus.unknown, '?', 'Not sure'),
      ],
    );
  }
}

// =============================================================================
// Photo entries (#23, #24)
// =============================================================================

class _PhotoEntry {
  _PhotoEntry({required this.source});

  /// 'camera' or 'gallery' — recorded until a backend stores real uploads.
  final String source;
  String caption = '';
  String? accessibilityCategory;

  String get url => source == 'camera'
      ? 'placeholder://camera'
      : 'placeholder://gallery';
}

class _PhotoEntryCard extends StatelessWidget {
  const _PhotoEntryCard({
    required this.entry,
    required this.onCaptionChanged,
    required this.onRemove,
  });

  final _PhotoEntry entry;
  final ValueChanged<String> onCaptionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: AppRadii.borderRadiusSm,
                  ),
                  child: Icon(
                    entry.source == 'camera'
                        ? Icons.photo_camera
                        : Icons.photo,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    entry.source == 'camera' ? 'Camera photo' : 'Gallery photo',
                    style: AppTypography.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ),
            TextField(
              onChanged: onCaptionChanged,
              decoration: const InputDecoration(
                hintText: 'Caption (e.g. "Ramp at the main entrance")',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Review section + nav helpers (#26)
// =============================================================================

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
      ],
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          label: nextLabel,
          icon: Icons.arrow_forward,
          onPressed: onNext,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    );
  }
}

class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: AppSpacing.lg),
        Text('Adding location...'),
      ],
    );
  }
}
