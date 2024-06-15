import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../components/helper_functions.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  Uint8List? _file;
  bool isSelected = false;
  bool isLoading = false;
  TextEditingController _textEditingController = TextEditingController();

  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Take a photo'),
                onPressed: () async {
                  Navigator.pop(context);
                  XFile? file = await pickImage(ImageSource.camera);
                  Uint8List? bytes = await file?.readAsBytes();
                  setState(() {
                    _file = bytes;
                    isSelected = true;
                  });
                }),
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Choose from Gallery'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  XFile? file = await pickImage(ImageSource.gallery);
                  Uint8List? bytes = await file?.readAsBytes();
                  setState(() {
                    _file = bytes;
                    isSelected = true;
                  });
                }),
            if(isSelected==true) SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Remove Image"),
              onPressed: () {
                setState(() {
                  _file = null;
                  isSelected = false;
                });
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  final user = FirebaseAuth.instance.currentUser!;

  void createPost() async {
    if (_textEditingController.text.isNotEmpty || _file != null) {
      String imageURL = "";
      if (_file != null) {
        imageURL = await StorageMethods().uploadPostImage(_file!);
      }
      await FirebaseFirestore.instance.collection("Posts").add({
        "text": _textEditingController.text,
        "imageUrl": imageURL,
        "timestamp": Timestamp.now(),
        "likes": [],
        "comments": [],
        "userId": user.uid,
      });
      setState(() {
        _textEditingController.clear();
        _file = null;
        isSelected = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              createPost();
            },
            child: Text(
              'Post',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
          return Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: 'Write your post...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0)
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _selectImage(context);
                  },
                  child:  isSelected == false ? Text(
                      'Add Photo',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ) : Container(
                    height: 100,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.memory(
                              _file!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
      ),
    );
  }
}