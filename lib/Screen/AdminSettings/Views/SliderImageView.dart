import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Constants/Strings.dart';
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

    bool success = await ctrl.addSliderImage(selectedImagePath);
    if (success) {
      ShowToast(title: "Success", body: "Slider image added successfully");
      setState(() {
        selectedImagePath = null;
      });
    } else {
      ShowToast(title: "Error", body: "Failed to add slider image");
    }
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
                  tx700("Slider Images", size: 25, color: Colors.black54),
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
              SizedBox(height: 20),
              if (selectedImagePath != null)
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
              SizedBox(height: 20),
              if (controller.isLoadingSliderImages)
                Center(child: CircularProgressIndicator())
              else if (controller.sliderImages.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("No slider images found"),
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
                    return Card(
                      child: Stack(
                        children: [
                          if (image.images != null)
                            Image.network(
                              image.images!.startsWith("http")
                                  ? image.images!
                                  : "$endpoint${image.images}",
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool success = await ctrl.deleteSliderImage(
                                  image.imagesId!,
                                );
                                if (success) {
                                  ShowToast(
                                    title: "Success",
                                    body: "Image deleted successfully",
                                  );
                                } else {
                                  ShowToast(
                                    title: "Error",
                                    body: "Failed to delete image",
                                  );
                                }
                              },
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

