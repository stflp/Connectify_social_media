import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'other_profile_screen.dart';
import '../components/theme_provider.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection("Users").snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        title: TextFormField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _usersStream = FirebaseFirestore.instance
                  .collection("Users")
                  .where("username", isGreaterThanOrEqualTo: value)
                  .where("username", isLessThan: value + 'z')
                  .snapshots();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
            border: InputBorder.none,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }


          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherProfileScreen(
                        userId: snapshot.data!.docs[index].id,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    snapshot.data!.docs[index]["profile_picture"],
                  ),
                ),
                title: Text(snapshot.data!.docs[index]["username"]),
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