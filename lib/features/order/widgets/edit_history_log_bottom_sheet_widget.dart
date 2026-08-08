import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_store/features/order/domain/models/edit_history_log_model.dart';
import 'package:sixam_mart_store/helper/date_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class EditHistoryLogBottomSheetWidget extends StatefulWidget {
  final int orderId;
  const EditHistoryLogBottomSheetWidget({super.key, required this.orderId});

  @override
  State<EditHistoryLogBottomSheetWidget> createState() => _EditHistoryLogBottomSheetWidgetState();
}

class _EditHistoryLogBottomSheetWidgetState extends State<EditHistoryLogBottomSheetWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrderController>().getEditHistoryLog(widget.orderId, 1, reload: true);
    });

    _scrollController.addListener(() {
      final OrderController controller = Get.find<OrderController>();
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && controller.editLogList != null && !controller.editLogPaginating) {
        int pageSize = (controller.editLogTotalSize / 10).ceil();
        if (controller.editLogOffset < pageSize) {
          controller.showEditLogBottomLoader();
          controller.getEditHistoryLog(widget.orderId, controller.editLogOffset + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Container(
              height: 4, width: 40,
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Align(alignment: AlignmentGeometry.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall), 
              child: InkWell(onTap: () => Get.back(),child: Icon(Icons.close, color: Theme.of(context).hintColor))
            ),
          ),
       
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Text('edit_history_log'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text('${'order_id'.tr}: # ${widget.orderId}', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Flexible(child: GetBuilder<OrderController>(builder: (controller) {
          if (controller.editLogList == null) {
            return Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge),
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
            );
          }
          if (controller.editLogList!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge),
              child: Center(child: Text('no_data_found'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor))),
            );
          }
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
            child: Column(children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.editLogList!.length,
                separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeSmall),
                itemBuilder: (context, index) => _logCard(context, controller.editLogList![index], index + 1),
              ),
              if (controller.editLogPaginating) Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
              ),
            ]),
          );
        })),
      ]),
    );
  }

  Widget _logCard(BuildContext context, EditLog log, int number) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text('$number', style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
  const SizedBox(width: Dimensions.paddingSizeDefault),

  Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(log.remark ?? '', style: robotoMedium),
    if ((log.editedByLabel ?? '').isNotEmpty) Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '${'edit_by'.tr} ${log.editedByLabel}',
        style: robotoRegular.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeSmall),
      ),
    ),
  ])),
  const SizedBox(width: Dimensions.paddingSizeSmall),
],)),

        Text(
          log.createdAt != null ? DateConverterHelper.orderEditLogDateTime(log.createdAt!) : '',
          textAlign: TextAlign.right,
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeExtraSmall),
        ),
      ]),
    );
  }
}
