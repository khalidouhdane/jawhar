import 'package:flutter/material.dart';

/// Immersive, verse-by-verse exploration screen for a page's context.
class PageUnderstandingScreen extends StatelessWidget {
  final int sabaqPage;

  const PageUnderstandingScreen({super.key, required this.sabaqPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $sabaqPage Understanding'),
      ),
      body: Center(
        child: Text('Under Construction'),
      ),
    );
  }
}
