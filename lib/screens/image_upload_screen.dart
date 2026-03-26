import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../models/plant_model.dart';
import 'dart:math';

class ImageUploadScreen extends StatefulWidget {
  final User user;

  const ImageUploadScreen({super.key, required this.user});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<String> _uploadedImages = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Future<void> _pickAndUploadImage({String? customName, String? customType, String? customNotes}) async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Choose Image Source', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text('Camera', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text('Gallery', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'dummy'),
              child: Text('Use Dummy Data', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );

      if (source == null) return;
      
      if (source == 'dummy') {
        await _addDummyPlant();
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        try {
          // Show upload progress
          FirebaseStorageService.getUploadProgress(image).listen((snapshot) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          });

          // Upload image
          final String? downloadUrl = await FirebaseStorageService.uploadImage(
            image,
            customFileName: 'plant_${DateTime.now().millisecondsSinceEpoch}',
          );

          setState(() {
            _isUploading = false;
          });

          if (downloadUrl != null) {
            setState(() {
              _uploadedImages.add(downloadUrl);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image uploaded successfully! 🌿'),
                backgroundColor: Color(0xFF1B5E20),
              ),
            );
            
            print('Uploaded image URL: $downloadUrl');
          } else {
            // Fallback to dummy data if upload fails
            await _addDummyPlant();
          }
        } catch (e) {
          setState(() {
            _isUploading = false;
          });
          
          print('Upload error: $e');
          
          // Show error and offer dummy data option
          final shouldAddDummy = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Upload Failed', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              content: Text(
                'Failed to upload image: ${e.toString()}\n\nWould you like to add a plant with dummy data instead?',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: GoogleFonts.inter()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add Dummy Plant', style: GoogleFonts.inter()),
                ),
              ],
            ),
          );
          
          if (shouldAddDummy == true) {
            await _addDummyPlant();
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addDummyPlant() async {
    try {
      final dummyPlants = [
        {
          'name': 'Monstera Deliciosa',
          'type': 'Tropical Plant',
          'imageUrl': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
          'notes': 'Loves bright, indirect light',
        },
        {
          'name': 'Snake Plant',
          'type': 'Succulent',
          'imageUrl': 'https://images.unsplash.com/photo-1527248403834-dcf5afe3383d',
          'notes': 'Very low maintenance',
        },
        {
          'name': 'Pothos',
          'type': 'Vining Plant',
          'imageUrl': 'https://images.unsplash.com/photo-1578616066572-a408562b1c9f',
          'notes': 'Great for beginners',
        },
        {
          'name': 'Fiddle Leaf Fig',
          'type': 'Tree',
          'imageUrl': 'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
          'notes': 'Needs bright, consistent light',
        },
        {
          'name': 'Peace Lily',
          'type': 'Flowering Plant',
          'imageUrl': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
          'notes': 'Droops when thirsty',
        },
      ];
      
      final randomPlant = dummyPlants[Random().nextInt(dummyPlants.length)];
      
      final PlantModel newPlant = PlantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: randomPlant['name']!,
        type: randomPlant['type']!,
        imageUrl: randomPlant['imageUrl'],
        createdAt: DateTime.now().toIso8601String(),
        lastWatered: DateTime.now().toIso8601String(),
        notes: randomPlant['notes'],
      );

      await _firestoreService.addPlantData(widget.user.uid, newPlant.toFirestore());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newPlant.name} added successfully! 🌱'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      
      // Navigate back to dashboard
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding dummy plant: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageToPlant(String imageUrl) async {
    // Show dialog to enter plant details
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plant Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Plant Name',
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Plant Type',
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              style: GoogleFonts.inter(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': _nameController.text.isNotEmpty ? _nameController.text : 'Plant ${Random().nextInt(1000)}',
                'type': _typeController.text.isNotEmpty ? _typeController.text : 'Unknown',
                'notes': _notesController.text,
              });
            },
            child: Text('Save', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final PlantModel newPlant = PlantModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name']!,
          type: result['type']!,
          imageUrl: imageUrl,
          createdAt: DateTime.now().toIso8601String(),
          lastWatered: DateTime.now().toIso8601String(),
          notes: result['notes']?.isNotEmpty == true ? result['notes'] : null,
        );

        await _firestoreService.addPlantData(widget.user.uid, newPlant.toFirestore());
        
        // Clear controllers
        _nameController.clear();
        _typeController.clear();
        _notesController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plant added successfully! 🌱'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        
        // Navigate back to dashboard
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Upload Plant Photos',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUploadSection(),
                const SizedBox(height: 24),
                _buildUploadedImagesGrid(),
              ],
            ),
          ),
          if (_isUploading) _buildUploadProgressOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUploadImage(),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(
          'Upload Photo',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_upload,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Plant Photos',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Add photos of your plants to track their growth',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _pickAndUploadImage(),
            icon: const Icon(Icons.photo_library),
            label: Text(
              'Choose from Gallery',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _addDummyPlant(),
            icon: const Icon(Icons.dataset),
            label: Text(
              'Add Dummy Plant',
              style: GoogleFonts.inter(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedImagesGrid() {
    if (_uploadedImages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No photos uploaded yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to upload your first plant photo',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Photos (${_uploadedImages.length})',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: _uploadedImages.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final imageUrl = _uploadedImages[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => _saveImageToPlant(imageUrl),
                          icon: const Icon(Icons.eco, color: Color(0xFF1B5E20)),
                          tooltip: 'Add to Plants',
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _uploadedImages.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image removed'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUploadProgressOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 16),
              Text(
                'Uploading image...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
