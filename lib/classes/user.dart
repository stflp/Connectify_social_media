import 'package:cloud_firestore/cloud_firestore.dart';

class UserClass {
  final String email;
  //final String uid;
  final String profile_picture;
  final String username;
  final String bio;
  final List followers;
  final List following;

  const UserClass(
      {required this.username,
      required this.profile_picture,
      required this.email,
      required this.bio,
      required this.followers,
      required this.following});

  static UserClass fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return UserClass(
      username: snapshot["username"],
      email: snapshot["email"],
      profile_picture: snapshot["profile_picture"],
      bio: snapshot["bio"],
      followers: snapshot["followers"],
      following: snapshot["following"],
    );
  }

  Map<String, dynamic> toJson() => {
        "username": username,
        "email": email,
        "profile_picture": profile_picture,
        "bio": bio,
        "followers": followers,
        "following": following,
      };
}