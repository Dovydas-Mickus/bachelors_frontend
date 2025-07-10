import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import '../../core/constants.dart';

class Layout extends StatelessWidget {
  final Widget header;
  final Widget leftSide;
  final List<SpeedDialChild> speedDialChildren;
  final Widget mainPart;
  final Widget rightSide;
  final String? userId;

  const Layout({
    super.key,
    required this.header,
    required this.leftSide,
    required this.speedDialChildren,
    required this.mainPart,
    required this.rightSide,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= CONSTRAINTS_BREAKPOINT;

    return Scaffold(
      appBar: AppBar(
        title: header,
        forceMaterialTransparency: true,
      ),

      // Left drawer on desktop only
      endDrawer: isDesktop
          ? null
          : Drawer(
              width: 220,
              child: rightSide,
            ),
      endDrawerEnableOpenDragGesture: false,

      // Speed dial replaces left drawer on mobile
      floatingActionButton: isDesktop
          ? null
          : SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              children: speedDialChildren,
            ),

      body: isDesktop
          ? Row(
              children: [
                // Left sidebar
                SizedBox(width: 200, child: leftSide),

                // Main content area with optional admin banner
                Expanded(
                  child: Column(
                    children: [
                      if (userId != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: const Icon(
                              Icons.warning,
                              color: Colors.black,
                            ),
                            title: const Text(
                              'Admin view, tap to go back',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              context.read<APIRepository>().userId = null;
                              await context
                                  .read<FilesCubit>()
                                  .loadFolder('', userId: null);
                            },
                            tileColor: Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      Expanded(child: mainPart),
                    ],
                  ),
                ),

                // Right sidebar
                SizedBox(width: 200, child: rightSide),
              ],
            )
          : Column(
              children: [
                if (userId != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning,
                        color: Colors.black,
                      ),
                      title: const Text(
                        'Admin view, tap to go back',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        context.read<APIRepository>().userId = null;
                        await context
                            .read<FilesCubit>()
                            .loadFolder('', userId: null);
                      },
                      tileColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                Expanded(child: mainPart),
              ],
            ),
    );
  }
}
