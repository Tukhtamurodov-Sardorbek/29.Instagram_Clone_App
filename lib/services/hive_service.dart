import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:instagramlesson/models/post_model.dart';

enum StorageKeys{
  UID,
  THEME,
  TOKEN,
  FEED,
  POST,
  DELETED
}

class HiveService {
  static String DB_NAME = 'database';
  static var box = Hive.box(DB_NAME);

  // #For theme
  static setTheme(String theme){
    box.put('theme', theme);
  }
  static getTheme(){
    String theme = box.get('theme', defaultValue: 'light');
    return theme;
  }

  // #For user id
  static void storeUID(String uid) async {
    await box.put('uid', uid);
  }
  static String getUID() {
    if(box.containsKey('uid')){
      String uid = box.get('uid');
      return uid;
    }
    return 'No data';
  }
  static Future<void> removeUid() async {
    await box.delete('uid');
  }

  // #For firebase token
  static void storeToken(String token) async {
    await box.put('Firebase_token', token);
  }
  static String getToken() {
    if(box.containsKey('Firebase_token')){
      String token = box.get('Firebase_token');
      return token;
    }
    return 'No data';
  }

  // #Store feed page posts
  static Future<void> storeFeed (List<Post> posts) async {
    // Object => Map => String
    List<String> stringPosts = posts.map((post) => jsonEncode(post.toJson())).toList();
    await box.put('feed', stringPosts);
  }
  static List<Post> loadFeed(){
    if(box.containsKey('feed')){
      // String => Map => Object
      List<String> stringPosts = box.get('feed');
      List<Post> posts = stringPosts.map((stringPost) => Post.fromJson(jsonDecode(stringPost))).toList();
      return posts;
    }
    return <Post>[];
  }
  static Future<void> removeFeed() async {
    await box.delete('feed');
  }

  // #Store feed page posts
  static Future<void> storePosts (List<Post> posts) async {
    // Object => Map => String
    List<String> stringPosts = posts.map((post) => jsonEncode(post.toJson())).toList();
    await box.put('posts', stringPosts);
  }
  static List<Post> loadPosts(){
    if(box.containsKey('posts')){
      // String => Map => Object
      List<String> stringPosts = box.get('posts');
      List<Post> posts = stringPosts.map((stringPost) => Post.fromJson(jsonDecode(stringPost))).toList();
      return posts;
    }
    return <Post>[];
  }
  static Future<void> removePosts() async {
    await box.delete('posts');
  }

  // #Store deleted posts
  static Future<void> storeDeletedPost (Post post) async {
    // Object => Map => String
    if(box.containsKey('DeletedPosts')){
      List<String> deletedPosts = box.get('DeletedPosts');
      String deleted = jsonEncode(post.toJson());
      deletedPosts.add(deleted);
      await box.put('DeletedPosts', deletedPosts);
    }else{
      List<String> deleted = [jsonEncode(post.toJson())];
      await box.put('DeletedPosts', deleted);
    }
  }
  static Future<void> storeDeletedPosts (List<Post> posts) async {
    // Object => Map => String
    List<String> stringPosts = posts.map((post) => jsonEncode(post.toJson())).toList();
    await box.put('DeletedPosts', stringPosts);
  }
  static List<Post> loadDeletedPosts(){
    if(box.containsKey('DeletedPosts')){
      // String => Map => Object
      List<String> stringPosts = box.get('DeletedPosts');
      List<Post> posts = stringPosts.map((stringPost) => Post.fromJson(jsonDecode(stringPost))).toList();
      return posts;
    }
    return <Post>[];
  }
  static Future<void> removeDeletedPosts() async {
    await box.delete('DeletedPosts');
  }

  // #Get key
  static String key(StorageKeys key){
    switch(key){
      case StorageKeys.UID: return 'uid';
      case StorageKeys.THEME: return 'theme';
      case StorageKeys.TOKEN: return 'Firebase_token';
      case StorageKeys.FEED: return 'feed';
      case StorageKeys.POST: return 'posts';
      case StorageKeys.DELETED: return 'DeletedPosts';
    }
  }
}
