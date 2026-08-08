import 'package:sixam_mart_store/common/models/response_model.dart';

abstract class OrderEditRepositoryInterface {
  Future<ResponseModel> updateOrder(Map<String, dynamic> body);
}
