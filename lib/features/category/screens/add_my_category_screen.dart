import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/models/config_model.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_text_field_widget.dart';
import 'package:sixam_mart_store/features/category/controllers/category_controller.dart';
import 'package:sixam_mart_store/features/category/domain/models/category_model.dart';
import 'package:sixam_mart_store/features/category/screens/assign_my_category_screen.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class AddMyCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  const AddMyCategoryScreen({super.key, this.category});

  @override
  State<AddMyCategoryScreen> createState() => _AddMyCategoryScreenState();
}

class _AddMyCategoryScreenState extends State<AddMyCategoryScreen> with TickerProviderStateMixin {

  final List<Language>? _languageList = Get.find<SplashController>().configModel!.language;
  final List<TextEditingController> _nameControllers = [];
  final List<FocusNode> _nameNodes = [];
  final List<Tab> _tabs = [];
  TabController? _tabController;
  late bool _update;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _update = widget.category != null;
    _tabController = TabController(length: _languageList!.length, initialIndex: 0, vsync: this);

    for (int i = 0; i < _languageList.length; i++) {
      _nameControllers.add(TextEditingController(
        text: _update && i == 0 ? (widget.category!.name ?? '') : '',
      ));
      _nameNodes.add(FocusNode());
      _tabs.add(Tab(text: i == 0 ? 'default'.tr : _languageList[i].value));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<CategoryController>();
      if (_update) {
        controller.setSelectedPriority(controller.priorityKeyFromInt(widget.category!.priority));
        if (mounted) setState(() => _isLoadingDetails = true);
        final CategoryModel? fresh = await controller.fetchCategoryById(widget.category!.id!);
        if (!mounted) return;
        if (fresh != null) {
          for (final c in _nameControllers) { c.text = ''; }
          _nameControllers[0].text = fresh.name ?? '';
          if (fresh.translations != null) {
            for (final t in fresh.translations!) {
              final idx = _languageList.indexWhere((l) => l.key == t.locale);
              if (idx != -1 && t.key == 'name') {
                _nameControllers[idx].text = t.value ?? '';
              }
            }
          }
          controller.setSelectedPriority(controller.priorityKeyFromInt(fresh.priority));
        }
        setState(() => _isLoadingDetails = false);
      } else {
        controller.resetMyCategoryForm();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _nameControllers) { c.dispose(); }
    for (final n in _nameNodes) { n.dispose(); }
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildImagePreview(CategoryController controller) {
    if (controller.pickedCategoryImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: GetPlatform.isWeb
            ? Image.network(controller.pickedCategoryImage!.path, fit: BoxFit.cover)
            : Image.file(File(controller.pickedCategoryImage!.path), fit: BoxFit.cover),
      );
    }
    if (_update && widget.category?.imageFullUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: CustomImageWidget(
          image: widget.category!.imageFullUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.add_photo_alternate_outlined, size: 30, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Text(
        'click_to_add'.tr,
        style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall),
      ),
    ]);
  }

  String get _nameHint {
    final isDefault = _tabController!.index == 0;
    final label = isDefault ? 'default'.tr : (_languageList?[_tabController!.index].value ?? '');
    return '${'name'.tr} ($label)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: _update ? 'update_my_category'.tr : 'add_my_category'.tr),

      body: GetBuilder<CategoryController>(builder: (controller) {
        return Stack(children: [
          Column(children: [

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                if (!_update) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: const Color(0xFFFFE082), width: 1),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        height: 28, width: 28,
                        decoration: const BoxDecoration(color: Color(0xFFFFA726), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          'my_category_list_note'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF7A5C00)),
                        ),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text('category_info'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  'setup_category_information_here'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Language tab section
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    SizedBox(
                      height: 40,
                      child: TabBar(
                        tabAlignment: TabAlignment.start,
                        controller: _tabController,
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorWeight: 3,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Theme.of(context).hintColor,
                        unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                        labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                        labelPadding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                        indicatorPadding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: _tabs,
                        onTap: (_) => setState(() {}),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      child: Divider(height: 0),
                    ),
                    CustomTextFieldWidget(
                      required: true,
                      hintText: _nameHint,
                      labelText: _nameHint,
                      controller: _nameControllers[_tabController!.index],
                      focusNode: _nameNodes[_tabController!.index],
                      inputType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      showTitle: false,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Priority dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    RichText(text: TextSpan( children: [
                      TextSpan( text: 'priority'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      TextSpan( text: ' *'.tr, style: robotoMedium.copyWith(color: Colors.red)),
                    ])),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    DropdownButtonFormField<String>(
                      initialValue: controller.selectedPriority,
                      hint: Text('select_priority'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 0.5),
                        ),
                      ),
                      items: controller.priorityList.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.tr, style: robotoRegular),
                      )).toList(),
                      onChanged: controller.setSelectedPriority,
                    ),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Image picker
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    RichText(text: TextSpan( children: [
                      TextSpan( text: 'category_image'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      TextSpan( text: ' *'.tr, style: robotoMedium.copyWith(color: Colors.red)),
                    ])),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'jpg_jpeg_png_less_2mb_ratio_1_1'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Center(
                      child: InkWell(
                        onTap: controller.pickCategoryImage,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 1,
                            strokeCap: StrokeCap.butt,
                            dashPattern: const [5, 5],
                            padding: const EdgeInsets.all(0),
                            radius: const Radius.circular(Dimensions.radiusDefault),
                          ),
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: _buildImagePreview(controller),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ]),
                ),

              ]),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)],
            ),
            child: CustomButtonWidget(
              buttonText: _update ? 'update'.tr : 'add'.tr,
              isLoading: controller.isSubmitLoading,
              onPressed: controller.isSubmitLoading ? null : () => _submit(controller),
            ),
          ),

          ]),
          if (_isLoadingDetails)
            SizedBox.shrink()
        ]);
      }),
    );
  }

  Future<void> _submit(CategoryController controller) async {
    final name = _nameControllers[0].text.trim();
    if (name.isEmpty) {
      showCustomSnackBar('enter_category_name'.tr);
      return;
    }
    if (controller.selectedPriority == null) {
      showCustomSnackBar('select_priority'.tr);
      return;
    }

    // Check for duplicate category name
    if (!_update && controller.myCategories != null) {
      final isDuplicate = controller.myCategories!.any((category) =>
        category.name?.toLowerCase() == name.toLowerCase()
      );
      if (isDuplicate) {
        showCustomSnackBar('category_already_exists'.tr, isError: true);
        return;
      }
    }

    final List<Translation> translations = [];
    for (int i = 0; i < _languageList!.length; i++) {
      translations.add(Translation(
        locale: _languageList[i].key,
        key: 'name',
        value: _nameControllers[i].text.trim().isNotEmpty
            ? _nameControllers[i].text.trim()
            : name,
      ));
    }

    final String priorityValue = controller.priorityValueFromKey(controller.selectedPriority!);
    if (_update) {
      controller.updateStoreCategoryApi(widget.category!.id!, translations, priorityValue);
    } else {
      final created = await controller.addStoreCategoryApi(translations, priorityValue);
      if (created != null && created.id != null && mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return AssignMyCategoryScreen(categoryId: created.id!, categoryName: created.name ?? name);
          }
        );
      }
    }
  }
}
