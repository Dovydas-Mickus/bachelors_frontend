import 'package:flutter/material.dart';
import 'package:micki_nas/frontend/home_screen/src/header/src/search_field.dart';

class ExpandedHeader extends StatelessWidget {
  const ExpandedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(

      children: [
        const Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.center,
            child: Text("Micki'nas"),
          ),
        ),
        const Expanded(flex: 8, child: SearchField()),
        const Expanded(flex: 3, child: SizedBox()),
      ],
    );

  }
}
