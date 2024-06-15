import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../classes/user.dart';
import '../components/helper_functions.dart';
import '../components/post_ui.dart';
import 'other_profile_screen.dart';
import 'profile_screen.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId;

  const CommentsScreen({
    Key? key,
    required this.postId,
    required this.postOwnerId,
  }) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageMethods().deleteComment(widget.postId, commentId);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posts')
                        .doc(widget.postId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var post = snapshot.data!.data() as Map<String, dynamic>;
                      var postUserId = post['userId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(postUserId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          var user = UserClass.fromSnap(userSnapshot.data!);
                          var postLikes = List<String>.from(post['likes'] ?? []);

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
                            postId: widget.postId,
                            currentUserId: currentUser!.uid,
                            postLikes: postLikes,
                            postOwnerId: widget.postOwnerId,
                          );
                        },
                      );
                    },
                  ),
                  Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posts')
                        .doc(widget.postId)
                        .collection('Comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var comments = snapshot.data!.docs;

                      comments.sort((a, b) {
                        var aLikes = List<String>.from(a['likes'] ?? []).length;
                        var bLikes = List<String>.from(b['likes'] ?? []).length;
                        return bLikes.compareTo(aLikes);
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var comment = comments[index].data() as Map<String, dynamic>;
                          var commentUserId = comment['userId'];
                          var commentId = comments[index].id;
                          var commentLikes = List<String>.from(comment['likes'] ?? []);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Users')
                                .doc(commentUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }

                              var user = UserClass.fromSnap(userSnapshot.data!);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(user.profile_picture),
                                ),
                                title: Text(user.username),
                                subtitle: Text(comment['text']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        commentLikes.contains(currentUser!.uid)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      onPressed: () async {
                                        await StorageMethods().likeComment(
                                          widget.postId,
                                          commentId,
                                          currentUser!.uid,
                                          commentLikes,
                                        );
                                      },
                                    ),
                                    Text('${commentLikes.length}'),
                                    if (commentUserId == currentUser!.uid || widget.postOwnerId == currentUser!.uid)
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () => _confirmDeleteComment(commentId),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_commentController.text.trim().isNotEmpty) {
                      await StorageMethods().addComment(
                        widget.postId,
                        currentUser!.uid,
                        _commentController.text.trim(),
                      );
                      _commentController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}