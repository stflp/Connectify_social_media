import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'other_profile_screen.dart';

class UserListScreen extends StatefulWidget {
  final String title;
  final List<String> userIds;

  const UserListScreen({
    Key? key,
    required this.title,
    required this.userIds,
  }) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0
      ),
      body: ListView.builder(
        itemCount: widget.userIds.length,
        itemBuilder: (context, index) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Users')
                .doc(widget.userIds[index])
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var user = snapshot.data!.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['profile_picture']),
                ),
                title: Text(user['username']),
                onTap: () {
                  // Navigate to the user's profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherProfileScreen(
                        userId: widget.userIds[index],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
