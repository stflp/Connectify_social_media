import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  signInWithGoogle() async {
    
    final GoogleSignInAccount? user = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication authentification = await user!.authentication;

    final credentials = GoogleAuthProvider.credential(
      accessToken: authentification.accessToken,
      idToken: authentification.idToken,
    );

    UserCredential userCredentials = await FirebaseAuth.instance.signInWithCredential(credentials);

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userCredentials.user!.uid).get();
    if (!userDoc.exists) {
    await FirebaseFirestore.instance.collection('Users').doc(userCredentials.user!.uid).set({
      'email': userCredentials.user!.email,
      'username': userCredentials.user!.displayName ?? 'No username',
      'bio': 'Nothing to see here...',
      'profile_picture': userCredentials.user!.photoURL ?? 'https://firebasestorage.googleapis.com/v0/b/social-media-app-af85c.appspot.com/o/pfps%2Fdefault.jpg?alt=media&token=11cdbcb1-c0c1-45e9-812b-a24b7e21d773',
      'followers': [],
      'following': [],
    });
  }

  return userCredentials;
  }
}