import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_store/common/models/config_model.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_text_field_widget.dart';
import 'package:sixam_mart_store/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_store/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart_store/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart_store/features/reels/widgets/reel_item_selector_widget.dart';
import 'package:sixam_mart_store/features/reels/widgets/reel_preview_dialog_widget.dart';
import 'package:sixam_mart_store/features/rental_module/provider/domain/models/vehicle_list_model.dart' as vehicle_model;
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/date_converter_helper.dart';
import 'package:sixam_mart_store/helper/image_size_checker.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';

class AddReelScreen extends StatefulWidget {
  final Reel? reel;
  const AddReelScreen({super.key, this.reel});

  @override
  State<AddReelScreen> createState() => _AddReelScreenState();
}

class _AddReelScreenState extends State<AddReelScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _descriptionController = [];
  final List<FocusNode> _descriptionFocusNode = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<Language>? _languageList = Get.find<SplashController>().configModel!.language;
  TabController? _tabController;
  final List<Tab> _tabs = [];

  int _scheduleType = 0; // 0 = All Time, 1 = Custom Schedule
  final TextEditingController _dateRangeController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  XFile? _thumbnailImage;
  XFile? _mediaFile;
  bool _isVideoFile = false;
  
  bool _orderNowButton = false;
  int? _selectedProductId;

  String? _networkThumbnailUrl;
  String? _networkVideoUrl;

  late bool _isUpdate;

  String get _maxFileSizeText {
    final double maxFileSize = Get.find<SplashController>().configModel!.validationConfig!.maxFileSize;
    if(maxFileSize % 1 == 0) {
      return maxFileSize.toInt().toString();
    }
    return maxFileSize.toString();
  }

  String get _imageSizeErrorText => 'image_size_exceeds'.trParams({'size' : _maxFileSizeText});

  @override
  void initState() {
    super.initState();

    _isUpdate = widget.reel != null;

    _tabController = TabController(length: _languageList!.length, vsync: this);
    for (var language in _languageList) {
      _tabs.add(Tab(text: language.value));
      _descriptionController.add(TextEditingController());
      _descriptionFocusNode.add(FocusNode());
    }

    if (_isUpdate) {
      _prefillForm();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isUpdate && widget.reel != null) {
        // Fetch full reel details with product_id
        final Reel? reelDetails = await Get.find<ReelsController>().getReelDetails(widget.reel!.id!);
        if (reelDetails != null) {
          _selectedProductId = reelDetails.productId;
        }
      }

      // Load items/vehicles for the selector
      await Get.find<ReelsController>().getReelItemList();

      if (_isUpdate) {
        setState(() {});
      }
    });
  }

  void _prefillForm() {
    final reel = widget.reel!;

    // Debug: Print reel data
    print('========== EDIT REEL DATA ==========');
    print('Reel ID: ${reel.id}');
    print('Description: ${reel.description}');
    print('Order Now Button: ${reel.orderNowButton}');
    print('Selected Product ID (itemId): ${reel.itemId}');
    print('Thumbnail URL: ${reel.thumbnailFullUrl}');
    print('Video URL: ${reel.videoFullUrl}');
    print('Is Always Visible: ${reel.isAlwaysVisible}');
    print('Start Date: ${reel.startDate}');
    print('End Date: ${reel.endDate}');
    print('===================================');

    _descriptionController[0].text = reel.description ?? '';

    _networkThumbnailUrl = reel.thumbnailFullUrl;
    _networkVideoUrl = reel.videoFullUrl;
    if (_networkVideoUrl != null && _networkVideoUrl!.isNotEmpty) {
      _isVideoFile = true;
    }

    _orderNowButton = reel.orderNowButton ?? false;
    _selectedProductId = reel.itemId;

    if (reel.isAlwaysVisible == true) {
      _scheduleType = 0;
    } else {
      _scheduleType = 1;
      if (reel.startDate != null && reel.endDate != null) {
        try {
          DateTime start = DateTime.parse(reel.startDate!);
          DateTime end = DateTime.parse(reel.endDate!);
          _selectedDateRange = DateTimeRange(start: start, end: end);
          String firstDate = DateConverterHelper.stringToMDY(start.toString());
          String lastDate = DateConverterHelper.stringToMDY(end.toString());
          _dateRangeController.text = '$firstDate - $lastDate';
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _descriptionController) {
      controller.dispose();
    }
    for (var node in _descriptionFocusNode) {
      node.dispose();
    }
    _dateRangeController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  List<Item> _convertVehiclesToItems(dynamic data, {required bool isRental}) {
    if (data == null) return [];

    if (isRental && data is List<vehicle_model.Vehicles>) {
      return data.map((vehicle) => Item(id: vehicle.id, name: vehicle.name)).toList();
    } else if (!isRental && data is List<Item>) {
      return data;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
    return Scaffold(
      appBar: CustomAppBarWidget(title: _isUpdate ? 'update_reel'.tr : 'create_reel'.tr),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  _buildReelInfoSection(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  _buildReelValidationSection(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  _buildThumbnailUploadSection(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  _buildFileUploadSection(),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  _buildCallToActionSection(),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                ]),
              ),
            ),
          ),

          _buildBottomButtons(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showPreviewDialog,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CustomAssetImageWidget(Images.reelPreview, height: 100, width: 100),
              Positioned(
                bottom: -15, left: -3, right: -3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.remove_red_eye_outlined, size: 14, color: Theme.of(context).cardColor),
                    const SizedBox(width: 2),
                    Text('preview'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).cardColor)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReelInfoSection() {
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('reel_info'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'upload_a_video_and_add_details_to_create_a_new_reel_for_your_store'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(children: [
            SizedBox(
              height: 40,
              child: TabBar(
                tabAlignment: TabAlignment.start,
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).disabledColor,
                unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                labelPadding: const EdgeInsets.only(right: Dimensions.radiusDefault),
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: _tabs,
                onTap: (int? value) {
                  setState(() {});
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: Divider(height: 0),
            ),

            CustomTextFieldWidget(
              hintText: 'short_description'.tr,
              labelText: '${'short_description'.tr} (${_tabController!.index == 0 ? 'default'.tr : _languageList![_tabController!.index].value ?? ''})',
              controller: _descriptionController[_tabController!.index],
              focusNode: _descriptionFocusNode[_tabController!.index],
              capitalization: TextCapitalization.sentences,
              maxLines: 3,
              showTitle: false,
              required: _tabController!.index == 0,
              maxLength: 100,
              validator: (value) {
                if (_tabController!.index == 0 && (value == null || value.trim().isEmpty)) {
                  return 'enter_short_description'.tr;
                }
                return null;
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildReelValidationSection() {
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('reel_validation'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'here_you_can_setup_the_food_information'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(children: [
            Expanded(
              child: _buildRadioOption(
                title: 'all_time'.tr,
                subtitle: 'this_reel_will_always_be_visible_to_customers'.tr,
                value: 0,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: _buildRadioOption(
                title: 'custom_schedule'.tr,
                subtitle: 'specify_the_start_and_end_dates_for_the_reel'.tr,
                value: 1,
              ),
            ),
          ]),
        ),

        if (_scheduleType == 1) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),

          InkWell(
            onTap: () async {
              DateTimeRange? dateTimeRange = await showDateRangePicker(
                initialEntryMode: DatePickerEntryMode.calendar,
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(3000),
                currentDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );

              if (dateTimeRange != null) {
                _selectedDateRange = dateTimeRange;
                String firstDate = DateConverterHelper.stringToMDY(dateTimeRange.start.toString());
                String lastDate = DateConverterHelper.stringToMDY(dateTimeRange.end.toString());
                _dateRangeController.text = '$firstDate - $lastDate';
                setState(() {});
              }
            },
            child: CustomTextFieldWidget(
              controller: _dateRangeController,
              hintText: 'select_date'.tr,
              labelText: 'select_date'.tr,
              showTitle: false,
              isEnabled: false,
              suffixChild: Icon(Icons.date_range_rounded, color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildRadioOption({required String title, required String subtitle, required int value}) {
    final bool isSelected = _scheduleType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _scheduleType = value;
        });
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Radio<int>(
          value: value,
          groupValue: _scheduleType,
          onChanged: (int? val) {
            setState(() {
              _scheduleType = val!;
            });
          },
          activeColor: Theme.of(context).primaryColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: isSelected ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).disabledColor,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).disabledColor,
              ), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildThumbnailUploadSection() {
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Flexible(child: Text('upload_thumbnail_image'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            Text(' *'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).colorScheme.error)),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'thumbnail_image_format'.trParams({'size' : _maxFileSizeText}),
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Center(
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
              strokeWidth: 1,
              radius: const Radius.circular(Dimensions.radiusDefault),
            ),
            child: InkWell(
              onTap: _pickThumbnailImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.04),
                ),
                child: _thumbnailImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: Image.file(File(_thumbnailImage!.path), height: 120, width: 120, fit: BoxFit.cover),
                )
                    : _networkThumbnailUrl != null && _networkThumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImageWidget(image: _networkThumbnailUrl!, height: 120, width: 120, fit: BoxFit.cover),
                )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload_outlined, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text('click_to_add'.tr, style: robotoRegular.copyWith(
                    color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall,
                  )),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildFileUploadSection() {
    final reelsModule = Get.find<SplashController>().configModel!.reelsModule;
    final int maxSizeMb = reelsModule?.reelsMaxUploadSizeMb ?? 50;
    final int maxDuration = reelsModule?.reelsMaxDuration ?? 50;
    final String durationUnit = reelsModule?.reelsMaxDurationUnit ?? 'min';

    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Flexible(child: Text('upload_a_file'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            Text(' *'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).colorScheme.error)),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'mp4_mov_jpg_png'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: 2),
        Text(
          '${'max_size'.tr}: $maxSizeMb MB · ${'max_duration'.tr}: $maxDuration $durationUnit (9:16 ${'recommended'.tr})',
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
            strokeWidth: 1,
            radius: const Radius.circular(Dimensions.radiusDefault),
          ),
          child: InkWell(
            onTap: _pickMediaFile,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                color: Theme.of(context).disabledColor.withValues(alpha: 0.04),
              ),
              child: _mediaFile != null
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam, color: Theme.of(context).primaryColor, size: 36),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Flexible(
                      child: Text(
                        _mediaFile!.name,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ])
                : _networkVideoUrl != null && _networkVideoUrl!.isNotEmpty
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.videocam, color: Theme.of(context).primaryColor, size: 36),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Flexible(
                        child: Text(
                          'video_uploaded'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        'tap_to_change'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                      ),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_upload_outlined, color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text('click_to_add'.tr, style: robotoRegular.copyWith(
                        color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall,
                      )),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCallToActionSection() {
    bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
    return _sectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('call_to_action'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'call_to_action_desc'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isRental? 'book_now_button'.tr : 'order_now_button'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                const SizedBox(height: 2),
                Text(
                  isRental? 'show_book_now_button_on_reel'.tr : 'show_order_now_button_on_reel'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                ),
              ]),
            ),
            CustomToggleButtonWidget(
              isActive: _orderNowButton,
              onTap: () {
                setState(() {
                  _orderNowButton = !_orderNowButton;
                });
              },
            ),
          ]),
        ),

        if (_orderNowButton) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
        GetBuilder<ReelsController>(builder: (reelsController) {
          final bool isRental = Get.find<AuthController>().getModuleType() == 'rental';
          final List<Item> itemsToDisplay = _convertVehiclesToItems(
            isRental ? reelsController.reelVehicleList : reelsController.reelItemList,
            isRental: isRental,
          );

          return _orderNowButton
              ? ReelItemSelectorWidget(
                  items: itemsToDisplay,
                  selectedItemId: _selectedProductId,
                  isLoading: reelsController.isReelItemLoading,
                  onSelected: (value) => setState(() => _selectedProductId = value),
                )
              : const SizedBox.shrink();
        }),
      ]),
    );
  }


  Widget _buildBottomButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(children: [
            Expanded(
              child: CustomButtonWidget(
                buttonText: 'reset'.tr,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                textColor: Theme.of(context).textTheme.bodyLarge!.color,
                onPressed: _resetForm,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: GetBuilder<ReelsController>(builder: (reelsController) {
                return CustomButtonWidget(
                  isLoading: reelsController.isSubmitting,
                  buttonText: _isUpdate ? 'update'.tr : 'save'.tr,
                  onPressed: reelsController.isSubmitting ? null : _submitForm,
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickThumbnailImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final double imageSize = await ImageSize.getImageSizeFromXFile(image);
      final SplashController splashController = Get.find<SplashController>();
      if (imageSize > splashController.configModel!.validationConfig!.maxFileSize) {
        showCustomSnackBar(_imageSizeErrorText);
        return;
      }

      setState(() {
        _thumbnailImage = image;
      });
    }
  }

  Future<void> _pickMediaFile() async {
    final ImagePicker picker = ImagePicker();
    XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final reelsModule = Get.find<SplashController>().configModel!.reelsModule;
      final int maxSizeMb = reelsModule?.reelsMaxUploadSizeMb ?? 50;
      final int fileSizeInBytes = await File(video.path).length();
      final double fileSizeInMb = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMb > maxSizeMb) {
        showCustomSnackBar('${'video_size_exceeds'.tr} $maxSizeMb MB');
        return;
      }

      setState(() {
        _mediaFile = video;
        _isVideoFile = true;
      });
    }
  }

  void _showPreviewDialog() {
    Get.dialog(
      ReelPreviewDialogWidget(
        description: _descriptionController[0].text,
        thumbnailImage: _thumbnailImage,
        mediaFile: _isVideoFile ? _mediaFile : null,
        isVideoFile: _isVideoFile && _mediaFile != null,
        networkThumbnailUrl: _thumbnailImage == null ? _networkThumbnailUrl : null,
        networkVideoUrl: _mediaFile == null ? _networkVideoUrl : null,
        orderNowButton: _orderNowButton,
      ),
      barrierDismissible: true,
      useSafeArea: true,
    );
  }

  void _resetForm() {
    setState(() {
      for (var controller in _descriptionController) {
        controller.clear();
      }
      _dateRangeController.clear();
      _selectedDateRange = null;
      _scheduleType = 0;
      _thumbnailImage = null;
      _mediaFile = null;
      _isVideoFile = false;
      _orderNowButton = false;
      _selectedProductId = null;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_isUpdate && _thumbnailImage == null) {
        showCustomSnackBar('upload_thumbnail_image'.tr);
        return;
      }
      if (!_isUpdate && _mediaFile == null) {
        showCustomSnackBar('upload_a_file'.tr);
        return;
      }
      if (_scheduleType == 1 && _selectedDateRange == null) {
        showCustomSnackBar('select_date'.tr);
        return;
      }
      if (_orderNowButton && _selectedProductId == null) {
        showCustomSnackBar('please_select_item'.tr);
        return;
      }

      // Debug: Print form submission data
      print('========== SUBMIT REEL DATA ==========');
      print('Is Update: $_isUpdate');
      print('Reel ID: ${_isUpdate ? widget.reel!.id : "null (new reel)"}');
      print('Description: ${_descriptionController[0].text}');
      print('Order Now Button: $_orderNowButton');
      print('Selected Product ID: $_selectedProductId');
      print('Is Always Visible: ${_scheduleType == 0}');
      print('Schedule Type: $_scheduleType');
      print('Date Range: ${_selectedDateRange != null ? "${_selectedDateRange!.start} to ${_selectedDateRange!.end}" : "null"}');
      print('Thumbnail: ${_thumbnailImage != null ? "yes (${_thumbnailImage!.name})" : "no"}');
      print('Video: ${_mediaFile != null ? "yes (${_mediaFile!.name})" : "no"}');
      print('===================================');

      Get.find<ReelsController>().submitReel(
        descriptionControllers: _descriptionController,
        languageList: _languageList!,
        thumbnail: _thumbnailImage,
        video: _mediaFile,
        isAlwaysVisible: _scheduleType == 0,
        dateRange: _selectedDateRange,
        reelId: _isUpdate ? widget.reel!.id : null,
        orderNowButton: _orderNowButton,
        productId: _orderNowButton ? _selectedProductId : null,
      );
    }
  }
}

class CustomToggleButtonWidget extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const CustomToggleButtonWidget({super.key, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget toggle = Container(
      width: 40,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      padding: const EdgeInsets.all(1),
      child: Align(
        alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          height: 20, width: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
          ),
        ),
      ),
    );

    return onTap == null ? toggle : InkWell(onTap: onTap, child: toggle);
  }
}
