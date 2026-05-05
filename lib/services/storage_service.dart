import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(XFile image, String path) async {
    try {
      final Uint8List data = await image.readAsBytes();
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putData(data);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}
