import 'package:flutter/material.dart';

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
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2B2B2B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
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
                child: _SegmentHighlight(width: width),
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
                                    ? Colors.black
                                    : Colors.white70,
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
                color: isSelected
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.28),
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
                      color: isSelected ? Colors.black : Colors.white70,
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
                    color: isSelected ? Colors.black : Colors.white70,
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

  const _SegmentHighlight({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}
