import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'image_editor.dart';

class ImageGridScreen extends StatefulWidget {
  const ImageGridScreen({super.key});

  @override
  _ImageGridScreenState createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends State<ImageGridScreen> {
  late Future<List<String>> _imageUrlsFuture;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0;
  List<String> _imageUrlsList = [];

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
  }

  Future<void> _fetchImageUrls() async {
    List<Map<String, dynamic>> imageInfoList = [];
    final storageRef = FirebaseStorage.instance.ref().child('images');

    try {
      final listResult = await storageRef.listAll();

      for (var item in listResult.items) {
        final url = await item.getDownloadURL();
        final fullPath = item.fullPath;
        final timestamp =
            int.tryParse(fullPath.split('/').last.split('.').first) ?? 0;

        imageInfoList.add({'url': url, 'timestamp': timestamp});
      }

      imageInfoList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } catch (e) {
      print('Error fetching image URLs: $e');
    }

    setState(() {
      _imageUrlsList =
          imageInfoList.map((info) => info['url'] as String).toList();
      print('Fetched image URLs: $_imageUrlsList');
    });
  }

  Future<void> uploadImage(
      {Uint8List? fileBytes, required String fileName}) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      if (fileBytes != null) {
        await storageRef.putData(fileBytes);
      }

      print('Image uploaded successfully.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total Images: ${_imageUrlsList.length + 1}'),
        ),
      );

      _fetchImageUrls();
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Device'),
              onTap: () async {
                Navigator.of(context).pop();
                await _uploadFromDevice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture from Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                await _captureFromCamera();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      showDialog(
        context: context,
        builder: (context) => ImageEditor(
          imageBytes: fileBytes,
          onImageEdited: (editedBytes) async {
            String fileName =
                'images/${DateTime.now().millisecondsSinceEpoch}.png';
            await uploadImage(fileBytes: editedBytes, fileName: fileName);
          },
        ),
      );
    } else {
      print('No file selected.');
    }
  }

  Future<void> _captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      Uint8List fileBytes = await photo.readAsBytes();
      showDialog(
        context: context,
        builder: (context) => ImageEditor(
          imageBytes: fileBytes,
          onImageEdited: (editedBytes) async {
            String fileName =
                'images/${DateTime.now().millisecondsSinceEpoch}.png';
            await uploadImage(fileBytes: editedBytes, fileName: fileName);
          },
        ),
      );
    } else {
      print('No image captured.');
    }
  }

  Widget _buildGridView() {
    switch (_selectedIndex) {
      case 0:
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: _imageUrlsList.length,
          itemBuilder: (context, index) {
            return _buildImageTile(_imageUrlsList[index]);
          },
        );
      case 1:
        return GridView.custom(
          gridDelegate: SliverWovenGridDelegate.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            pattern: [
              const WovenGridTile(1),
              const WovenGridTile(
                5 / 7,
                crossAxisRatio: 0.9,
                alignment: AlignmentDirectional.centerEnd,
              ),
            ],
          ),
          childrenDelegate: SliverChildBuilderDelegate(
            (context, index) => _buildImageTile(_imageUrlsList[index]),
            childCount: _imageUrlsList.length,
          ),
        );
      case 2:
      default:
        return MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: _imageUrlsList.length,
          itemBuilder: (context, index) {
            return _buildImageTile(_imageUrlsList[index]);
          },
        );
    }
  }

  Widget _buildImageTile(String imageUrl) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Center(
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Color.fromARGB(237, 255, 254, 254), size: 30),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Hero(
          tag: imageUrl,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingGlassmorphicBottomNavbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.view_comfortable),
                    label: 'Staggered',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view),
                    label: 'Woven',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.view_module),
                    label: 'Masonry',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: Colors.white.withOpacity(0.2),
                pinned: true,
                snap: false,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Image Gallery',
                      style: TextStyle(color: Colors.white)),
                  centerTitle: true,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              SliverFillRemaining(
                child: _imageUrlsList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildGridView(),
                      ),
              ),
            ],
          ),
          _buildFloatingGlassmorphicBottomNavbar(),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: ImageGridScreen()));
}
