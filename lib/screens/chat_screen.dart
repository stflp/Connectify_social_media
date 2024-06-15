import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../components/chat_service.dart';
import 'other_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  ChatScreen({required this.receiverId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final chat = await _chatService.getOrCreateChat(widget.receiverId);
    setState(() {
      _chatId = chat.id;
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty && _chatId != null) {
      await _chatService.sendMessage(_chatId!, _controller.text);
      _controller.clear();
    }
  }

  Future<void> _sendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _chatId != null) {
      File image = File(pickedFile.path);
      await _chatService.sendImageMessage(_chatId!, image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _chatService.getUserData(widget.receiverId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Chat', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final receiverData = snapshot.data!;
        final receiverName = receiverData['username'];
        final receiverImageUrl = receiverData['profile_picture'];

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherProfileScreen(userId: widget.receiverId),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(receiverImageUrl),
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    receiverName,
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            ),
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: Column(
            children: [
              Expanded(
                child: _chatId == null
                    ? Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: _chatService.getMessages(_chatId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final messages = snapshot.data!.docs;
                          return ListView.builder(
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final messageData = messages[index].data() as Map<String, dynamic>;
                              final isMe = messageData['senderId'] == _currentUser?.uid;
                              final type = messageData.containsKey('type') ? messageData['type'] : 'text';
                              return GestureDetector(
                                onLongPress: isMe
                                    ? () => _showDeleteDialog(messages[index].reference)
                                    : null,
                                child: type == 'text'
                                    ? _buildMessage(messageData['text'], isMe)
                                    : _buildImageMessage(messageData['imageUrl'], isMe),
                              );
                            },
                          );
                        },
                      ),
              ),
              _buildMessageComposer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Image.network(imageUrl),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _sendImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(DocumentReference messageRef) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _chatService.deleteMessage(messageRef);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
