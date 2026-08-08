import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sixam_mart_store/common/models/config_model.dart';
import 'package:sixam_mart_store/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/splash/domain/services/splash_service_interface.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;
  SplashController({required this.splashServiceInterface});

  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  final DateTime _currentTime = DateTime.now();
  DateTime get currentTime => _currentTime;

  bool _firstTimeConnectionCheck = true;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  int? _moduleID;
  int? get moduleID => _moduleID;

  String? _moduleType;
  String? get moduleType => _moduleType;

  Map<String, dynamic>? _data = {};

  Future<bool> getConfigData({bool handleMaintenanceMode = false, bool closeRoute = false}) async {
    Response response = await splashServiceInterface.getConfigData();
    bool isSuccess = false;
    if(response.statusCode == 200) {
      _data = response.body;
      _configModel = ConfigModel.fromJson(response.body);

      splashServiceInterface.handleInitialTopicSubscription();
      if (closeRoute) return true;
      bool isMaintenanceMode = _configModel!.maintenanceMode!;
      String platform = 'vendor_app';
      bool isInMaintenance = isMaintenanceMode && _configModel!.maintenanceModeData!.maintenanceSystemSetup!.contains(platform);

      if(isInMaintenance) {
        Get.offNamed(RouteHelper.getUpdateRoute(false));
      } else if((!isInMaintenance && Get.find<AuthController>().isLoggedIn())){
        Get.offAllNamed(RouteHelper.getInitialRoute());
      } else {
        Get.offAllNamed(RouteHelper.getSignInRoute());
      }

      isSuccess = true;
    }else {
      isSuccess = false;
    }
    update();
    return isSuccess;
  }

  Future<bool> initSharedData() {
    return splashServiceInterface.initSharedData();
  }

  Future<bool> removeSharedData() {
    return splashServiceInterface.removeSharedData();
  }

  bool showIntro() {
    return splashServiceInterface.showIntro();
  }

  void setIntro(bool intro) {
    splashServiceInterface.setIntro(intro);
  }

  bool isRestaurantClosed() {
    DateTime open = DateFormat('hh:mm').parse('');
    DateTime close = DateFormat('hh:mm').parse('');
    DateTime openTime = DateTime(_currentTime.year, _currentTime.month, _currentTime.day, open.hour, open.minute);
    DateTime closeTime = DateTime(_currentTime.year, _currentTime.month, _currentTime.day, close.hour, close.minute);
    if(closeTime.isBefore(openTime)) {
      closeTime = closeTime.add(const Duration(days: 1));
    }
    if(_currentTime.isAfter(openTime) && _currentTime.isBefore(closeTime)) {
      return false;
    }else {
      return true;
    }
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  Future<void> setModule(int? moduleID, String? moduleType) async {
    _moduleID = moduleID;
    _moduleType = moduleType;
    if(moduleType != null) {
      _configModel!.moduleConfig!.module = Module.fromJson(_data!['module_config'][moduleType]);
    }
    update();
  }

  Module getModuleConfig(String? moduleType) {
    Module module = Module.fromJson(_data!['module_config'][moduleType]);
    moduleType == 'food' ? module.newVariation = true : module.newVariation = false;
    return module;
  }

  Module getStoreModuleConfig() {
    Module module = Module.fromJson(_data!['module_config'][Get.find<ProfileController>().profileModel!.stores!.first.module!.moduleType]);
    Get.find<ProfileController>().profileModel!.stores!.first.module!.moduleType == 'food' ? module.newVariation = true : module.newVariation = false;
    return module;
  }

}