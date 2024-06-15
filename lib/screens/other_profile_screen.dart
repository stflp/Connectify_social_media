import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/components/helper_functions.dart';
import '../classes/user.dart';
import '../components/post_ui.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'user_list_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  OtherProfileScreen({required this.userId});

  @override
  _OtherProfileScreenState createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("Users").doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection("Users").doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final currentUser = snapshot.data!.data() as Map<String, dynamic>;
                      final currentUserId = snapshot.data!.id;

                      isFollowing = currentUser['following'].contains(widget.userId);

                      if (currentUserId == widget.userId) {
                        return Container();
                      }

                      return Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: TextButton(
                          onPressed: () {
                            StorageMethods().followUser(currentUserId, widget.userId);
                          },
                          child: Text(
                            isFollowing ? 'Unfollow' : 'Follow',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                );
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(userData['profile_picture']),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userData['username'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.messenger_outline_rounded),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          receiverId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Text(
                              userData['bio'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserListScreen(
                                        title: userData['username'] + "'s Following",
                                        userIds: List<String>.from(userData['following'] ?? []),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Following: ' + userData['following'].length.toString(),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserListScreen(
                                        title: userData['username'] + "'s Followers",
                                        userIds: List<String>.from(userData['followers'] ?? []),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Followers: ' + userData['followers'].length.toString(),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Posts")
                        .where('userId', isEqualTo: widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final posts = snapshot.data!.docs;
                        posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final postUserId = post['userId'];
                            final postLikes = List<String>.from(post['likes'] ?? []);
                            final currentUser = FirebaseAuth.instance.currentUser;

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('Users').doc(postUserId).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final user = UserClass.fromSnap(userSnapshot.data!);

                                return PostUi(
                                  text: post["text"],
                                  imageUrl: post["imageUrl"],
                                  username: user.username,
                                  userImageUrl: user.profile_picture,
                                  likes: postLikes.length,
                                  onTap: () {
                                    if (currentUser?.uid == postUserId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProfilePage(),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OtherProfileScreen(
                                            userId: postUserId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  postId: post.id,
                                  currentUserId: currentUser!.uid,
                                  postLikes: postLikes,
                                  postOwnerId: postUserId,
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
