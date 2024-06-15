import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../components/chat_preview.dart';
import '../components/theme_provider.dart';
import 'package:provider/provider.dart';

class MessageScreen extends StatefulWidget {
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = FirebaseFirestore.instance
        .collection('Chats')
        .where('participants', arrayContains: _currentUser!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversations', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
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
      ),
      body: StreamBuilder(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(chatDoc.id)
                    .collection('Messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData) {
                    return Container();
                  }

                  final messageDocs = messageSnapshot.data!.docs;
                  if (messageDocs.isEmpty) {
                    return Container();
                  }

                  final lastMessageDoc = messageDocs.first;
                  final lastMessage = lastMessageDoc['type'] == 'text'
                      ? lastMessageDoc['text']
                      : '[Image]';

                  final otherParticipantId = chatDoc['participants'].firstWhere((id) => id != _currentUser!.uid);

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(otherParticipantId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Container();
                      }

                      final user = userSnapshot.data!;
                      final username = user['username'];
                      final profilePicture = user['profile_picture'];

                      return ChatPreview(
                        userId: user.id,
                        profilePicture: profilePicture,
                        username: username,
                        lastMessage: lastMessage,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(receiverId: otherParticipantId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
