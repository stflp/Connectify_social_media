import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../classes/user.dart';
import '../components/post_ui.dart';
import 'edit_profile_screen.dart';
import 'main_screen.dart';
import 'other_profile_screen.dart';
import 'user_list_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(),
                ),
              );
            },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
            child: Text('Edit'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(userData['profile_picture']),
                        ),
                      ),
                      Column(
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
                            ],
                          ),
                          SizedBox(height: 10),
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
                    ],
                  ),
                  SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Posts")
                        .where('userId', isEqualTo: user.uid)
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
                                  return Center(child: CircularProgressIndicator());
                                }

                                final user = UserClass.fromSnap(userSnapshot.data!);

                                return PostUi(
                                  text: post["text"],
                                  imageUrl: post["imageUrl"],
                                  username: user.username,
                                  userImageUrl: user.profile_picture,
                                  likes: postLikes.length,
                                  onTap: () {
                                    if (currentUser.uid == postUserId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(),
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
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}