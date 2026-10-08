import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/skin_tone.dart';

/// Three large, label-free swatches keep the choice comfortable for little
/// fingers while the tooltip/semantics still names each tone for accessibility.
class SkinTonePicker extends StatelessWidget {
  const SkinTonePicker({
    required this.selected,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final SkinTone selected;
  final ValueChanged<SkinTone> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 34 : 40;
    return Semantics(
      label: 'Choose skin tone',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.palette_rounded, size: 20, color: AppColors.lavender),
          const SizedBox(width: 5),
          for (final SkinTone tone in SkinTone.values) ...<Widget>[
            Tooltip(
              message: tone.label,
              child: Semantics(
                button: true,
                selected: tone == selected,
                label: tone.label,
                child: GestureDetector(
                  onTap: () => onChanged(tone),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: size,
                    height: size,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.swatch,
                      border: Border.all(
                        color: tone == selected ? AppColors.white : AppColors.white.withValues(alpha: 0.56),
                        width: tone == selected ? 3.5 : 2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: tone.swatch.withValues(alpha: 0.38),
                          blurRadius: tone == selected ? 9 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: tone == selected
                        ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
