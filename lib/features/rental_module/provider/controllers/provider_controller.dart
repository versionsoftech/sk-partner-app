import 'package:get/get.dart';
import 'package:sixam_mart_store/api/api_client.dart';
import 'package:sixam_mart_store/features/rental_module/provider/domain/models/vehicle_list_model.dart';
import 'package:sixam_mart_store/features/rental_module/provider/domain/services/provider_service_interface.dart';
import 'package:sixam_mart_store/util/app_constants.dart';

class ProviderController extends GetxController implements GetxService {
  final ProviderServiceInterface providerServiceInterface;
  ProviderController({required this.providerServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Vehicles>? _vehicleList;
  List<Vehicles>? get vehicleList => _vehicleList;

  int? _vehiclePageSize;
  int? get vehiclePageSize => _vehiclePageSize;

  List<String> _offsetList = [];

  Future<void> getVehicleList({required String offset, required String search, bool willUpdate = true}) async {
    if (offset == '1') {
      _offsetList = [];
      _vehicleList = null;
      if (willUpdate) {
        update();
      }
    }

    if (_offsetList.contains(offset)) {
      if (_isLoading) {
        _isLoading = false;
        update();
      }
      return;
    }

    _offsetList.add(offset);
    _isLoading = true;
    if (willUpdate) {
      update();
    }

    try {
      final ApiClient apiClient = Get.find<ApiClient>();
      String url = '${AppConstants.taxiVehicleListUri}?offset=$offset&limit=10';
      if (search.isNotEmpty) {
        url += '&search=$search';
      }

      final Response response = await apiClient.getData(url);
      if (response.statusCode == 200 && response.body != null) {
        final VehicleListModel vehicleModel = VehicleListModel.fromJson(response.body);
        if (offset == '1') {
          _vehicleList = [];
        }
        _vehicleList ??= [];
        if (vehicleModel.vehicles != null) {
          _vehicleList!.addAll(vehicleModel.vehicles!);
        }
        _vehiclePageSize = vehicleModel.totalSize;
      }
    } catch (_) {
      if (offset == '1') {
        _vehicleList = [];
      }
    }

    _isLoading = false;
    update();
  }
}
