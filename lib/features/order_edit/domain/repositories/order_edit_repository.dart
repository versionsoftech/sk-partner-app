import 'package:get/get.dart';
import 'package:sixam_mart_store/api/api_client.dart';
import 'package:sixam_mart_store/common/models/response_model.dart';
import 'package:sixam_mart_store/features/order_edit/domain/repositories/order_edit_repository_interface.dart';
import 'package:sixam_mart_store/util/app_constants.dart';

class OrderEditRepository implements OrderEditRepositoryInterface {
  final ApiClient apiClient;
  OrderEditRepository({required this.apiClient});

  @override
  Future<ResponseModel> updateOrder(Map<String, dynamic> body) async {
    ResponseModel responseModel;
    Response response = await apiClient.putData(AppConstants.editOrderUri, body, handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body['message']);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }
}
