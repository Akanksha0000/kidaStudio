import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; 
import 'registration_screen.dart'; 
import 'image_grid_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDZiZCwOc-gIxxrk-mpGVQ7AgOfasCZdC8",
        authDomain: "bentogrid-375ae.firebaseapp.com",
        projectId: "bentogrid-375ae",
        storageBucket: "bentogrid-375ae.appspot.com",
        messagingSenderId: "384077576399",   
        appId: "1:384077576399:web:2f5cfdb514e577cae3dfba"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const RegistrationScreen(),
    
    );
  }
}
