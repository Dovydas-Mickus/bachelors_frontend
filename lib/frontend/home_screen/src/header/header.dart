import 'package:flutter/material.dart';

import '../../../../core/constants.dart' as constants;
import 'compact_header/compact_header.dart';
import 'expanded_header/expanded_header.dart';


class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width >= constants.CONSTRAINTS_BREAKPOINT) {
      return ExpandedHeader();
    }
    else {
      return CompactHeader();
    }
  }
}
