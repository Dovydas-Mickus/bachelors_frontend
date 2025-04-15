import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/cloud_item.dart';
import 'package:micki_nas/frontend/home_screen/src/files/file_view/file_view.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final SearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSearch() {
    if (_controller.isOpen) {
      _controller.closeView(''); // hide suggestions
      FocusManager.instance.primaryFocus?.unfocus(); // dismiss keyboard
      _controller.clear();
      _controller.clearComposing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeSearch,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 45,
        child: SearchAnchor.bar(
          barHintText: 'Search',
          barElevation: WidgetStateProperty.all(0),
          searchController: _controller,
          suggestionsBuilder: (BuildContext context, SearchController controller) async {
            final List<CloudItem> results = await context.read<APIRepository>().getSearch(controller.text);

            return List<ListTile>.generate(results.length, (int index) {
              final CloudItem item = results[index];

              return ListTile(
                title: Text(item.name.split('/').last),
                onTap: () {
                  _closeSearch(); // close the search when tapping on a result
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "File viewer",
                    transitionDuration: const Duration(milliseconds: 150),
                    pageBuilder: (context, anim1, anim2) {
                      return Scaffold(
                        body: SafeArea(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: FileView(
                              path: item.name,
                              name: item.name.split('/').last,
                              repo: context.read<APIRepository>(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}
