import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/main_screen/cubit/app_cubit.dart';
import 'package:micki_nas/frontend/main_screen/theme_data/cubit/theme_cubit.dart';

class AppProviders {
  static MultiRepositoryProvider repositoryProviders({required Widget child}) {
    return MultiRepositoryProvider(providers: [
      RepositoryProvider(create: (_) => APIRepository())
    ],
        child: child,
    );
  }
  static MultiBlocProvider blocProviders({required Widget child, required APIRepository api}) {
    return MultiBlocProvider(providers: [
      BlocProvider(create: (_) => ThemeCubit()),
      BlocProvider(create: (_) => AppCubit(api: api))
    ],
        child: child,
    );
  }
}