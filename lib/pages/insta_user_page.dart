import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:instagramlesson/models/post_model.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/notification_http_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UserProfilePage extends StatefulWidget {
  String uid;
  UserProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isLoading = false;
  UserModel profileOwner = UserModel(password: '', username: '', email: '');
  int axisCount = 1;
  int postsNumber = 0;
  List<Post> posts = [];
  PageController pageController = PageController();
  int currentPage = 0;

  void _apiLoadUser() {
    setState(() {
      isLoading = true;
    });
    FirestoreService.loadUser(widget.uid)
        .then((value) => {_resLoadUser(value)});
  }

  void _resLoadUser(UserModel userModel) {
    setState(() {
      profileOwner = userModel;
      _apiLoadPost();
    });
  }

  void _apiLoadPost() {
    setState(() {
      isLoading = true;
    });
    FirestoreService.loadPosts(profileOwner.uid)
        .then((value) => {_resLoadPosts(value)});
  }

  void _resLoadPosts(List<Post> _posts) {
    setState(() {
      postsNumber = _posts.length;
      posts = _posts;
      isLoading = false;
    });
    _loadLikes(posts);
  }


  void _apiPostLike(Post post) async {
    setState(() {
      isLoading = true;
    });
    await FirestoreService.likePost(post, true);
    setState(() {
      post.isLiked = true;
      isLoading = false;
    });
    UserModel myAccount = await FirestoreService.loadUser(null);
    UserModel someone = await FirestoreService.loadUser(post.uid);
    await HttpService.POST(HttpService.bodyLike(someone.deviceToken, myAccount.username)).then((value) {
      if (kDebugMode) {
        print(value);
      }
    });
  }

  void _apiPostUnlike(Post post) async {
    setState(() {
      isLoading = true;
    });
    await FirestoreService.likePost(post, false);
    setState(() {
      post.isLiked = false;
      isLoading = false;
    });
  }

  void _shareFile(Post post) async {
    setState(() {
      isLoading = true;
    });
    final box = context.findRenderObject() as RenderBox?;
    if (Platform.isAndroid || Platform.isIOS) {
      var response = await get(Uri.parse(post.image));
      final documentDirectory = (await getExternalStorageDirectory())?.path;
      File imgFile = File('$documentDirectory/flutter.png');
      imgFile.writeAsBytesSync(response.bodyBytes);
      Share.shareFiles([File('$documentDirectory/flutter.png').path],
          subject: 'Instagram',
          text: post.caption,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    } else {
      Share.share('Hello, check your share files!',
          subject: 'URL File Share',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    }
    setState(() {
      isLoading = false;
    });
  }

  _loadLikes(List<Post> allPosts) async {
    String uid = HiveService.getUID();
    // #get all liked posts
    var querySnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('feeds').where("liked", isEqualTo: true).get();
    for (var element in querySnapshot.docs) {
      Post likedPost = Post.fromJson(element.data());
      for(var post in allPosts){
        if(post.id == likedPost.id){
          setState(() {
            post.isLiked = true;
            // allPosts[allPosts.indexOf(post)].isLiked = true;
          });
        }
      }
    }
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _apiLoadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Profile',
              style: TextStyle(fontSize: 30, fontFamily: 'instagramFont')),
          centerTitle: true,
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
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
                    // #User's profile image
                    Container(
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
                    // #Posts number
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
                    // #Followers number
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
                    // #Followings number
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
                          color:
                              Theme.of(context).brightness == Brightness.light
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              // #gridselect
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: IconButton(
                      onPressed: () {
                        setState(() {
                          axisCount = 1;
                        });
                      },
                      icon: const Icon(
                        Icons.list_alt,
                        size: 27,
                      ),
                    ))),
                    Expanded(
                        child: Center(
                            child: IconButton(
                      onPressed: () {
                        setState(() {
                          axisCount = 2;
                        });
                      },
                      icon: const Icon(
                        Icons.grid_view,
                        size: 27,
                      ),
                    ))),
                  ],
                ),
              ),
              Expanded(
                  child: GridView.builder(
                      itemCount: posts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: axisCount,
                      ),
                      itemBuilder: (context, index) {
                        return _itemOfPost(posts[index]);
                      }))
            ],
          ),
        ));
  }

  Widget _itemOfPost(Post post) {
    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.all(5),
          child: CachedNetworkImage(
            imageUrl: post.image,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: axisCount == 1 ? 320 : 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        axisCount == 1 ?
        // #likeshare
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                splashRadius: 1,
                icon: Icon(
                    post.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.isLiked
                        ? Colors.red
                        : Colors.black,
                    size: 30),
                onPressed: () {
                  if (!post.isLiked) {
                    _apiPostLike(post);
                  } else {
                    _apiPostUnlike(post);
                  }
                },
              ),
              GestureDetector(
                child: Image.asset(
                  'assets/icons/comment.png',
                  height: 28,
                  width: 28,
                ),
                onTap: () {},
              ),
              const SizedBox(width: 8.0),
              IconButton(
                splashRadius: 1,
                padding: const EdgeInsets.fromLTRB(
                    0.0, 0.0, 16.0, 0.0),
                icon: const Icon(Icons.share,
                    color: Colors.black, size: 28),
                onPressed: () {
                  _shareFile(post);
                },
              ),
            ],
          ),
          trailing: GestureDetector(
            child: Image.asset(
              'assets/icons/save_outline.png',
              height: 28,
              width: 28,
            ),
            onTap: () {},
          ),
        ) : const SizedBox()
      ],
    );
  }
}
