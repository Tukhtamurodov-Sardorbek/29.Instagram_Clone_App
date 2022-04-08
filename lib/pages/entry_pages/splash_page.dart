import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/pages/entry_pages/sign_in_page.dart';
import 'package:instagramlesson/pages/home_page.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/utils_service.dart';

class SplashPage extends StatefulWidget {
  static const String id = '/splash_page';
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  Widget _openNextPage() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, value) {
        if(value.hasData) {
          HiveService.storeUID(value.data!.uid);
          return const HomePage();
        } else {
          HiveService.removeUid();
          return const SignInPage();
        }
      },
    );
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Utils.initNotification();
    // Future.delayed(Duration.zero, () async {
    //   await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    // });
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => _openNextPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorService.lightColor,
                ColorService.deepColor,
              ]
            )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Expanded(
                  child: Center(
                      child: Text('Instagram', style: TextStyle(color: Colors.white, fontSize: 45, fontFamily: 'instagramFont'))
                  ),
              ),
              Text('All rights are reserved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
            ],
          ),
        )
    );
  }
}
