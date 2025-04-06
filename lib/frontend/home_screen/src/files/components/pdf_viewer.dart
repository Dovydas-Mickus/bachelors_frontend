import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:typed_data';

class PdfViewerScreen extends StatefulWidget {
  final Uint8List pdfBytes;

  const PdfViewerScreen({super.key, required this.pdfBytes});

  @override
  PdfViewerScreenState createState() => PdfViewerScreenState();
}

class PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openData(widget.pdfBytes),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(physics: BouncingScrollPhysics()),
        child: PdfView(
          controller: _pdfController,
          scrollDirection: Axis.vertical,
        ),
      );
  }
}
