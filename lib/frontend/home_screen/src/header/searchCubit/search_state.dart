part of 'search_cubit.dart';

class SearchState extends Equatable {
  final String query;
  final List<CloudItem> items;

  const SearchState({
    this.query = '',
    this.items = const [],
  });

  @override
  List<Object?> get props => [query, items];

  SearchState copyWith({
    String? query,
    List<CloudItem>? items,
  }) {
    return SearchState(
      query: query ?? this.query,
      items: items ?? this.items,
    );
  }
}

