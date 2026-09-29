import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/view_state.dart';
import '../../../weather/data/models/place.dart';
import '../../../weather/state/place_controller.dart';

/// App-bar search field providing 400ms debounced place search,
/// active ground location display, and a dropdown overlay of search results.
class PlaceSearchField extends ConsumerStatefulWidget {
  const PlaceSearchField({super.key});

  @override
  ConsumerState<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends ConsumerState<PlaceSearchField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_textController.text.trim().isNotEmpty) {
        _overlayController.show();
      }
    } else {
      _overlayController.hide();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref.read(placeControllerProvider.notifier).onSearchQueryChanged(query);
    if (query.trim().isEmpty) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
    } else if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _onPlaceSelected(Place place) {
    ref.read(placeControllerProvider.notifier).selectPlace(place);
    _textController.clear();
    _focusNode.unfocus();
    _overlayController.hide();
  }

  void _clearSearch() {
    _textController.clear();
    ref.read(placeControllerProvider.notifier).clearSearch();
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeState = ref.watch(placeControllerProvider);
    final selectedPlace = placeState.selectedPlace;
    final isSearching = placeState.searchState.isLoading;

    ref.listen<PlaceState>(placeControllerProvider, (previous, next) {
      if (!_focusNode.hasFocus) return;
      if (next.query.trim().isEmpty && _overlayController.isShowing) {
        _overlayController.hide();
      } else if (next.query.trim().isNotEmpty &&
          !_overlayController.isShowing) {
        _overlayController.show();
      }
    });

    final hintText = selectedPlace != null
        ? '${selectedPlace.name}, ${selectedPlace.country}'
        : 'Search ground or city...';

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => _buildOverlay(context),
        child: TapRegion(
          groupId: 'place_search_field',
          onTapOutside: (_) {
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
              _overlayController.hide();
            }
          },
          child: Semantics(
            label: 'Search cricket ground or city',
            textField: true,
            hint: hintText,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedPlace != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                    fontWeight: selectedPlace != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  prefixIcon: Icon(
                    selectedPlace != null ? Icons.location_on : Icons.search,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: _buildSuffixIcon(isSearching),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isSearching) {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_textController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, size: 16),
        tooltip: 'Clear search',
        onPressed: _clearSearch,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      );
    }

    return null;
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final placeState = ref.watch(placeControllerProvider);
    final searchState = placeState.searchState;

    final targetWidth = _layerLink.leaderSize?.width ?? 280.0;

    return TapRegion(
      groupId: 'place_search_field',
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        child: SizedBox(
          width: targetWidth,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surfaceTint,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: _buildResultsList(context, searchState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    ViewState<List<Place>> searchState,
  ) {
    final theme = Theme.of(context);

    return switch (searchState) {
      ViewLoading() => const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      ViewSuccess(:final data) => ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: data.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = data[index];
          final locationSubtitle = [
            if (place.admin1 != null && place.admin1!.isNotEmpty) place.admin1!,
            place.country,
          ].join(', ');

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              Icons.location_city,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              place.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              locationSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _onPlaceSelected(place),
          );
        },
      ),
      ViewEmpty(:final message) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message ?? 'No matching locations found.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      ViewFailure(:final exception) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exception.messageKey,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    };
  }
}
