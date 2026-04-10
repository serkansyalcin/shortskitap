import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SegmentedItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentedItem({required this.value, required this.label, this.icon});
}

class AnimatedSegmentedControl<T> extends StatelessWidget {
  final T selected;
  final List<SegmentedItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool isScrollable;
  final EdgeInsetsGeometry padding;

  const AnimatedSegmentedControl({
    super.key,
    required this.selected,
    required this.items,
    required this.onChanged,
    this.isScrollable = false,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = _SegmentPalette.resolve(theme);
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.containerBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.13 : 0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: isScrollable
          ? _ScrollableSegments<T>(
              selected: selected,
              items: items,
              onChanged: onChanged,
            )
          : _FixedSegments<T>(
              selected: selected,
              items: items,
              onChanged: onChanged,
            ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: container,
    );
  }
}

class _FixedSegments<T> extends StatelessWidget {
  final T selected;
  final List<SegmentedItem<T>> items;
  final ValueChanged<T> onChanged;

  const _FixedSegments({
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SegmentPalette.resolve(theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / items.length;
        final selectedIndex = items.indexWhere(
          (item) => item.value == selected,
        );
        final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;

        return SizedBox(
          height: 48,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: safeIndex * width,
                top: 0,
                bottom: 0,
                child: _SegmentHighlight(width: width, palette: palette),
              ),
              Row(
                children: items.map((item) {
                  final isSelected = item.value == selected;
                  return Expanded(
                    child: _SegmentButton(
                      item: item,
                      isSelected: isSelected,
                      textStyle:
                          (theme.textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(
                                color: isSelected
                                    ? palette.selectedForeground
                                    : palette.unselectedForeground,
                                fontWeight: FontWeight.w800,
                              ),
                      onTap: () => onChanged(item.value),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrollableSegments<T> extends StatelessWidget {
  final T selected;
  final List<SegmentedItem<T>> items;
  final ValueChanged<T> onChanged;

  const _ScrollableSegments({
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SegmentPalette.resolve(theme);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isSelected ? palette.selectedBackground : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.selectedGlow,
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: _SegmentButton(
                item: item,
                isSelected: isSelected,
                textStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      color: isSelected
                          ? palette.selectedForeground
                          : palette.unselectedForeground,
                      fontWeight: FontWeight.w800,
                    ),
                onTap: () => onChanged(item.value),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  final SegmentedItem<T> item;
  final bool isSelected;
  final TextStyle textStyle;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.item,
    required this.isSelected,
    required this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SegmentPalette.resolve(Theme.of(context));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: textStyle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 16,
                    color: isSelected
                        ? palette.selectedForeground
                        : palette.unselectedForeground,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentHighlight extends StatelessWidget {
  final double width;
  final _SegmentPalette palette;

  const _SegmentHighlight({required this.width, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: palette.selectedBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: palette.selectedGlow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _SegmentPalette {
  final Color containerBorder;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color unselectedForeground;
  final Color selectedGlow;

  const _SegmentPalette({
    required this.containerBorder,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.selectedGlow,
  });

  factory _SegmentPalette.resolve(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return _SegmentPalette(
      containerBorder: isDark
          ? AppColors.outline.withValues(alpha: 0.95)
          : theme.colorScheme.outline.withValues(alpha: 0.72),
      selectedBackground: isDark
          ? AppColors.accent.withValues(alpha: 0.38)
          : AppColors.accentSoft,
      selectedForeground: isDark ? AppColors.primaryLight : AppColors.accent,
      unselectedForeground:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      selectedGlow: isDark
          ? AppColors.primary.withValues(alpha: 0.16)
          : AppColors.primary.withValues(alpha: 0.18),
    );
  }
}
