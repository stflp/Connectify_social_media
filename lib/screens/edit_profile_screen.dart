import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/helper_functions.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  final usersCollection = FirebaseFirestore.instance.collection("Users");

  Uint8List? image;

  String newValue = "";

  void selectImage() async {
  XFile? imageFile = await pickImage(ImageSource.gallery);
  
  if (imageFile != null) {
    Uint8List bytes = await imageFile.readAsBytes();
    setState(() {
      image = bytes;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").doc(user.uid).snapshots(),
        builder: (context, snapshot) {
            if(snapshot.hasData){
              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return Scaffold(
                appBar: AppBar(
                  title: Text('Edit Profile', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  iconTheme: IconThemeData(color: Theme.of(context).colorScheme.secondary),
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                        Navigator.pop(context);
                      },
                  ),
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          image != null ? CircleAvatar(
                            radius: 50,
                            backgroundImage: MemoryImage(image!),
                          ) :
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(userData['profile_picture']),
                          ),
                          Positioned(
                            left: 60,
                            bottom: -10,
                            child: IconButton(onPressed: () {
                              selectImage();
                            }, 
                            icon: Icon(Icons.add_a_photo))),
                        ],
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: _usernameController..text = userData['username'],
                        onChanged: (value) {
                          newValue = value;
                          _usernameController.text = newValue;
                        },
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: _bioController..text = userData['bio'],
                        onChanged: (value) {
                          newValue = value;
                          _bioController.text = newValue;
                        },
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () async {
                          if(newValue.trim().length > 0){
                            usersCollection.doc(user.uid).update({
                              'username': _usernameController.text,
                              'bio': _bioController.text,
                            });
                          }
                          if(image != null) {
                            String photoUrl = await StorageMethods().uploadImage('pfps', image!);
                            usersCollection.doc(user.uid).update({
                              'profile_picture': photoUrl
                            });
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {

                              return AlertDialog(
                                content: Text('Profile details saved successfully!'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ),
              );
            }
          else{
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      )
    );
  }
}