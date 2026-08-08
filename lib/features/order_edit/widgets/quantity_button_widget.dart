import 'package:flutter/material.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';

/// Increment / decrement button used in the order-edit screens. When
/// [showRemoveIcon] is true the decrement button turns into a delete (trash) icon.
class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final VoidCallback? onTap;
  final bool showRemoveIcon;
  final Color? color;
  final double size;
  const QuantityButton({super.key, required this.isIncrement, required this.onTap, this.showRemoveIcon = false, this.color, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: size, width: size,
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 1, color: showRemoveIcon ? Colors.transparent : isIncrement ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
          color: showRemoveIcon ? Colors.transparent : isIncrement ? color ?? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.2),
        ),
        alignment: Alignment.center,
        child: showRemoveIcon ? Image.asset(Images.deleteIcon, height: size * 0.7, width: size * 0.7): Icon(
          isIncrement ? Icons.add : Icons.remove,
          size: size * 0.7,
          color: isIncrement ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
