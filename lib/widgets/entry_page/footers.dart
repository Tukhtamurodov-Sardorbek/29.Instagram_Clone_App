import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/pages/entry_pages/sign_in_page.dart';
import 'package:instagramlesson/pages/entry_pages/sign_up_page.dart';

Widget SignUpFooter(BuildContext context){
  return RichText(
    text: TextSpan(
        text: 'Don\'t have an account? ',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        children: [
          TextSpan(
            text: 'Sign up',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            recognizer: TapGestureRecognizer()..onTap = (){
              Navigator.pushReplacementNamed(context, SignUpPage.id);
            },
          )
        ]
    ),
  );
}

Widget SignInFooter(BuildContext context){
  return RichText(
    text: TextSpan(
        text: 'Already have an account? ',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        children: [
          TextSpan(
            text: 'Sign in',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            recognizer: TapGestureRecognizer()..onTap = (){
              Navigator.pushReplacementNamed(context, SignInPage.id);
            },
          )
        ]
    ),
  );
}