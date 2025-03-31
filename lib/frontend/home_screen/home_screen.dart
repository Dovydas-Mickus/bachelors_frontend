import 'package:flutter/material.dart';
import 'package:micki_nas/frontend/home_screen/layout.dart';
import 'package:micki_nas/frontend/home_screen/src/files/files.dart';
import 'package:micki_nas/frontend/home_screen/src/header/header.dart';
import 'package:micki_nas/frontend/home_screen/src/left_side_bar/left_side_bar.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final Widget header = Header();
  final Widget leftSide = LeftSideBar();
  final Widget mainPart = Files();
  final Widget rightSide = Text('rightSide');

  @override
  Widget build(BuildContext context) {
    return Layout(header: header, leftSide: leftSide, mainPart: mainPart, rightSide: rightSide);
  }
}
