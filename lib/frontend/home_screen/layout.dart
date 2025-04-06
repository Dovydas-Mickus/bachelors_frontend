import 'package:flutter/material.dart';

class Layout extends StatelessWidget {
  final Widget header;
  final Widget leftSide;
  final Widget mainPart;
  final Widget rightSide;

  const Layout({
    super.key,
    required this.header,
    required this.leftSide,
    required this.mainPart,
    required this.rightSide,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(title: header),

      // Show drawers on mobile
      drawer: isDesktop ? null : Drawer(child: leftSide),
      endDrawer: isDesktop ? null : Drawer(child: rightSide),
      endDrawerEnableOpenDragGesture: false,
      body: isDesktop
          ? Row(
        children: [
          // Left Sidebar
          SizedBox(width: 200, child: leftSide),

          // Main Content
          Expanded(child: mainPart),

          // Right Sidebar
          SizedBox(width: 200, child: rightSide),
        ],
      )
          : mainPart, // Mobile body only shows mainPart (drawers open via appbar menu)
    );
  }
}
