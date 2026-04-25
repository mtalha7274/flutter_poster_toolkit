import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_poster/flutter_poster.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PosterExampleApp());
}

class PosterExampleApp extends StatefulWidget {
  const PosterExampleApp({super.key});

  @override
  State<PosterExampleApp> createState() => _PosterExampleAppState();
}

class _PosterExampleAppState extends State<PosterExampleApp> {
  late final PosterController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = PosterController(document: PosterDocument.empty());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Poster Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563eb)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: PosterEditor(
            controller: _controller,
            onPickImage: _pickImage,
            onExportPng: _savePng,
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.readAsBytes();
  }

  Future<void> _savePng(PosterExportResult result) async {
    await FileSaver.instance.saveFile(
      name: 'lost-cat-poster',
      bytes: result.bytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
  }
}
