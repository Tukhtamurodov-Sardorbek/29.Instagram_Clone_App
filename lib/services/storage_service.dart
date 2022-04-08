import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instagramlesson/services/hive_service.dart';

class StorageService {
  static final Reference _storage = FirebaseStorage.instance.ref();
  static const postFolder = 'post_images';
  static const highlightFolder = 'highlight_images';
  static const userFolder = 'profile_images';

  // #store user profile image
  static Future<String?> uploadUserImage(File _image) async {
    String uid = HiveService.getUID();
    String profileImage = uid;
    Reference firebaseStorageRef = _storage.child(userFolder).child(profileImage);
    UploadTask uploadTask = firebaseStorageRef.putFile(_image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // #store user post
  static Future<String?> uploadHighlightImage(File? _image) async {
    if (_image == null) return null;
    String uid =  HiveService.getUID();
    String imageName = 'file_' + DateTime.now().toString();
    Reference firebaseStorageRef = _storage.child(highlightFolder).child(imageName);
    UploadTask uploadTask = firebaseStorageRef.putFile(_image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // #store user post
  static Future<String?> uploadPostImage(File? _image) async {
    if (_image == null) return null;
    String uid =  HiveService.getUID();
    String imageName = "file_" + DateTime.now().toString();
    Reference firebaseStorageRef = _storage.child(postFolder).child(imageName);
    UploadTask uploadTask = firebaseStorageRef.putFile(_image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}