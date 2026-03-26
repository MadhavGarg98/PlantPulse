import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(XFile imageFile, {String? customFileName}) async {
    try {
      // Generate unique filename if not provided
      String fileName = customFileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      
      // Create reference to the file location
      Reference ref = _storage.ref().child('plant_images/$fileName');

      // Upload the file
      UploadTask uploadTask = ref.putFile(File(imageFile.path));

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Get upload progress stream
  static Stream<TaskSnapshot> getUploadProgress(XFile imageFile, {String? customFileName}) {
    String fileName = customFileName ?? 
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
    Reference ref = _storage.ref().child('plant_images/$fileName');
    return ref.putFile(File(imageFile.path)).snapshotEvents;
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages(List<XFile> imageFiles) async {
    List<String> downloadUrls = [];
    
    for (XFile imageFile in imageFiles) {
      String? downloadUrl = await uploadImage(imageFile);
      if (downloadUrl != null) {
        downloadUrls.add(downloadUrl);
      }
    }
    
    return downloadUrls;
  }
}
