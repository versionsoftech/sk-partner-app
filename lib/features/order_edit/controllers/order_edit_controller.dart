import 'package:get/get.dart';
import 'package:sixam_mart_store/common/models/response_model.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/models/edit_order_body_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/services/order_edit_service_interface.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';

/// Manages the working copy of an order while it is being edited
/// (add / remove / change quantity of items).
class OrderEditController extends GetxController implements GetxService {
  final OrderEditServiceInterface orderEditServiceInterface;
  OrderEditController({required this.orderEditServiceInterface});

  /// Working copy of the order items. Discarded if the user cancels without saving.
  List<OrderDetailsModel>? _editOrderItemList;
  List<OrderDetailsModel>? get editOrderItemList => _editOrderItemList;

  bool _isOrderEditLoading = false;
  bool get isOrderEditLoading => _isOrderEditLoading;

  /// Builds the working copy from the loaded order items (deep copied).
  void initializeEditOrder(List<OrderDetailsModel>? source) {
    _editOrderItemList = orderEditServiceInterface.prepareEditList(source);
    update();
  }

  void addItemToEditOrder(OrderDetailsModel item) {
    _editOrderItemList ??= [];
    _editOrderItemList!.add(item);
    update();
  }

  /// Adds an item that has no variation directly to the order.
  void addItemDirectly(Item item) {
    addItemToEditOrder(orderEditServiceInterface.buildDirectItem(item));
  }

  /// Replaces an existing item (variation / add-ons / quantity edited).
  void updateEditItem(int index, OrderDetailsModel item) {
    if (_editOrderItemList != null && index >= 0 && index < _editOrderItemList!.length) {
      _editOrderItemList![index] = item;
      update();
    }
  }

  void increaseEditItemQuantity(int index) {
    if (_editOrderItemList != null && index < _editOrderItemList!.length) {
      _editOrderItemList![index].quantity = (_editOrderItemList![index].quantity ?? 1) + 1;
      update();
    }
  }

  void decreaseEditItemQuantity(int index) {
    if (_editOrderItemList != null && index < _editOrderItemList!.length && (_editOrderItemList![index].quantity ?? 1) > 1) {
      _editOrderItemList![index].quantity = _editOrderItemList![index].quantity! - 1;
      update();
    }
  }

  void removeEditOrderItem(int index) {
    if (_editOrderItemList != null && index < _editOrderItemList!.length) {
      _editOrderItemList!.removeAt(index);
      update();
    }
  }

  Future<bool> updateOrder(int orderId) async {
    if (_editOrderItemList == null || _editOrderItemList!.isEmpty) {
      return false;
    }
    _isOrderEditLoading = true;
    update();

    EditOrderBodyModel body = orderEditServiceInterface.buildEditBody(orderId, _editOrderItemList!);
    ResponseModel responseModel = await orderEditServiceInterface.updateOrder(body.toJson());

    if (responseModel.isSuccess) {
      OrderController orderController = Get.find<OrderController>();
      await orderController.getOrderDetails(orderId);
      await orderController.getOrderItemsDetails(orderId);
      await orderController.getCurrentOrders();
      Get.back();
      showCustomSnackBar(responseModel.message, isError: false);
    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    _isOrderEditLoading = false;
    update();
    return responseModel.isSuccess;
  }
}
