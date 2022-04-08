import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/models/post_model.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/pages/insta_user_page.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/notification_http_service.dart';
import 'package:instagramlesson/services/utils_service.dart';
import 'package:instagramlesson/widgets/appBar.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FeedPage extends StatefulWidget {
  static const String id = '/feed_page';
  PageController controller;
  FeedPage({Key? key, required this.controller}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool isLoading = false;
  bool isSharing = false;
  List<Post> posts = [];

  void _requestForFeed() {
    setState(() {
      isLoading = true;
    });
    FirestoreService.loadFeeds().then((value) => {_getPosts(value)});
  }

  void _getPosts(List<Post> _posts) {
    if (_posts.isEmpty) {
      setState(() {
        posts = HiveService.loadFeed();
      });
    } else {
      setState(() {
        posts = _posts;
      });
      HiveService.storeFeed(posts);
    }
    print('Number: ${posts.length} \t Posts: $posts');

    setState(() {
      isLoading = false;
    });
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

  void _actionRemovePost(Post post) async {
    var result = await Utils.dialog(context, 'Instagram',
        'Are you sure you want to remove this post?', false);
    if (result) {
      setState(() {
        isLoading = true;
      });
      FirestoreService.removePost(post).then((value) => {_requestForFeed()});
    }
  }

  void _apiUnfollowUser(String uid) async {
    setState(() {
      isLoading = true;
    });

    await FirestoreService.unfollowViaPost(uid).then((someone) {
      unfollowing(someone);
    });
  }

  void unfollowing(UserModel? someone) async {
    if (someone != null) {
      setState(() {
        someone.isFollowed = false;
        isLoading = false;
      });
      await FirestoreService.removePostsFromMyFeed(someone);
      _requestForFeed();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _bottomSheet(Post post, context) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topRight: Radius.circular(50),
          topLeft: Radius.circular(50),
        )),
        elevation: 6.0,
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 110,
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/icons/link.png'),
                      Image.asset('assets/icons/share.png'),
                      Image.asset('assets/icons/report.png'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 2),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GestureDetector(
                    child: const Text('Hide',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () {
                      // posts.remove(post);
                      // setState(() {});
                      _actionRemovePost(post);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                post.uid != HiveService.getUID()
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GestureDetector(
                          child: const Text('Unfollow',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          onTap: () {
                            if (post.uid != HiveService.getUID()) {
                              _apiUnfollowUser(post.uid!);
                              setState(() {});
                            }
                          },
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          );
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestForFeed();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Column(
            children: [
              appBar(
                  text: 'Instagram',
                  isCentered: false,
                  leading: Icon(Icons.camera_alt,
                      size: 28, color: ColorService.lightColor),
                  action: Image.asset('assets/icons/send.png',
                      height: 26, width: 26, color: ColorService.lightColor),
                  onPressedLeading: () {
                    widget.controller.jumpToPage(2);
                  },
                  onPressedAction: () {},
                  isLoading: isLoading),
              isLoading
                  ? LinearProgressIndicator(
                      color: ColorService.lightColor,
                      backgroundColor: ColorService.deepColor)
                  : const SizedBox(),
            ],
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(color: ColorService.lightColor, thickness: 2);
                },
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                        onTap: () {
                          if (!posts[index].isMine) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        UserProfilePage(
                                            uid: posts[index].uid!)));
                          }
                        },
                        // tileColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: posts[index].profileImage == null
                              ? Image.asset(
                                  'assets/profile_pictures/user.png',
                                  height: 45,
                                  width: 45,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: posts[index].profileImage!,
                                  placeholder: (context, url) => Image.asset(
                                      'assets/profile_pictures/user.png'),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                          'assets/profile_pictures/user.png'),
                                  height: 45,
                                  width: 45,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        title: Text(posts[index].username ?? 'User',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text(posts[index].date ?? ''),
                        trailing: IconButton(
                          splashRadius: 1,
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _bottomSheet(posts[index], context);
                          },
                        ),
                      ),
                      // #image
                      GestureDetector(
                        child: CachedNetworkImage(
                          imageUrl: posts[index].image,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator.adaptive()),
                          errorWidget: (context, url, error) =>
                              Image.asset('assets/icons/not_found.png'),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover,
                        ),
                        onDoubleTap: (){
                          if (!posts[index].isLiked) {
                            _apiPostLike(posts[index]);
                          } else {
                            _apiPostUnlike(posts[index]);
                          }
                        },
                      ),

                      // #likeshare
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              splashRadius: 1,
                              icon: Icon(
                                  posts[index].isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: posts[index].isLiked
                                      ? Colors.red
                                      : Colors.black,
                                  size: 30),
                              onPressed: () {
                                if (!posts[index].isLiked) {
                                  _apiPostLike(posts[index]);
                                } else {
                                  _apiPostUnlike(posts[index]);
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
                                _shareFile(posts[index]);
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
                      ),

                      // #caption
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 10),
                        child: Text(
                          posts[index].caption,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    ],
                  );
                },
              )
            ],
          ),
        ));
  }
}
