import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/button.dart';
import '../components/textfield.dart';

class RegisterScreen extends StatefulWidget {

  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  Future<void> createAccount() async {
    if(passwordController.text != confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Passwords do not match!'),
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
    }

    else{
      try{
      UserCredential? userCredentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      FirebaseFirestore.instance.collection("Users").doc(userCredentials.user!.uid).set({
        'email': emailController.text,
        'username': usernameController.text,
        'bio': 'Nothing to see here...',
        'profile_picture': 'https://firebasestorage.googleapis.com/v0/b/social-media-app-af85c.appspot.com/o/pfps%2Fdefault.jpg?alt=media&token=11cdbcb1-c0c1-45e9-812b-a24b7e21d773',
        'followers': [],
        'following': []
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Account created successfully!'),
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
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Something went wrong!'),
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
    }
  };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onBackground,
                      width: 2.0,
                    ),
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Textfield(
                    labelText: 'Email',
                    isPassword: false,
                    controller: emailController,
                  ),
                    
                  SizedBox(height: 15.0),
                    
                  Textfield(
                    labelText: 'Username',
                    isPassword: false,
                    controller: usernameController,
                  ),
                    
                  SizedBox(height: 15.0),
                    
                  Textfield(
                    labelText: 'Password',
                    isPassword: true,
                    controller: passwordController,
                  ),
            
                  SizedBox(height: 15.0),
                    
                  Textfield(
                    labelText: 'Confirm Password',
                    isPassword: true,
                    controller: confirmPasswordController,
                  ),
            
                  SizedBox(height: 40.0),
            
                  Button(
                    text: 'Create account',
                    onPressed: () {
                      createAccount();
                    },
                  ),
            
                  SizedBox(height: 10.0),
            
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      )),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text("Sign in!", style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}