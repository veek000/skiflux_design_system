import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../tokens/colors.dart';
import '../tokens/icons.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component: **Search Container** (`190:6876`, Search Flow section
/// `294:6905`)
///
/// Pill search input with two visual states driven by content:
/// - Idle (empty): `Background/Hover` fill, `Content/Disabled` icon and
///   placeholder ("Search").
/// - Active (has text): `Background/Selected` fill, `Content/Brand` icon and
///   text, trailing clear button (`close-circle-fill`).
///
/// Label style is `UI Style/Input Label` (Creato Display Bold 16).
class SkifluxSearchField extends StatefulWidget {
  const SkifluxSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after the trailing clear button empties the field.
  final VoidCallback? onCleared;

  @override
  State<SkifluxSearchField> createState() => _SkifluxSearchFieldState();
}

class _SkifluxSearchFieldState extends State<SkifluxSearchField> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  bool get _hasText => _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SkifluxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = _hasText;

    return Container(
      // Figma: Search Container is exactly 48px tall — the same as the
      // 48px circular back button it sits beside. A fixed height (rather
      // than vertical padding) stops the TextField's intrinsic height from
      // inflating the pill.
      height: SkifluxUnit.u48,
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceL,
      ),
      decoration: BoxDecoration(
        color: active
            ? SkifluxColors.backgroundSelected
            : SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        children: [
          Icon(
            RemixIcons.search_fill,
            size: SkifluxIcons.sizeM,
            color: active
                ? SkifluxColors.contentBrand
                : SkifluxColors.contentDisabled,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              style: SkifluxTypography.uiInputLabel.copyWith(
                color: SkifluxColors.contentBrand,
              ),
              cursorColor: SkifluxColors.contentBrand,
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                // Same reasoning as ComposeBar: the theme styles standalone
                // inputs as white filled pills with per-state outline
                // borders; here the field sits directly on the pill.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: SkifluxTypography.uiInputLabel.copyWith(
                  color: SkifluxColors.contentDisabled,
                ),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          if (active) ...[
            const SizedBox(width: SkifluxSpacing.spaceS),
            GestureDetector(
              onTap: _clear,
              child: const Icon(
                RemixIcons.close_circle_fill,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
