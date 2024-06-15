import 'package:flutter/material.dart';

class ChatPreview extends StatelessWidget {
  final String userId;
  final String username;
  final String profilePicture;
  final String lastMessage;
  final VoidCallback onTap;

  ChatPreview({
    required this.userId,
    required this.username,
    required this.profilePicture,
    required this.lastMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profilePicture),
      ),
      title: Text(username),
      subtitle: Text(lastMessage),
    );
  }
}
