import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_store/features/order_edit/controllers/order_edit_controller.dart';
import 'package:sixam_mart_store/features/order_edit/widgets/edit_order_item_widget.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class EditOrderScreen extends StatelessWidget {
  final int orderId;
  const EditOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: CustomAppBarWidget(
        titleWidget: GetBuilder<OrderController>(builder: (controller) {
          return Column(children: [
            Text(
              '${'edit_item'.tr} #${orderId.toString()}',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
            if(controller.orderModel != null)
              Text(
                '${'order_is'.tr} ${controller.orderModel!.orderStatus == 'picked_up' ? 'on_the_way'.tr : controller.orderModel!.orderStatus!.tr}',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
              ),
          ]);
        }),
      ),
      body: SafeArea(child: GetBuilder<OrderEditController>(builder: (orderEditController) {
        final items = orderEditController.editOrderItemList ?? [];

        return Column(children: [

          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Center(child: SizedBox(width: 1170, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Text('item_list'.tr, style: robotoBold),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge), color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
                  child: Text(items.length.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeSmall),
                itemBuilder: (context, index) => EditOrderItemWidget(orderDetails: items[index], index: index),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Center(child: InkWell(
                onTap: () => Get.toNamed(RouteHelper.getAddNewItemsRoute()),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('add_more_items'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                  ]),
                ),
              )),

            ]))),
          )),

          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 300]!, blurRadius: 10)],
            ),
            child: Center(child: SizedBox(width: 1170, child: Row(children: [
              Expanded(child: CustomButtonWidget(
                buttonText: 'cancel'.tr,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                textColor: Theme.of(context).textTheme.bodyLarge!.color,
                onPressed: () => Get.back(),
              )),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: CustomButtonWidget(
                buttonText: 'update'.tr,
                isLoading: orderEditController.isOrderEditLoading,
                onPressed: () => orderEditController.updateOrder(orderId),
              )),
            ]))),
          ),
        ]);
      })),
    );
  }
}
