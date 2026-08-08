import 'package:sixam_mart_store/common/models/response_model.dart';
import 'package:sixam_mart_store/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/models/edit_order_body_model.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';

abstract class OrderEditServiceInterface {
  List<OrderDetailsModel> prepareEditList(List<OrderDetailsModel>? source);
  OrderDetailsModel buildDirectItem(Item item);
  EditOrderBodyModel buildEditBody(int orderId, List<OrderDetailsModel> items);
  Future<ResponseModel> updateOrder(Map<String, dynamic> body);
}
