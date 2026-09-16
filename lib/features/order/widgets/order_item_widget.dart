import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderItemWidget extends StatelessWidget {
  final OrderModel? order;
  final OrderDetailsModel orderDetails;
  const OrderItemWidget({super.key, required this.order, required this.orderDetails});

  String? _offerSizeSuffix(OrderDetailsModel od) {
    final dealSizes = od.restaurantDeal?.offerLabel;
    final fromDealLabel = RegExp(
      r'(small|medium|large|regular|family)(?:\s*/\s*(small|medium|large|regular|family))*',
      caseSensitive: false,
    ).firstMatch(od.offerLabel ?? dealSizes ?? '');
    if (fromDealLabel != null) {
      return fromDealLabel.group(0)!.replaceAll(RegExp(r'\s*/\s*'), '/');
    }

    final sizes = <String>{};
    void addSize(String? value) {
      if (value == null) return;
      final m = RegExp(r'\b(small|medium|large|regular|family)\b', caseSensitive: false).firstMatch(value);
      if (m != null) {
        final s = m.group(1)!;
        sizes.add(s[0].toUpperCase() + s.substring(1).toLowerCase());
      }
    }

    if (od.foodVariation != null) {
      for (final fv in od.foodVariation!) {
        addSize(fv.name);
        fv.variationValues?.forEach((v) => addSize(v.level));
      }
    }
    if (od.variation != null && od.variation!.isNotEmpty) {
      addSize(od.variation!.first.type);
    }
    if (od.variant != null) addSize(od.variant);
    if (sizes.isEmpty) return null;
    return sizes.join('/');
  }
  
  @override
  Widget build(BuildContext context) {
    String addOnText = '';
    for (var addOn in orderDetails.addOns!) {
      addOnText = '$addOnText${(addOnText.isEmpty) ? '' : ',  '}${addOn.name} (${addOn.quantity})';
    }

    String variationText = '';
    if(orderDetails.variation!.isNotEmpty) {
      if(orderDetails.variation!.isNotEmpty) {
        List<String> variationTypes = orderDetails.variation![0].type!.split('-');
        if(variationTypes.length == orderDetails.itemDetails!.choiceOptions!.length) {
          int index = 0;
          for (var choice in orderDetails.itemDetails!.choiceOptions!) {
            variationText = '$variationText${(index == 0) ? '' : ',  '}${choice.title} - ${variationTypes[index]}';
            index = index + 1;
          }
        }else {
          variationText = orderDetails.itemDetails!.variations![0].type!;
        }
      }
    }else if(orderDetails.foodVariation!.isNotEmpty) {
      for(FoodVariation variation in orderDetails.foodVariation!) {
        variationText += '${variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
        for(VariationValue value in variation.variationValues!) {
          variationText += '${variationText.endsWith('(') ? '' : ', '}${value.level}';
        }
        variationText += ')';
      }
    }
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
      Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
        orderDetails.itemDetails!.imageFullUrl != null ? ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImageWidget(
            height: 50, width: 50, fit: BoxFit.cover,
            image: '${orderDetails.itemDetails!.imageFullUrl}',
          ),
        ) : ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImageWidget(
            height: 50, width: 50, fit: BoxFit.cover,
            image: Images.image,
          ),
        ),
        SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(
                orderDetails.itemDetails!.name!,
                style: robotoBold.copyWith(color: Theme.of(context).hintColor),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              )),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text('${'quantity'.tr}: ', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
              Text(orderDetails.quantity.toString(), style: robotoMedium),
            ]),
            if (orderDetails.isOfferItem == true || (orderDetails.discountOnItem ?? 0) > 0 || orderDetails.restaurantDeal != null)
              Builder(builder: (context) {
                final unitPrice = orderDetails.price ?? 0;
                final discountOnItem = orderDetails.discountOnItem ?? 0;
                final qty = orderDetails.quantity ?? 1;
                final lineDiscount = discountOnItem * qty;
                final label = (orderDetails.offerLabel ?? '').toLowerCase();
                final dealType = (orderDetails.restaurantDeal?.dealType ?? '').toLowerCase();
                final dealPct = orderDetails.restaurantDeal?.discountPercent ?? 0;
                final isBogo = dealType != 'percent_off'
                    && dealPct <= 0
                    && !label.contains('%')
                    && (orderDetails.restaurantDeal?.isBogo == true
                        || dealType == 'bogo'
                        || label.contains('free')
                        || label.contains('bogo')
                        || (label.contains('buy') && label.contains('get')));
                String badge;
                if (isBogo) {
                  badge = 'Buy 1 Get 1 Free';
                } else {
                  double? pct = orderDetails.restaurantDeal?.discountPercent;
                  if ((pct == null || pct <= 0)) {
                    final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(orderDetails.offerLabel ?? '');
                    if (m != null) pct = double.tryParse(m.group(1)!);
                  }
                  if ((pct == null || pct <= 0) && unitPrice > 0 && discountOnItem > 0) {
                    pct = (discountOnItem / unitPrice) * 100;
                  }
                  if (pct != null && pct > 0) {
                    final shown = pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
                    badge = '$shown% OFF';
                  } else {
                    badge = (orderDetails.offerLabel ?? 'offer'.tr)
                        .replaceAll(RegExp(r'\s*[·•|\-]\s*(small|medium|large|regular|family)(/[a-z]+)*.*$', caseSensitive: false), '')
                        .replaceAll(RegExp(r'^\+\s*'), '')
                        .trim();
                  }
                }
                final size = _offerSizeSuffix(orderDetails);
                if (size != null) badge = '$badge · $size';
                if (badge.isEmpty) return const SizedBox.shrink();
                final primary = Theme.of(context).primaryColor;
                return Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primary.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      badge,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary),
                    ),
                  ),
                );
              }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Builder(builder: (context) {
              final unitPrice = orderDetails.price ?? 0;
              final discountOnItem = orderDetails.discountOnItem ?? 0;
              final qty = orderDetails.quantity ?? 1;
              final lineDiscount = discountOnItem * qty;
              final label = (orderDetails.offerLabel ?? '').toLowerCase();
              final dealType = (orderDetails.restaurantDeal?.dealType ?? '').toLowerCase();
              final dealPct = orderDetails.restaurantDeal?.discountPercent ?? 0;
              final isBogo = dealType != 'percent_off'
                  && dealPct <= 0
                  && !label.contains('%')
                  && (orderDetails.restaurantDeal?.isBogo == true
                      || dealType == 'bogo'
                      || label.contains('free')
                      || label.contains('bogo')
                      || (label.contains('buy') && label.contains('get')));
              final displayUnit = (!isBogo && discountOnItem > 0)
                  ? (unitPrice - discountOnItem).clamp(0, double.infinity).toDouble()
                  : unitPrice;
              final showUnitStrike = !isBogo && discountOnItem > 0;
              final paidLine = (unitPrice * qty - lineDiscount).clamp(0, double.infinity).toDouble();

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(
                    PriceConverterHelper.convertPrice(displayUnit),
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(width: 5),
                  showUnitStrike
                      ? Expanded(child: Text(
                          PriceConverterHelper.convertPrice(unitPrice),
                          style: robotoMedium.copyWith(
                            decoration: TextDecoration.lineThrough,
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ))
                      : const Expanded(child: SizedBox()),
                  ((Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && orderDetails.itemDetails!.unitType != null)
                  || (Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!)) ? Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
                child: Text(
                  Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! ? orderDetails.itemDetails!.unitType ?? ''
                      : orderDetails.itemDetails!.veg == 0 ? 'non_veg'.tr : 'veg'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                ),
              ) : const SizedBox(),
                ]),
                if (isBogo && lineDiscount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${PriceConverterHelper.convertPrice(paidLine)}  (${PriceConverterHelper.convertPrice(unitPrice * qty)} · 1 free)',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                    ),
                  ),
              ]);
            }),

          ]),
        ),
      ]),

      variationText.isNotEmpty ? Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          Expanded( flex: 1, child: Text('${'variations'.tr} ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor))),
          Text(': '),
          Expanded( flex: 4, child: Text(
              " $variationText",
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
          ))),
        ]),
      ) : const SizedBox(),

      addOnText.isNotEmpty ? Row(children: [
        Expanded( flex: 1,child: Text('${'addons'.tr} ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall,  color: Theme.of(context).hintColor))),
        Text(': '),
        Expanded( flex: 4,child: Text(
            " $addOnText",
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
            ))),
      ]) : const SizedBox(),
    ]);
  }
}
