import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, Icons.home, 'Home Feed'),
          _buildNavItem(context, 1, Icons.search, 'Search'),
          _buildNavItem(context, 2, Icons.message, 'Messages'),
          _buildProfileNavItem(context),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary),
            if (isSelected) SizedBox(width: 8),
            if (isSelected) Text(label, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildNavItem(context, 3, Icons.account_circle, 'Profile');
        }

        var user = snapshot.data!.data() as Map<String, dynamic>;
        bool isSelected = currentIndex == 3;
        return GestureDetector(
          onTap: () => onTap(3),
          child: Container(
            color: Theme.of(context).colorScheme.background,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user['profile_picture']),
                ),
                if (isSelected) SizedBox(width: 8),
                if (isSelected) Text(user['username'], style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
