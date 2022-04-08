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

class SignInPage extends StatefulWidget {
  static const String id = '/sign_in_page';
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool isHidden = true;
  bool isLoading = false;
  bool _clearEmail = false;
  DateTime? lastPressed;


  void _signIn() async {
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
    String email = _emailController.text.trim().toString();
    String password = _passwordController.text.trim().toString();

    if (email.isEmpty || password.isEmpty) {
      Utils.snackBar(context, 'Fill in the fields, please!', ColorService.snackBarColor);
      setState(() {
        isLoading = false;
      });
      return;
    }

    await AuthenticationService.signInUser(context, email, password)
        .then((value) => _getFirebaseUser(value));
  }

  void _getFirebaseUser(User? user) {
    if (user != null) {
      HiveService.storeUID(user.uid);
      _apiUpdateUser();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
    setState(() {
      isLoading = false;
    });
  }

  void _apiUpdateUser() async {
    UserModel user = await FirestoreService.loadUser(null);
    user.deviceToken = HiveService.getToken();
    await FirestoreService.updateUser(user);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Utils.initNotification();
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
                          textInputAction: TextInputAction.done,
                          obscureText: isHidden,
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
                                    isHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined
                                ),
                                color: Colors.white54,
                                onPressed: (){
                                  setState(() {
                                    isHidden = !isHidden;
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
                      color: ColorService.entryButtonColor,
                      minWidth: MediaQuery.of(context).size.width,
                      height: 40,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Colors.white54)
                      ),
                      elevation: 20,
                      child: isLoading
                          ? const Center(child: SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white)),)
                          : const Text('Sign In', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                      onPressed: (){
                        setState(() {
                          isLoading = true;
                        });
                        _signIn();
                      },
                    )
                  ],
                )
              ),
              // #Sign Up
              SignUpFooter(context)
            ],
          ),
        ),
      ),
    );
  }
}
