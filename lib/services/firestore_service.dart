import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagramlesson/models/post_model.dart';
import 'package:instagramlesson/models/user_model.dart';
import 'package:instagramlesson/services/hive_service.dart';
import 'package:instagramlesson/services/utils_service.dart';

class FirestoreService {
  static final _FireStore = FirebaseFirestore.instance;

  // #Folders
  static String usersFolder = "users";
  static String postsFolder = "posts";
  static String feedsFolder = "feeds";
  static String followersFolder = "followers";
  static String followingsFolder = "followings";

  // #store account
  static Future storeUser(UserModel user) async {
    user.uid = HiveService.getUID();
    Map<String, String> params = await Utils.deviceParams();

    user.deviceId = params['device_id']!;
    user.deviceType = params['device_type']!;
    user.deviceToken = params['device_token']!;

    return await _FireStore.collection (usersFolder).doc(user.uid).set(user.toJson());
  }
  // #get account data
  static Future<UserModel> loadUser(String? uid) async {
    uid ??= HiveService.getUID();
    var value = await _FireStore.collection(usersFolder).doc(uid).get();
    UserModel user = UserModel.fromJson(value.data()!);

    // #Get followers number
    var querySnapshot1 = await _FireStore.collection(usersFolder).doc(uid).collection(followersFolder).get();
    user.followers = querySnapshot1.docs.length;

    // #Get following users number
    var querySnapshot2 = await _FireStore.collection(usersFolder).doc(uid).collection(followingsFolder).get();
    user.followings = querySnapshot2.docs.length;

    return user;
  }
  // #update account data
  static Future updateUser(UserModel user) async {
    String uid = HiveService.getUID();
    // #Get all my posts from postsFolder
    var myPosts = await _FireStore.collection(usersFolder).doc(user.uid).collection(postsFolder).get();
    // #Get all my followers
    var myFollowers = await _FireStore.collection(usersFolder).doc(user.uid).collection(followersFolder).get();
    // #Get all my followings
    var myFollowings = await _FireStore.collection(usersFolder).doc(user.uid).collection(followingsFolder).get();


    for (var result in myPosts.docs) {
      // #Update my each post
      Post post = Post.fromJson(result.data());
      post.uid = user.uid;
      post.username = user.username;
      post.profileImage = user.profileImageURL;

      // #Update my each post in my posts & feeds folder
      await _FireStore.collection(usersFolder).doc(user.uid).collection(postsFolder).doc(post.id).update(post.toJson());
      await _FireStore.collection(usersFolder).doc(user.uid).collection(feedsFolder).doc(post.id).update(post.toJson());

      // #Update my post in all my followers feeds
      for (var element in myFollowers.docs) {
        UserModel follower = UserModel.fromJson(element.data());
        await _FireStore.collection(usersFolder).doc(follower.uid).collection(feedsFolder).doc(post.id).update(post.toJson());
      }
      // #Update my post in all my followings feeds
      for (var element in myFollowings.docs) {
        UserModel following = UserModel.fromJson(element.data());
        await _FireStore.collection(usersFolder).doc(following.uid).collection(feedsFolder).doc(post.id).update(post.toJson());
      }
    }
    return _FireStore.collection(usersFolder).doc(uid).update(user.toJson());
  }

  // #search
  static Future<List<UserModel>> searchUsers(String keyword) async {
    List<UserModel> searchResults = [];
    List<UserModel> followingUsers = [];
    // #In order not to show the user's account in search
    String uid = HiveService.getUID();
    // #Get search result
    var querySnapshot1 = await _FireStore.collection(usersFolder).orderBy('username').startAt([keyword]).endAt([keyword + '\uf8ff']).get();
    for (var result in querySnapshot1.docs) {
      UserModel user = UserModel.fromJson(result.data());
      if (user.uid != uid) {
        searchResults.add(user);
      }
    }
    // #Get list of all followed users
    var querySnapshot2 = await _FireStore.collection(usersFolder).doc(uid).collection(followingsFolder).get();
    for (var result in querySnapshot2.docs) {
      UserModel followingUser = UserModel.fromJson(result.data());
      followingUsers.add(followingUser);
    }
    // #Clarify if is followed by user
    for (UserModel user in searchResults) {
      if (followingUsers.contains(user)) {
        user.isFollowed = true;
      } else {
        user.isFollowed = false;
      }
    }
    return searchResults;
  }


  // #store post in postsFolder
  static Future<Post> storePost(Post post) async {
    UserModel myAccount = await loadUser(null);
    post.uid = myAccount.uid;
    post.username = myAccount.username;
    post.profileImage = myAccount.profileImageURL;
    post.date = DateTime.now().toString().substring(0, 16);

    String postId = _FireStore.collection(usersFolder).doc(myAccount.uid).collection(postsFolder).doc().id;
    post.id = postId;
    // #Store new post to my postsFeed
    await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(postsFolder).doc(postId).set(post.toJson());
    // #Get all my followers
    var myFollowers = await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followersFolder).get();
    // #Get all my followings
    var myFollowings = await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followingsFolder).get();

    // #Update my post in all my followers feeds
    for (var element in myFollowers.docs) {
      UserModel follower = UserModel.fromJson(element.data());
      await _FireStore.collection(usersFolder).doc(follower.uid).collection(feedsFolder).doc(post.id).set(post.toJson());
    }
    // #Update my post in all my followings feeds
    for (var element in myFollowings.docs) {
      UserModel following = UserModel.fromJson(element.data());
      await _FireStore.collection(usersFolder).doc(following.uid).collection(feedsFolder).doc(post.id).set(post.toJson());
    }

    return post;
  }
  // #store the post in feedsFolder
  static Future<Post> storeFeed(Post post) async {
    String uid = HiveService.getUID();
    await _FireStore.collection(usersFolder).doc(uid).collection(feedsFolder).doc(post.id).set(post.toJson());
    return post;
  }
  // #load posts in FeedPage
  static Future<List<Post>> loadFeeds() async {
    List<Post> posts = [];
    String uid = HiveService.getUID();
    var querySnapshot = await _FireStore.collection(usersFolder).doc(uid).collection(feedsFolder).orderBy("date", descending: true).get();
    for (var element in querySnapshot.docs) {
      Post post = Post.fromJson(element.data());
      if (post.uid == uid) post.isMine = true;
      posts.add(post);
    }
    return posts;
  }
  // #load posts
  static Future<List<Post>> loadPosts(String? uid) async {
    List<Post> posts = [];
    uid ??= HiveService.getUID();
    var querySnapshot = await _FireStore.collection(usersFolder).doc(uid).collection(postsFolder).get();
    for (var element in querySnapshot.docs) {
      Post post = Post.fromJson(element.data());
      posts.add(post);
    }
    return posts;
  }

  // #likePost
  static Future<Post> likePost(Post post, bool isLiked) async {
    String uid = HiveService.getUID();
    post.isLiked = isLiked;
    await _FireStore.collection(usersFolder).doc(uid).collection(feedsFolder).doc(post.id).set(post.toJson());
    if (uid == post.uid) {
      await _FireStore.collection(usersFolder).doc(uid).collection(postsFolder).doc(post.id).set(post.toJson());
    }
    return post;
  }
  // #get all liked posts
  static Future<List<Post>> loadLikes() async {
    String uid = HiveService.getUID();
    List<Post> posts = [];
    // #get all liked posts
    var querySnapshot = await _FireStore.collection(usersFolder).doc(uid).collection(feedsFolder).where("liked", isEqualTo: true).get();
    for (var element in querySnapshot.docs) {
      Post post = Post.fromJson(element.data());
      if (uid == post.uid) post.isMine = true;
      posts.add(post);
    }
    return posts;
  }


  // #When I follow someone
  static Future<UserModel> followUser(UserModel someone) async {
    UserModel myAccount = await loadUser(null);

    // #Add someone to my followings
    await _FireStore.collection(usersFolder).doc(myAccount.uid)
        .collection(followingsFolder).doc(someone.uid).set(someone.toJson());

    // #Add my account to someone's followers
    await _FireStore.collection(usersFolder).doc(someone.uid)
        .collection(followersFolder).doc(myAccount.uid).set(myAccount.toJson());

    return someone;
  }
  // #When I unfollow someone
  static Future<UserModel> unfollowUser(UserModel someone) async {
    UserModel myAccount = await loadUser(null);

    // #Delete someone from my followings
    await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followingsFolder).doc(someone.uid).delete();

    // #Delete my account from someone's followers
    await _FireStore.collection(usersFolder).doc(someone.uid).collection(followersFolder).doc(myAccount.uid).delete();

    return someone;
  }
  // #When I unfollow someone
  static Future<UserModel?> unfollowViaPost(String uid) async{
    UserModel myAccount = await loadUser(null);
    UserModel someone = UserModel(password: '', username: '', email: '');

    var myFollowings = await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followingsFolder).get();
    for (var follower in myFollowings.docs) {
      UserModel myFollowing = UserModel.fromJson(follower.data());
      if(myFollowing.uid == uid){
        someone = myFollowing;
      }
    }

    if(someone.password.isNotEmpty && someone.username.isNotEmpty && someone.email.isNotEmpty){
      // #Delete someone from my followings
      await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followingsFolder).doc(someone.uid).delete();

      // #Delete my account from someone's followers
      await _FireStore.collection(usersFolder).doc(someone.uid).collection(followersFolder).doc(myAccount.uid).delete();

      return someone;
    }
    return null;
  }

  // #Update me in followers feeds
  static Future updateMyPostsInFollowersFeed(UserModel myAccount) async {
    // Store someone's posts to my feed
    List<String> myFollowerIds = [];
    // #Get all my followers
    var myFollowers = await _FireStore.collection(usersFolder).doc(myAccount.uid).collection(followersFolder).get();

    for (var follower in myFollowers.docs) {
      UserModel myFollower = UserModel.fromJson(follower.data());
      myFollowerIds.add(myFollower.uid!);
    }

    for (String myFollowerId in myFollowerIds) {
      var querySnapshot = await _FireStore
          .collection(usersFolder)
          .doc(myFollowerId)
          .collection(feedsFolder)
          .where("uid", isEqualTo: myAccount.uid)
          .get();

      for (var element in querySnapshot.docs) {
        Post post = Post.fromJson(element.data());
        post.profileImage = myAccount.profileImageURL;
        post.username = myAccount.username;
        await _FireStore
            .collection(usersFolder)
            .doc(myFollowerId)
            .collection(feedsFolder)
            .doc(post.id)
            .update(post.toJson());
      }
    }
  }
  // #Store my others posts in my feed
  static Future storePostsInMyFeed(UserModel someone) async {
    // Store someone's posts in my feed
    List<Post> posts = [];
    var querySnapshot = await _FireStore.collection(usersFolder).doc(someone.uid).collection(postsFolder).get();
    for (var element in querySnapshot.docs) {
      Post post = Post.fromJson(element.data());
      post.isLiked = false;
      posts.add(post);
    }
    for (Post post in posts) {
      storeFeed(post);
    }
  }
  // #Remove posts from my feed
  static Future removePostsFromMyFeed(UserModel someone) async {
    // Remove someone's posts from my feed
    List<Post> posts = [];
    var querySnapshot = await _FireStore.collection(usersFolder).doc(someone.uid).collection(postsFolder).get();
    for (var element in querySnapshot.docs) {
      Post post = Post.fromJson(element.data());
      posts.add(post);
    }
    for (Post post in posts) {
      removeFeed(post);
    }
  }
  // #Delete the post from my feedsFolder
  static Future removeFeed(Post post) async {
    String uid = HiveService.getUID();
    return await _FireStore.collection(usersFolder).doc(uid).collection(feedsFolder).doc(post.id).delete();
  }
  // #Delete my post
  static Future removePost(Post post) async {
    String uid = HiveService.getUID();
    List<String> userIds = [];

    // #Delete the post from my feedsFolder
    await removeFeed(post);
    await _FireStore.collection(usersFolder).doc(uid).collection(postsFolder).doc(post.id).delete();
    // #Get all my followers
    var querySnapshot = await _FireStore.collection(usersFolder).doc(uid).collection(followersFolder).get();
    // #Get all my followers ids
    for (var element in querySnapshot.docs) {
      UserModel follower = UserModel.fromJson(element.data());
      userIds.add(follower.uid!);
    }
    // #Delete the post from the rest users feedsFolder
    for (String follower in userIds) {
      await _FireStore.collection(usersFolder).doc(follower).collection(feedsFolder).doc(post.id).delete();
    }
  }
}
