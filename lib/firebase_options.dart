
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCXzOsQqppTfekR2IiSLQSCHZraQKjLl4g", 
        appId: "1:864800184550:android:3215a8e8b613054df28327", 
        messagingSenderId: "864800184550", // Look for 'Sender ID' 
        projectId: "kidspark-47928", //  Project ID
        storageBucket: "kidspark-47928.firebasestorage.app", //  Storage Bucket
      );
    }
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }
}