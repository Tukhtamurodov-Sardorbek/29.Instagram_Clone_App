import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/pages/insta_feed_page.dart';
import 'package:instagramlesson/pages/insta_likes_page.dart';
import 'package:instagramlesson/pages/insta_profile_page.dart';
import 'package:instagramlesson/pages/insta_search_page.dart';
import 'package:instagramlesson/pages/insta_upload_page.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/utils_service.dart';

class HomePage extends StatefulWidget {
  static const String id = '/home_page';
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController pageController = PageController();
  int currentPage = 0;
  DateTime? lastPressed;

  _initNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("Message: ${message.notification.toString()}");
      }
      Utils.showLocalNotification(message, context);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Utils.showLocalNotification(message, context);
    });
  }

  @override
  void initState() {
    super.initState();
    _initNotification();
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
      body: WillPopScope(
        onWillPop: () async{
          final now = DateTime.now();
          const maxDuration = Duration(seconds: 2);
          final isWarning = lastPressed == null || now.difference(lastPressed!) > maxDuration;

          if(isWarning){
            lastPressed = DateTime.now();
            // doubleTap(context);
            return false;
          } else{
            return true;
          }
        },
        child: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            FeedPage(controller: pageController),
            const SearchPage(),
            UploadPage(controller: pageController),
            const LikesPage(),
            const ProfilePage()
            // FeedPage(pageController: pageController),
            // const SearchPage(),
            // UploadPage(pageController: pageController),
            // const NotificationsPage(),
            // const ProfilePage(),
          ],
          onPageChanged: (int index) {
            setState(() {
              currentPage = index;
            });
          },
        ),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: currentPage,
        activeColor: ColorService.lightColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.add_box)),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
        onTap: (int index) {
          pageController.jumpToPage(index);
        },
      ),
    );
  }
}
