import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instagramlesson/models/post_model.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/storage_service.dart';
import 'package:instagramlesson/services/utils_service.dart';
import 'package:instagramlesson/widgets/appBar.dart';
import 'package:image_picker/image_picker.dart';

class UploadPage extends StatefulWidget {
  static const String id = '/upload_page';
  PageController controller;
  UploadPage({Key? key, required this.controller}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();
  bool isLoading = false;
  File? _image;
  var selectedImageSize = '';

  // #camera
  _imageFromCamera() async {
    XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);

    setState(() {
      _image = File(image!.path);
      selectedImageSize = _image != null ?(_image!.lengthSync() / 1024 / 1024).toStringAsFixed(2) + ' Mb' : '';
    });
  }

  // #gallery
  _imageFromGallery() async {
    XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    setState(() {
      _image = File(image!.path);
      selectedImageSize = _image != null ?(_image!.lengthSync() / 1024 / 1024).toStringAsFixed(2) + ' Mb' : '';
    });
  }

  // #gallery or camera
  void _mediaSource(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    _imageFromGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    _imageFromCamera();
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        });
  }

  // #upload button
  void _uploadPost(){
    _captionFocus.unfocus();
    String caption = _captionController.text.toString().trim();
    if(_image == null && caption.isEmpty){
      Utils.snackBar(context, 'Attach a photo and make a caption, please!', ColorService.deepColor);
      return;
    }else if(_image == null){
      Utils.snackBar(context, 'Attach a photo, please!', ColorService.deepColor);
      return;
    } else if(caption.isEmpty){
      Utils.snackBar(context, 'Leave a caption, please!', ColorService.deepColor);
      return;
    }
    _postImage(caption);
  }

  void _postImage(String caption) {
    setState(() {
      isLoading = true;
    });
    StorageService.uploadPostImage(_image).then((downloadUrl) => {_resPostImage(caption, downloadUrl!)});
  }

  void _resPostImage(String caption, String downloadUrl) {
    Post post = Post(caption: caption, image: downloadUrl);
    _apiStorePost(post);
  }

  void _apiStorePost(Post post) async {
    Post posted = await FirestoreService.storePost(post);
    FirestoreService.storeFeed(posted).then((value) => {_moveToFeed()});
  }

  void _moveToFeed() {
    setState(() {
      isLoading = false;
      _image = null;
      _captionController.clear();
    });
    widget.controller.jumpToPage(0);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _captionController.dispose();
    _captionFocus.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if(mounted){
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(text: 'Upload', isCentered: true),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                // #pick image
                GestureDetector(
                  child: Container(
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey.withOpacity(0.4),
                    child: _image == null
                        ? const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              color: Colors.grey,
                              size: 80,
                            ),
                          )
                        : Stack(
                            children: [
                              Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(0, 4.0, 4.0, 0),
                                  height: 26,
                                  width: 26,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle
                                  ),
                                  child: IconButton(
                                    splashRadius: 1,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                        Icons.cancel_outlined,
                                        color: ColorService.lightColor,
                                        size: 26
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _image = null;
                                      });
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                  ),

                  onTap: () {
                    _image == null ? _mediaSource(context) : () {};
                  },
                ),
                const SizedBox(height: 5),
                selectedImageSize.isNotEmpty
                    ? Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 10.0),
                  child: Text('Size: $selectedImageSize',
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                )
                    : const SizedBox(),
                const SizedBox(height: 5),
                // #comment
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _captionController,
                      focusNode: _captionFocus,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                          label: const Text('Write a caption...'),
                          labelStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: ColorService.lightColor.withOpacity(0.7)
                          ),
                          border: InputBorder.none,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: ColorService.lightColor,
                                  width: 2
                              )
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: ColorService.lightColor,
                                  width: 4
                              )
                          )
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: MaterialButton(
                    height: 45,
                    minWidth: MediaQuery.of(context).size.width,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    color: ColorService.lightColor,
                    child: isLoading
                        ? const Center(child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Colors.white)),)
                        : const Text(
                        'Upload',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    onPressed: _uploadPost,
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
