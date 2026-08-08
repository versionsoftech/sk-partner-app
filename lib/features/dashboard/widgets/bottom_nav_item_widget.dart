import 'package:flutter/material.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class BottomNavItemWidget extends StatelessWidget {
  final String selectedIcon;
  final String unSelectedIcon;
  final String title;
  final Function? onTap;
  final bool isSelected;
  const BottomNavItemWidget({super.key, this.onTap, this.isSelected = false, required this.title, required this.selectedIcon, required this.unSelectedIcon});

  @override
  Widget build(BuildContext context) {
    bool isDisabled = onTap == null;

    return Expanded(
      child: InkWell(
        onTap: onTap as void Function()?,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            Image.asset(
              isSelected ? selectedIcon : unSelectedIcon, height: 25, width: 25,
              color: isDisabled
                  ? Theme.of(context).disabledColor
                  : (isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium!.color!),
            ),

            SizedBox(height: isSelected ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),

            Text(
              title,
              style: robotoRegular.copyWith(
                color: isDisabled
                    ? Theme.of(context).disabledColor
                    : (isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium!.color!),
                fontSize: 12
              ),
            ),

          ]),
        ),
      ),
    );
  }
}
