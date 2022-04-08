import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/pages/insta_user_page.dart';
import 'package:instagramlesson/services/colors_service.dart';
import 'package:instagramlesson/services/firestore_service.dart';
import 'package:instagramlesson/services/notification_http_service.dart';
import 'package:instagramlesson/widgets/appBar.dart';

class SearchPage extends StatefulWidget {
  static const String id = '/search_page';
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _clearSearch = false;
  bool isLoading = false;
  bool isPressed = false;
  List<UserModel> users = [];

  void _searchUserFromFirestore(String keyword) {
    setState(() {
      isLoading = true;
    });
    FirestoreService.searchUsers(keyword)
        .then((value) => {_respSearchUsers(value)});
  }

  void _respSearchUsers(List<UserModel> _users) {
    setState(() {
      users = _users;
      isLoading = false;
    });
  }

  void _apiFollowUser(UserModel someone) async {
    setState(() {
      isLoading = true;
    });
    await FirestoreService.followUser(someone);
    setState(() {
      someone.isFollowed = true;
      isLoading = false;
    });

    UserModel myAccount = await FirestoreService.loadUser(null);
    await HttpService.POST(HttpService.bodyFollow(someone.deviceToken, myAccount.username)).then((value) {
      if (kDebugMode) {
        print(value);
      }
    });
    await FirestoreService.storePostsInMyFeed(someone);

    setState(() {
      isPressed = false;
    });
  }

  void _apiUnfollowUser(UserModel someone) async {
    setState(() {
      isLoading = true;
    });
    await FirestoreService.unfollowUser(someone);
    setState(() {
      someone.isFollowed = false;
      isLoading = false;
    });
    await FirestoreService.removePostsFromMyFeed(someone);

    setState(() {
      isPressed = false;
    });
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _searchUserFromFirestore('');
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
              child: Column(
                children: [
                  appBar(text: 'Search', isCentered: true),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black87, fontSize: 18),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    cursorColor: ColorService.lightColor,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white54,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 0.0),
                      hintText: 'Search',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 20),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffix: _clearSearch
                          ? GestureDetector(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(CupertinoIcons.clear,
                                    color: ColorService.lightColor, size: 20),
                              ),
                              onTap: () {
                                _searchFocus.unfocus();
                                setState(() {
                                  _clearSearch = false;
                                  _searchController.text = '';
                                  // _searchController.clear();
                                });
                              },
                            )
                          : const SizedBox(),
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        borderSide: BorderSide(
                            color: ColorService.lightColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        borderSide: BorderSide(
                            color: ColorService.lightColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        borderSide: BorderSide(color: ColorService.lightColor),
                      ),
                    ),
                    onChanged: (search) {
                      _searchController.text.isEmpty
                          ? _searchFocus.unfocus()
                          : null;
                      setState(() {
                        _clearSearch = _searchController.text.isNotEmpty;
                      });
                      _searchUserFromFirestore(search);
                    },
                    onSubmitted: (search) {
                      _searchFocus.unfocus();
                    },
                  ),
                  const SizedBox(height: 4.0),
                  isPressed ? LinearProgressIndicator(
                      color: ColorService.lightColor,
                      backgroundColor: ColorService.deepColor) : const SizedBox()
                ],
              ),
            ),
          ),
          body: users.isEmpty && _searchController.text.isNotEmpty
              ? SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/user.png',
                          height: 140,
                          width: 140,
                          fit: BoxFit.cover,
                          color: ColorService.deepColor),
                      const SizedBox(height: 20),
                      Text(
                        'User not found',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorService.deepColor),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (BuildContext context, int index) {
                          return const SizedBox(height: 2.0);
                        },
                        itemBuilder: (BuildContext context, int index) {
                          return userWidget(users[index]);
                        },
                      )
                    ],
                  ),
                )),
    );
  }

  ListTile userWidget(UserModel user) {
    return ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      UserProfilePage(uid: user.uid!)));
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: user.profileImageURL == null
              ? Image.asset(
                  'assets/profile_pictures/user.png',
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: user.profileImageURL!,
                  placeholder: (context, url) =>
                      Image.asset('assets/profile_pictures/user.png'),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/profile_pictures/user.png'),
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(user.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        trailing: MaterialButton(
          minWidth: 90,
          elevation: 3.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                  color:
                      user.isFollowed ? Colors.white : ColorService.lightColor,
                  width: 2)),
          color: user.isFollowed ? ColorService.lightColor : Colors.white,
          child: user.isFollowed
              ? const Text('Unfollow',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white))
              : Text('Follow',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: ColorService.lightColor)),
          onPressed: () {
            setState(() {
              isPressed = true;
            });
            print('isPressed: $isPressed \t isFollowed: ${user.isFollowed}');
            if (user.isFollowed) {
              _apiUnfollowUser(user);
            } else {
              _apiFollowUser(user);
            }
            print('isPressed: $isPressed \t isFollowed: ${user.isFollowed}');
          },
        ));
  }
}
