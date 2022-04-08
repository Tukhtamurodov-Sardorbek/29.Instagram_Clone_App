import 'dart:convert';
import 'package:http/http.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/utils_service.dart';

class HttpService {
  static String BASE = 'fcm.googleapis.com';
  static String API_SEND = '/fcm/send';
  static Map<String, String> headers = {
    'Authorization': 'key=AAAA7fuYkM0:APA91bFTae4czLMkjVIueh8iLU9fUnQuxXbxJfN2vm7cppGjNTkjRO3p_ABD10WdA9kQPeJXpiPIEbHjsb1Hm5XwNtQzFQc6DRC0s9FGZ8F3qumco5GaQ5-7L1dzduRLdd1CoH75HWr6',
    'Content-Type': 'application/json'
  };

  static Future<String?> POST(Map<String, dynamic> body) async {
    var uri = Uri.https(BASE, API_SEND);
    var response = await post(uri, headers: headers, body: jsonEncode(body));
    if(response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    }
    return null;
  }

  // static Future<UserModel> loadMe() async {
  //   String uid = HiveService.getUID();
  //   var value = await FirebaseFirestore.instance.collection("users").doc(uid).get();
  //   UserModel user = UserModel.fromJson(value.data()!);
  //   return user;
  // }


  static Map<String, dynamic> bodyFollow(String fcmToken, String myName) {
    Map<String, dynamic> body = {};
    body.addAll({
      'notification': {
        'title': 'Instagram',
        'body': '$myName started following you'
      },
      'registration_ids': [fcmToken],
      'click_action': 'FLUTTER_NOTIFICATION_CLICK'
    });
    return body;
  }

  static Map<String, dynamic> bodyLike(String fcmToken, String myName) {
    Map<String, dynamic> body = {};
    body.addAll({
      'notification': {
        'title': 'Instagram',
        'body': '$myName liked your post'
      },
      'registration_ids': [fcmToken],
      'click_action': 'FLUTTER_NOTIFICATION_CLICK'
    });
    return body;
  }
}