import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<XFile?> pickImage(ImageSource source) async {
  final ImagePicker _picker = ImagePicker();
  XFile? image = await _picker.pickImage(source: source);
  return image;
}


class StorageMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadImage(String name, Uint8List file) async {
    Reference ref = _storage.ref().child(name).child(_auth.currentUser!.uid);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String url = await taskSnapshot.ref.getDownloadURL();
    return url;
  }

  Future<String> uploadPostImage(Uint8List file) async {
    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    
    Reference ref = _storage.ref().child('Posts').child(_auth.currentUser!.uid).child(uniqueFileName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String url = await taskSnapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('Users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('Users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('Users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        await _firestore.collection('Users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('Users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('Posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await _firestore.collection('Posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> addComment(String postId, String uid, String text) async {
    try {
      await _firestore.collection('Posts').doc(postId).collection('Comments').add({
        'userId': uid,
        'text': text,
        'likes': [],
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> likeComment(String postId, String commentId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('Posts').doc(postId).collection('Comments').doc(commentId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await _firestore.collection('Posts').doc(postId).collection('Comments').doc(commentId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore.collection('Posts').doc(postId).collection('Comments').doc(commentId).delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> updateCommentCountInPosts() async {
    try {
      QuerySnapshot postsSnapshot =
          await FirebaseFirestore.instance.collection('Posts').get();

      Map<String, int> postCommentCounts = {};

      for (QueryDocumentSnapshot postDoc in postsSnapshot.docs) {
        String postId = postDoc.id;

        QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .collection('Comments')
            .get();

        postCommentCounts[postId] = commentsSnapshot.size;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      postCommentCounts.forEach((postId, commentCount) {
        DocumentReference postRef =
            FirebaseFirestore.instance.collection('Posts').doc(postId);

        batch.update(postRef, {'comments': commentCount});
      });

      await batch.commit();
      print('Comment counts updated successfully.');
    } catch (error) {
      print('Error updating comment counts: $error');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      DocumentSnapshot postSnap = await _firestore.collection('Posts').doc(postId).get();
      String imageUrl = postSnap['imageUrl'];

      await _firestore.collection('Posts').doc(postId).delete();

      Reference imageRef = _storage.refFromURL(imageUrl);
      await imageRef.delete();
    } catch (e) {
      print(e.toString());
    }
  }
}