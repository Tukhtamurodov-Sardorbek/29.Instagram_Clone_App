import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class Utils {
   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

   static initNotification() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await _firebaseMessaging.getToken().then((String? token) {
      assert(token != null);
      HiveService.storeToken(token!);
      if (kDebugMode) {
        print(token);
      }
    });
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar(BuildContext context, String message, Color? color){
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color ?? ColorService.snackBarColor, duration: const Duration(seconds: 3)));
  }

  ScaffoldMessengerState doubleTap(BuildContext context){
    return ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Double tap to close app'), duration: Duration(seconds: 2)));
  }

  static bool validatePassword(String value) {
    return RegExp( r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~+-]).{8,30}$').hasMatch(value);
  }

  static bool validateEmail(String email) {
    return RegExp(r'^([a-zA-z\d\.\-\_]+)@[a-z]+\.[a-z]+(\.[a-z]+)?$')
        .hasMatch(email);
  }

  static Future<bool> dialog(BuildContext context, String title, String message, bool isSingle) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)
            ),
            backgroundColor: ColorService.lightColor.withOpacity(0.9),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 30, fontFamily: 'instagramFont'), textAlign: TextAlign.center),
            content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            actions: [
              !isSingle
                  ? GestureDetector(
                onTap: () {
                  Navigator.pop(context, false);
                },
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, true);
                },
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Confirm",
                    style: TextStyle(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          );
        });
  }

  static Future<Map<String, String>> deviceParams() async {
    Map<String, String> params = {};
    var deviceInfo = DeviceInfoPlugin();
    String fcmToken = HiveService.getToken();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      params.addAll({
        'device_id': iosDeviceInfo.identifierForVendor!,
        'device_type': "IOS",
        'device_token': fcmToken
      });
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      params.addAll({
        'device_id': androidDeviceInfo.androidId!,
        'device_type': "Android",
        'device_token': fcmToken
      });
    }
    return params;
  }

  static Future<void> showLocalNotification(RemoteMessage message, BuildContext context) async {
    String title = message.notification!.title!;
    String body = message.notification!.body!;

    var android = const AndroidNotificationDetails("channelId", "channelName",
        channelDescription: "channelDescription");
    var iOS = const IOSNotificationDetails();
    var platform = NotificationDetails(android: android, iOS: iOS);

    int id = Random().nextInt((pow(2, 31) - 1).toInt());
    await FlutterLocalNotificationsPlugin().show(id, title, body, platform);

    showToastWidget(
        Container(
          width: MediaQuery.of(context).size.width*0.7,
          alignment: Alignment.centerLeft,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)
          ),
          child: Row(
            children: [
              Image.asset('assets/icons/ic_launcher_round.png', height: 25, width: 25),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 2,),
                  Expanded(child: Text(body, style: const TextStyle(fontSize: 11, color: Colors.black))),
                ],
              )
            ],
          ),
        ),
        context: context,
        animation: StyledToastAnimation.slideFromTop,
        reverseAnimation: StyledToastAnimation.slideToTop,
        position: StyledToastPosition.top,
        startOffset: const Offset(0.0, -3.0),
        reverseEndOffset: const Offset(0.0, -3.0),
        duration: const Duration(seconds: 4),
        //Animation duration   animDuration * 2 <= duration
        animDuration: const Duration(seconds: 1),
        curve: Curves.elasticOut,
        reverseCurve: Curves.fastOutSlowIn
    );
  }
}
