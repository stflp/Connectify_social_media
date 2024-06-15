import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'classes/user.dart' as classes;
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<classes.UserClass> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return classes.UserClass.fromSnap(documentSnapshot);
  }
  
  User? _user;

  User get getUser => _user!;

  Future<void> refreshUser() async {
    User user = (await getUserDetails()) as User;
    _user = user;
    notifyListeners();
  }
}