import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ensure consistent ordering
    return ids.join('_');
  }

  Future<DocumentReference> getOrCreateChat(String receiverId) async {
    final currentUser = _auth.currentUser;
    final chatId = _getChatId(currentUser!.uid, receiverId);
    final chatDoc = _firestore.collection('Chats').doc(chatId);

    final chatSnapshot = await chatDoc.get();
    if (!chatSnapshot.exists) {
      await chatDoc.set({
        'participants': [currentUser.uid, receiverId],
      });
    }
    return chatDoc;
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('Chats')
        .doc(chatId)
        .collection('Messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String chatId, String text) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection('Chats').doc(chatId).collection('Messages').add({
      'text': text,
      'senderId': currentUser?.uid,
      'timestamp': Timestamp.now(),
      'type': 'text',
    });
  }

  Future<void> sendImageMessage(String chatId, File image) async {
    final currentUser = _auth.currentUser;
    final storageRef = _storage.ref().child('chat_images').child(chatId).child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('Chats').doc(chatId).collection('Messages').add({
      'imageUrl': imageUrl,
      'senderId': currentUser?.uid,
      'timestamp': Timestamp.now(),
      'type': 'image',
    });
  }

  Future<void> deleteMessage(DocumentReference messageRef) async {
    await messageRef.delete();
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('Users').doc(userId).get();
    return doc.data() as Map<String, dynamic>;
  }
}
