import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/components/post_ui.dart';
import 'package:social_media_app/screens/other_profile_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import '../classes/user.dart';
import '../components/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
        leading: GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image(
              image: AssetImage(
                isDarkMode ? 'images/clogo_white.png' : 'images/clogo_black.png',
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
  child: Column(
    children: [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Posts")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data!.docs[index];
                  final userId = post['userId'];
                  final currentUser = FirebaseAuth.instance.currentUser;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final user = UserClass.fromSnap(userSnapshot.data!);
                      final postLikes = List<String>.from(post['likes'] ?? []);

                      return PostUi(
                        text: post["text"],
                        imageUrl: post["imageUrl"],
                        username: user.username,
                        userImageUrl: user.profile_picture,
                        likes: postLikes.length,
                        onTap: () {
                          if (currentUser?.email == user.email) {
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
                                  userId: userId,
                                ),
                              ),
                            );
                          }
                        },
                        postId: post.id,
                        currentUserId: currentUser!.uid,
                        postLikes: postLikes,
                        postOwnerId: userId,
                      );
                    },
                  );
                },
              ),
            );
          }
        },
      ),
    ],
  ),
),
    );
  }
}