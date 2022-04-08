import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/pages/home_page.dart';
import 'package:instagramlesson/services/authentication_service.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/utils_service.dart';
import 'package:instagramlesson/widgets/entry_page/footers.dart';

class SignUpPage extends StatefulWidget {
  static const String id = '/sign_up_page';
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _clearName = false;
  bool _clearEmail = false;
  bool isLoading = false;
  bool isHidden1 = true;
  bool isHidden2 = true;
  DateTime? lastPressed;

  void _signUp() async{
    _nameFocus.unfocus();
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
    _confirmPasswordFocus.unfocus();

    String username = _nameController.text.toString().trim();
    String email = _emailController.text.toString().trim();
    String password = _passwordController.text.toString().trim();
    String confirmPassword = _confirmPasswordController.text.toString().trim();
    if(username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty){
      Utils.snackBar(context, 'Fill in the fields, please!', ColorService.snackBarColor);
      setState(() {
        isLoading = false;
      });
      return;
    }
    else if (Utils.validateEmail(email) == false) {
      Utils.snackBar(context, 'Enter a valid email address, please!', ColorService.snackBarColor);
      setState(() {
        isLoading = false;
      });
      return;
    }
    else if (Utils.validatePassword(password) == false) {
      Utils.snackBar(context, 'Password must contain at least one upper case, one lower case, one digit, one special character and be at least 8 characters in length', ColorService.snackBarColor);
      setState(() {
        isLoading = false;
      });
      return;
    }
    else if(password != confirmPassword){
      Utils.snackBar(context, 'Confirm password correctly, please!', ColorService.snackBarColor);
      setState(() {
        isLoading = false;
      });
      return;
    }

    UserModel user = UserModel(username: username, email: email, password: password);
    await AuthenticationService.signUpUser(context, username, email, password)
        .then((value) => _getFirebaseUser(user, value));

  }

  void _getFirebaseUser(UserModel userModel, User? user) {
    if (user != null) {
      HiveService.storeUID(user.uid);
      FirestoreService.storeUser(userModel).then((value) => Navigator.pushReplacementNamed(context, HomePage.id));
    } else {
      Utils.snackBar(context, 'Check your data, please!', ColorService.snackBarColor);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
        child: Container(
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
            children: [
              Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // #Instagram
                      const Center(
                          child: Text('Instagram', style: TextStyle(color: Colors.white, fontSize: 45, fontFamily: 'instagramFont'))
                      ),
                      const SizedBox(height: 20),
                      // #Name
                      SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 30,
                          child: TextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                                filled: true,
                                fillColor: Colors.white54.withOpacity(0.2),
                                hintText: 'Nickname',
                                hintStyle: const TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.person, color: Colors.white54),
                                suffixIcon: _clearName ? IconButton(
                                    splashRadius: 1,
                                    icon: const Icon(CupertinoIcons.clear, size: 18, color: Colors.white54),
                                    onPressed: (){
                                      setState(() {
                                        _clearName = false;
                                        _nameController.clear();
                                      });
                                    }
                                ) : const SizedBox(),


                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                enabledBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                focusedBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                )
                            ),
                            onChanged: (name) {
                              setState(() {
                                _clearName = _nameController.text.isNotEmpty;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // #Email
                      SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 30,
                          child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                                filled: true,
                                fillColor: Colors.white54.withOpacity(0.2),
                                hintText: 'Email',
                                hintStyle: const TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.mail, color: Colors.white54),
                                suffixIcon: _clearEmail ? IconButton(
                                    splashRadius: 1,
                                    icon: const Icon(CupertinoIcons.clear, size: 18, color: Colors.white54),
                                    onPressed: (){
                                      setState(() {
                                        _clearEmail = false;
                                        _emailController.clear();
                                      });
                                    }
                                    ) : const SizedBox(),


                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                enabledBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                focusedBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                )
                            ),
                            onChanged: (email) {
                            setState(() {
                              _clearEmail = _emailController.text.isNotEmpty;
                            });
                          },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // #Password
                      SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 30,
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            obscureText: isHidden1,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                                filled: true,
                                fillColor: Colors.white54.withOpacity(0.2),
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                                suffixIcon: IconButton(
                                  splashRadius: 1,
                                  icon:  Icon(
                                      isHidden1
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined
                                  ),
                                  color: Colors.white54,
                                  onPressed: (){
                                    setState(() {
                                      isHidden1 = !isHidden1;
                                    });
                                  },
                                ),


                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                enabledBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                focusedBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                )
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // #Confirm Password
                      SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 30,
                          child: TextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            obscureText: isHidden2,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                                filled: true,
                                fillColor: Colors.white54.withOpacity(0.2),
                                hintText: 'Confirm password',
                                hintStyle: const TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                                suffixIcon: IconButton(
                                  splashRadius: 1,
                                  icon:  Icon(
                                      isHidden2
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined
                                  ),
                                  color: Colors.white54,
                                  onPressed: (){
                                    setState(() {
                                      isHidden2 = !isHidden2;
                                    });
                                  },
                                ),


                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                enabledBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                ),
                                focusedBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(color: Colors.transparent)
                                )
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // #Sign in button
                      MaterialButton(
                        height: 40,
                        minWidth: MediaQuery.of(context).size.width,
                        elevation: 20,
                        color: ColorService.entryButtonColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.white54)
                        ),
                        child: isLoading
                            ? const Center(child: SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white)))
                            : const Text('Sign Up', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                        onPressed:  () {
                          setState(() {
                            isLoading = true;
                          });
                          _signUp();
                        },
                      ),

                    ],
                  )
              ),
              // #Sign In
              SignInFooter(context)
            ],
          ),
        ),
      ),
    );
  }
}
