import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/pages/entry_pages/sign_in_page.dart';
import 'package:instagramlesson/pages/entry_pages/sign_up_page.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/utils_service.dart';

class AuthenticationService {
  static final _auth = FirebaseAuth.instance;

  static Future<User?> signUpUser(BuildContext context, String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(name);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Utils.snackBar(context, 'The password provided is too weak.', null);
      } else if (e.code == 'email-already-in-use') {
        Utils.snackBar(context, 'The account already exists.', null);
      } else {
        Utils.snackBar(context, 'Something went wrong, try again...', null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in signing up: $e');
      }
      Utils.snackBar(context, 'Something went wrong, try again...', null);
    }
    return null;
  }

  static Future<User?> signInUser(
      BuildContext context, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (kDebugMode) {
        print(userCredential.user.toString());
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Utils.snackBar(context, 'The email is not registered.', null);
      } else if (e.code == 'wrong-password') {
        Utils.snackBar(context, 'Wrong password.', null);
      }
    }
    return null;
  }

  static void signOutUser(BuildContext context) async {
    await _auth.signOut();
    HiveService.removeUid();
    Navigator.pushReplacementNamed(context, SignInPage.id);
  }

  static void deleteAccount(BuildContext context) async {
    try {
      _auth.currentUser!.delete();
      HiveService.removeUid();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignUpPage()), (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Utils.snackBar(context, 'The user must re-authenticate before this operation can be executed.', null);
      }
    }
  }
}