class Post{
  String? uid;
  String? id;
  String? username;
  String? profileImage;
  String? date;
  String image;
  String caption;
  bool isLiked = false;

  bool isMine = false;

  Post({
    required this.image,
    required this.caption,
    this.uid,
    this.id,
    this.username,
    this.profileImage,
    this.date
  });

  Post.fromJson(Map<String, dynamic> json)
      : uid = json["uid"],
        id = json["id"],
        username = json["username"],
        profileImage = json["profileImage"],
        date = json["date"],
        image = json['postImage'],
        caption = json['postCaption'],
        isLiked = json["liked"];

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "id": id,
    "username": username,
    "profileImage": profileImage,
    'date' : date,
    'postImage' : image,
    'postCaption' : caption,
    "liked": isLiked
  };
}