import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/comments_screen.dart';
import '../screens/user_list_screen.dart';
import 'helper_functions.dart';

class PostUi extends StatefulWidget {
  final String? text;
  final String? imageUrl;
  final String username;
  final String userImageUrl;
  final int likes;
  final Function onTap;
  final String postId;
  final String currentUserId;
  final List<dynamic> postLikes;
  final String postOwnerId;

  const PostUi({
    super.key,
    required this.text,
    required this.imageUrl,
    required this.username,
    required this.userImageUrl,
    required this.likes,
    required this.onTap,
    required this.postId,
    required this.currentUserId,
    required this.postLikes,
    required this.postOwnerId,
  });

  @override
  State<PostUi> createState() => _PostUiState();
}

class _PostUiState extends State<PostUi> {
  int commentsLength = 0;

  @override
  void initState() {
    super.initState();
    getComments();
  }

  void getComments() async {
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .collection('Comments')
        .get();
    if (mounted) {
    setState(() {
      commentsLength = snap.docs.length;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final StorageMethods storageMethods = StorageMethods();

    Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await storageMethods.deletePost(widget.postId);
    }
  }

    final likesUserIds = widget.postLikes.map((userId) => userId.toString()).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              widget.onTap();
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(widget.userImageUrl),
              radius: 25,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    widget.onTap();
                  },
                  child: Text(
                    widget.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Post text
                if (widget.text != null && widget.text!.isNotEmpty)
                  Text(
                    widget.text!,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                if (widget.text != null && widget.text!.isNotEmpty)
                  const SizedBox(height: 5),
                // Post image
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 10),
                // Like, comment, and delete buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.postLikes.contains(widget.currentUserId) ? Icons.favorite : Icons.favorite_border,
                        color: widget.postLikes.contains(widget.currentUserId) ? Colors.red : Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () async {
                        await storageMethods.likePost(widget.postId, widget.currentUserId, widget.postLikes);
                      },
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserListScreen(
                                title: 'Likes',
                                userIds: likesUserIds,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '${widget.likes}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              postId: widget.postId,
                              postOwnerId: widget.postOwnerId,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      '$commentsLength',
                      style: TextStyle(fontSize: 16),
                    ),
                    Spacer(),
                    if (widget.postOwnerId == widget.currentUserId)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: ()  {
                          _confirmDelete(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
