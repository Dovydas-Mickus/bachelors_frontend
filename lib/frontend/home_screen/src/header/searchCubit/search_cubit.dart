import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/cloud_item.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  APIRepository api;
  SearchCubit({required this.api}) : super(SearchState(query: '', items: []));


  void queryChanged(String query) async {
    List<CloudItem> items = await api.getSearch(query);
    emit(state.copyWith(query: query, items: items));
  }
}
