import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Constants/Strings.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Models/SliderImageModel.dart';
import 'package:mathlab_admin/Screen/AdminSettings/Service/AdminSettingsController.dart';
import 'dart:html' as html if (dart.library.io) 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class SliderImageView extends StatefulWidget {
  const SliderImageView({super.key});

  @override
  State<SliderImageView> createState() => _SliderImageViewState();
}

class _SliderImageViewState extends State<SliderImageView> {
  AdminSettingsController ctrl = Get.put(AdminSettingsController());
  String? selectedImagePath;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _orderController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadSliderImages();
    });
  }

  Future<void> pickImage() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.onLoadEnd.listen((e) {
            setState(() {
              selectedImagePath = "WEB_FILE:${file.name}:${reader.result}";
            });
          });
          reader.readAsDataUrl(file);
        }
      });
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedImagePath = result.files.single.path;
        });
      }
    }
  }

  Future<void> addImage() async {
    if (selectedImagePath == null || selectedImagePath!.isEmpty) {
      ShowToast(title: "Error", body: "Please select an image");
      return;
    }

    final order = int.tryParse(_orderController.text.trim());
    bool success = await ctrl.addSliderImage(
      selectedImagePath,
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      shortDescription: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      displayOrder: order,
    );
    if (success) {
      ShowToast(title: "Success", body: "Slider image added successfully");
      setState(() {
        selectedImagePath = null;
        _titleController.clear();
        _descController.clear();
        _orderController.clear();
      });
    } else {
      ShowToast(title: "Error", body: "Failed to add slider image");
    }
  }

  /// API origin (scheme + host + port) so image URLs load from the API server, not the current origin.
  String get _apiOrigin {
    final uri = Uri.parse(endpoint);
    return uri.origin;
  }

  String _imageUrl(SliderImageModel image) {
    // Prefer full URL from API; if relative, prepend API origin so the image loads from the API server
    if (image.imageUrl != null && image.imageUrl!.isNotEmpty) {
      final u = image.imageUrl!;
      if (u.startsWith('http')) return u;
      return _apiOrigin + (u.startsWith('/') ? u : '/$u');
    }
    // Fallback: build URL from stored path (e.g. "banners/file.png" -> origin + /media/ + path)
    if (image.images == null || image.images!.isEmpty) return '';
    if (image.images!.startsWith('http')) return image.images!;
    final path = image.images!.startsWith('/') ? image.images!.substring(1) : image.images!;
    return _apiOrigin + '/media/' + path;
  }

  void _showEditDialog(SliderImageModel image) {
    final tCtrl = TextEditingController(text: image.title ?? '');
    final dCtrl = TextEditingController(text: image.shortDescription ?? '');
    final oCtrl = TextEditingController(text: '${image.displayOrder ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tCtrl,
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Short description (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Display order (priority)',
                    hintText: '0 = first'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final order = int.tryParse(oCtrl.text.trim());
              final success = await ctrl.updateSliderImage(
                image.imagesId!,
                title: tCtrl.text.trim().isEmpty ? null : tCtrl.text.trim(),
                shortDescription: dCtrl.text.trim().isEmpty ? null : dCtrl.text.trim(),
                displayOrder: order,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (success) ShowToast(title: "Success", body: "Banner updated");
              else ShowToast(title: "Error", body: "Update failed");
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminSettingsController>(
      builder: (controller) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  tx700("Banner / Slider Images", size: 25, color: Colors.black54),
                  Expanded(child: Container()),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text("Select Image"),
                  ),
                  SizedBox(width: 10),
                  if (selectedImagePath != null)
                    ElevatedButton.icon(
                      onPressed: addImage,
                      icon: Icon(Icons.upload),
                      label: Text("Upload"),
                    ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => ctrl.loadSliderImages(),
                  ),
                ],
              ),
              if (selectedImagePath != null) ...[
                SizedBox(height: 12),
                Text("Optional: add title, description and display order (lower = first).", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title (optional)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: 'Short description (optional)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 6),
                TextField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Display order (priority)',
                    hintText: '0 = first',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kIsWeb
                              ? selectedImagePath!.split(":")[1]
                              : selectedImagePath!.split("/").last,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20),
              if (controller.isLoadingSliderImages)
                Center(child: CircularProgressIndicator())
              else if (controller.sliderImages.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("No slider images found. Upload JPEG, PNG or WebP."),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.sliderImages.length,
                  itemBuilder: (context, index) {
                    final image = controller.sliderImages[index];
                    final url = _imageUrl(image);
                    return Card(
                      child: Stack(
                        children: [
                          if (url.isNotEmpty)
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('Image unavailable', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('No image URL', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Order: ${image.displayOrder ?? 0}",
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showEditDialog(image),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    bool success = await ctrl.deleteSliderImage(image.imagesId!);
                                    if (success) ShowToast(title: "Success", body: "Image deleted successfully");
                                    else ShowToast(title: "Error", body: "Failed to delete image");
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (image.title != null && image.title!.isNotEmpty)
                            Positioned(
                              left: 6,
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  image.title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              if (controller.sliderImages.length >= 10)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Maximum 10 slider images allowed",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

