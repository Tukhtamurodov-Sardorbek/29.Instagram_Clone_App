import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagramlesson/models/post_model.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/services/authentication_service.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/storage_service.dart';
import 'package:instagramlesson/services/utils_service.dart';


class ProfilePage extends StatefulWidget {
  static const String id = '/profile_page';
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  UserModel profileOwner = UserModel(password: '', username: '', email: '');
  int postsNumber = 0;
  File? _image;

  List<Post> posts = [];

  late TabController _tabController;
  int tabIndex = 0;
  double heightTabBarView = 0;
  List<Tab> tabs = <Tab>[
    const Tab(icon: Icon(Icons.grid_off, size: 24)),
    const Tab(icon: Icon(Icons.grid_view, size: 24)),
    const Tab(icon: Icon(Icons.grid_on_sharp, size: 24)),
  ];

  // #camera
  _imageFromCamera() async {
    XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);

    setState(() {
      _image = File(image!.path);
    });
    _changeProfilePhoto();
  }

  // #gallery
  _imageFromGallery() async {
    XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    setState(() {
      _image = File(image!.path);
    });
    _changeProfilePhoto();
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

  void _changeProfilePhoto() {
    if (_image == null) return;
    setState(() {
      isLoading = true;
    });
    StorageService.uploadUserImage(_image!)
        .then((downLoadUrl) => _apiUpdateUser(downLoadUrl!));
  }

  void _apiUpdateUser(String downLoadUrl) async {
    UserModel userModel = await FirestoreService.loadUser(null);
    userModel.profileImageURL = downLoadUrl;
    await FirestoreService.updateUser(userModel);
    await FirestoreService.updateMyPostsInFollowersFeed(userModel);
    _getUserFromFirestore();
  }

  void _getUserFromFirestore() {
    setState(() {
      isLoading = true;
    });
    FirestoreService.loadUser(null).then((value) => _showUserData(value));
  }

  void _showUserData(UserModel user) {
    setState(() {
      profileOwner = user;
      isLoading = false;
    });
  }

  void _getPosts() {
    setState(() {
      isLoading = true;
    });
    FirestoreService.loadPosts(null).then((value) => {_resLoadPosts(value)});
  }

  void _resLoadPosts(List<Post> _posts) {
    if (_posts.isEmpty) {
      setState(() {
        posts = HiveService.loadPosts();
      });
    } else {
      setState(() {
        posts = _posts;
      });
      HiveService.storePosts(posts);
    }

    setState(() {
      postsNumber = posts.length;
      heightTabBarView = postsNumber * 400;
      isLoading = false;
    });
    print(
        'Index: ${_tabController.index} \t Post: ${posts.length} Height: $heightTabBarView');
    print('Profile Page Number: ${posts.length} \t Posts: $postsNumber');
  }

  // #Sign out
  void _logOut() async {
    var result = await Utils.dialog(
        context, 'Instagram', 'Confirm that you want to log out', false);
    if (result) {
      AuthenticationService.signOutUser(context);
      HiveService.removeUid();
      HiveService.removeFeed();
      HiveService.removePosts();
      HiveService.removeDeletedPosts();
    }
  }

  void _actionRemovePost(Post post) async {
    var result = await Utils.dialog(context, 'Instagram',
        'Are you sure you want to remove this post?', false);
    if (result) {
      setState(() {
        isLoading = true;
      });
      FirestoreService.removePost(post).then((value) => {_getPosts()});
    }
  }

  void _uploadHighlight(){

  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            setState(() {
              tabIndex = 0;
              heightTabBarView = posts.length * 400;
            });
            break;
          case 1:
            setState(() {
              tabIndex = 1;
              heightTabBarView = posts.length * 130;
            });
            break;
          case 2:
            setState(() {
              tabIndex = 2;
              heightTabBarView = posts.length * 60;
            });
            break;
        }
        print('Index: ${_tabController.index} \t Height: $heightTabBarView');
      }
    });
    _getUserFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            profileOwner.username.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              splashRadius: 1,
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logOut,
            ),
          ],
          elevation: 0.0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: isLoading
                ? LinearProgressIndicator(
                    color: ColorService.lightColor,
                    backgroundColor: ColorService.deepColor)
                : const SizedBox(),
          )),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // #statistics
            Container(
              height: 95,
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Container(
                      height: 95,
                      width: 95,
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: ColorService.lightColor, width: 2),
                          shape: BoxShape.circle),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: profileOwner.profileImageURL == null
                            ? Image.asset(
                                'assets/profile_pictures/user.png',
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: profileOwner.profileImageURL!,
                                placeholder: (context, url) => Image.asset(
                                    'assets/profile_pictures/user.png'),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                        'assets/profile_pictures/user.png'),
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    onLongPress: () {
                      _mediaSource(context);
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(postsNumber.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      const Text('Posts',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 16)),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profileOwner.followers.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      const Text('Followers',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 16)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(profileOwner.followings.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const Text('Following',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 16)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // #bio
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 14.0, 8.0, 14.0),
              child: RichText(
                text: TextSpan(
                    text: profileOwner.username,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19),
                    children: [
                      TextSpan(
                        text: '\n${profileOwner.email}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                            fontSize: 16),
                      ),
                    ]),
              ),
            ),
            // #buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MaterialButton(
                    height: 34,
                    minWidth: MediaQuery.of(context).size.width * 0.3,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Edit profile',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  MaterialButton(
                    height: 34,
                    minWidth: MediaQuery.of(context).size.width * 0.3,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Ad tools',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  MaterialButton(
                    height: 34,
                    minWidth: MediaQuery.of(context).size.width * 0.3,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Insights',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            // #posts
            Column(
              children: [
                TabBar(
                    controller: _tabController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    indicatorColor: Colors.black,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black,
                    tabs: tabs),
                posts.isNotEmpty
                    ? SizedBox(
                        height: heightTabBarView,
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _tabController,
                          children: [
                            SizedBox(
                              height: 400,
                              child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: posts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 1,
                                          mainAxisSpacing: 4.0,
                                          crossAxisSpacing: 4.0),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return myPost(posts[index]);
                                  }),
                            ),
                            SizedBox(
                              height: 110,
                              child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: posts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 4.0,
                                          crossAxisSpacing: 4.0),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return myPost(posts[index]);
                                  }),
                            ),
                            SizedBox(
                              height: 100,
                              child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: posts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 2 / 2,
                                          mainAxisSpacing: 4.0,
                                          crossAxisSpacing: 4.0),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return myPost(posts[index]);
                                  }),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 300,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Image.asset(
                            'assets/icons/not_found.png',
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }


  Widget myPost(Post post) {
    return GestureDetector(
      onLongPress: () {
        _actionRemovePost(post);
      },
      child: Card(
        elevation: 20.0,
        color: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: CachedNetworkImage(
            imageUrl: post.image,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            errorWidget: (context, url, error) =>
                Image.asset('assets/icons/not_found.png'),
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

}
