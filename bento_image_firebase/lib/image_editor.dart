import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageEditor extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onImageEdited;

  const ImageEditor({
    Key? key,
    required this.imageBytes,
    required this.onImageEdited,
  }) : super(key: key);

  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  img.Image? _image;
  double _rotation = 0.0;
  Rect _cropRect = Rect.zero;
  bool _isDragging = false;
  late Offset _dragStart;
  late Rect _initialCropRect;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _image = img.decodeImage(widget.imageBytes);
      _cropRect = Rect.fromLTWH(
        50, 50, _image!.width * 0.6, _image!.height * 0.6);  // Initial crop area
    });
  }

  void _applyChanges() {
    if (_image == null || _cropRect.isEmpty) return;

    int left = _cropRect.left.toInt();
    int top = _cropRect.top.toInt();
    int width = _cropRect.width.toInt();
    int height = _cropRect.height.toInt();

    left = left.clamp(0, _image!.width - width);
    top = top.clamp(0, _image!.height - height);

    final croppedImage = img.copyCrop(
      _image!,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    final rotatedImage = img.copyRotate(
      croppedImage,
      angle: _rotation * 180 / 3.141592653589793,
    );

    final Uint8List imageBytes = Uint8List.fromList(img.encodePng(rotatedImage));

    widget.onImageEdited(imageBytes);
    Navigator.of(context).pop();
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStart = details.localPosition;
      _initialCropRect = _cropRect;
    });
  }

  
  void _onDragUpdate(DragUpdateDetails details) {
  if (_isDragging) {
    setState(() {
      final dx = details.localPosition.dx - _dragStart.dx;
      final dy = details.localPosition.dy - _dragStart.dy;

      // Check which side or corner is being dragged
      double newLeft = _initialCropRect.left;
      double newTop = _initialCropRect.top;
      double newRight = _initialCropRect.right;
      double newBottom = _initialCropRect.bottom;

      if (_dragStart.dx <= _initialCropRect.left + 20) {
        // Dragging from the left side
        newLeft = (_initialCropRect.left + dx).clamp(0, _initialCropRect.right - 50);
      } else if (_dragStart.dx >= _initialCropRect.right - 20) {
        // Dragging from the right side
        newRight = (_initialCropRect.right + dx).clamp(_initialCropRect.left + 50, _image!.width.toDouble());
      }

      if (_dragStart.dy <= _initialCropRect.top + 20) {
        // Dragging from the top side
        newTop = (_initialCropRect.top + dy).clamp(0, _initialCropRect.bottom - 50);
      } else if (_dragStart.dy >= _initialCropRect.bottom - 20) {
        // Dragging from the bottom side
        newBottom = (_initialCropRect.bottom + dy).clamp(_initialCropRect.top + 50, _image!.height.toDouble());
      }

      // Create the updated crop rect with the new positions
      _cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });
  }
}

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  void _rotateImage(double delta) {
    setState(() {
      _rotation += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      title: const Text('Edit Image', style: TextStyle(color: Colors.white)),
      content: _image == null
          ? const Center(child: CircularProgressIndicator())
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: GestureDetector(
                  onPanStart: _onDragStart,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                  child: Stack(
                    children: [
                      Transform.rotate(
                        angle: _rotation,
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                          width: _image!.width.toDouble(),
                          height: _image!.height.toDouble(),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: _cropRect,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => _rotateImage(-0.1), // Rotate left
          child: const Text('Rotate Left', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => _rotateImage(0.1), // Rotate right
          child: const Text('Rotate Right', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: _applyChanges,
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
