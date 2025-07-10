// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:micki_nas/frontend/firebase_login_screen/components/inputs.dart';
//
// import '../../core/repositories/authentication_repository.dart';
// import 'cubit/firebase_login_cubit.dart';
//
// class FirebaseLoginScreen extends StatelessWidget {
//   const FirebaseLoginScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) =>
//           FirebaseLoginCubit(
//               authenticationRepository: context.read<
//                   AuthenticationRepository>()),
//       child: BlocBuilder<FirebaseLoginCubit, FirebaseLoginState>(
//         builder: (context, state) {
//           return Scaffold(
//             appBar: AppBar(),
//             body: Column(
//               children: [
//                 Text(
//                   'Login',
//                   style: TextStyle(
//                     fontSize: 35,
//                   ),
//                 ),
//                 Text(state.errorMessage == ''
//                     ? ''
//                     : 'Error: ${state.errorMessage}'),
//                 LoginEmailInput(),
//                 LoginPasswordInput(),
//                 LoginButton(),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text("Don't have an account?"),
//                     TextButton(
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         foregroundColor:
//                         Theme
//                             .of(context)
//                             .colorScheme
//                             .secondary,
//                       ),
//                       onPressed: () {
//                         // Navigator.of(context).push(MaterialPageRoute(
//                         //     builder: (builder) => RegisterScreen()));
//                       },
//                       child: Text("Register"),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
