import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/controllers/order_edit_controller.dart';
import 'package:sixam_mart_store/features/order_edit/widgets/item_details_bottom_sheet_widget.dart';
import 'package:sixam_mart_store/features/order_edit/widgets/quantity_button_widget.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';

class EditOrderItemWidget extends StatelessWidget {
  final OrderDetailsModel orderDetails;
  final int index;
  const EditOrderItemWidget({super.key, required this.orderDetails, required this.index});

  @override
  Widget build(BuildContext context) {
    print("---------> ${orderDetails.variation}");
    final OrderEditController orderEditController = Get.find<OrderEditController>();
    final bool isEditable = orderDetails.isEditable ?? false;
    final String addOnText = _buildAddOnText();
    final String variationText = _buildVariationText();

    return InkWell(
      /// tap the card to view / edit this item's details
      onTap: () => _openDetails(),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [BoxShadow(offset: const Offset(0, 3), color: Colors.grey[Get.isDarkMode ? 700 : 200]!, blurRadius: 8)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImageWidget(
            height: 60, width: 60, fit: BoxFit.cover,
            image: orderDetails.itemDetails?.imageFullUrl ?? '',
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text(orderDetails.itemDetails?.name ?? '', style: robotoMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          /// price + quantity controls aligned in one row
          Row(children: [
            Expanded(child: Text(
              PriceConverterHelper.convertPrice((orderDetails.price ?? 0) * (orderDetails.quantity ?? 1)),
              style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
            )),

            isEditable ? Row(mainAxisSize: MainAxisSize.min, children: [

              /// minus button — turns into a delete button when quantity is 1
              QuantityButton(
                isIncrement: false, size: 22,
                showRemoveIcon: (orderDetails.quantity ?? 1) == 1,
                onTap: () {
                  if((orderDetails.quantity ?? 1) > 1) {
                    orderEditController.decreaseEditItemQuantity(index);
                  } else if((orderEditController.editOrderItemList?.length ?? 0) <= 1) {
                    /// an order must always contain at least one item
                    showCustomSnackBar('order_must_contain_at_least_one_item'.tr);
                  } else {
                    _showDeleteDialog(orderEditController);
                  }
                },
              ),

              /// quantity count in a bordered box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                ),
                child: Text(orderDetails.quantity.toString(), style: robotoMedium),
              ),

              QuantityButton(
                isIncrement: true, size: 22,
                onTap: () => orderEditController.increaseEditItemQuantity(index),
              ),
            ]) : Text('${'quantity'.tr}: ${orderDetails.quantity}', style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
          ]),

          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          if(variationText.isNotEmpty) Text(
            '${'variations'.tr}: $variationText',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          if(addOnText.isNotEmpty) Text(
            '${'addons'.tr}: $addOnText',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),

        ])),
      ]),
      ),
    );
  }

  /// Opens the item details sheet to edit this item's variations / add-ons / quantity.
  void _openDetails() {
    if(orderDetails.itemDetails == null) return;
    Get.bottomSheet(
      ItemDetailsBottomSheetWidget(item: orderDetails.itemDetails!, orderDetails: orderDetails, editIndex: index),
      isScrollControlled: true, backgroundColor: Colors.transparent,
    );
  }

  void _showDeleteDialog(OrderEditController orderEditController) {
    final module = Get.find<ProfileController>().profileModel?.stores?.first.module?.moduleType;
    final String titleKey = module  == 'food' ? 'are_you_sure_to_delete_this_food' : 'are_you_sure_to_delete_this_item';

    Get.dialog(ConfirmationDialogWidget(
      icon: Images.deleteDialogIcon,
      title: titleKey.tr,
      description: 'if_once_you_delete_this_item_this_will_remove_from_item_list'.tr,
      onYesPressed: () {
        Get.back();
        orderEditController.removeEditOrderItem(index);
      },
    ));
  }

  String _buildAddOnText() {
    String text = '';
    if(orderDetails.addOns != null) {
      for (final addOn in orderDetails.addOns!) {
        text = '$text${text.isEmpty ? '' : ',  '}${addOn.name} (${addOn.quantity})';
      }
    }
    return text;
  }

  String _buildVariationText() {
    String text = '';
    if(orderDetails.variation != null && orderDetails.variation!.isNotEmpty) {
      final List<String> variationTypes = (orderDetails.variation![0].type ?? '').split('-');
      final choiceOptions = orderDetails.itemDetails?.choiceOptions;
      if(choiceOptions != null && variationTypes.length == choiceOptions.length) {
        for(int index = 0; index < choiceOptions.length; index++) {
          text = '$text${index == 0 ? '' : ',  '}${choiceOptions[index].title} - ${variationTypes[index]}';
        }
      } else {
        for(final variation in orderDetails.variation!) {
          text += '${text.isEmpty ? '' : ', '}${variation.type}';
        }
      }
    } else if(orderDetails.foodVariation != null && orderDetails.foodVariation!.isNotEmpty) {
      for(final foodVariation in orderDetails.foodVariation!) {
        text += '${text.isNotEmpty ? ', ' : ''}${foodVariation.name} (';
        bool first = true;
        for(final value in foodVariation.variationValues ?? []) {
          text += '${first ? '' : ', '}${value.level}';
          first = false;
        }
        text += ')';
      }
    }
    return text;
  }
}
