// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:micki_nas/frontend/firebase_login_screen/cubit/firebase_login_cubit.dart';
// import 'package:micki_nas/frontend/home_screen/home_screen.dart';
//
// import '../../main_screen/cubit/app_cubit.dart';
//
// class LoginEmailInput extends StatelessWidget {
//   const LoginEmailInput({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
//       child: TextField(
//         onChanged: (value) => context.read<FirebaseLoginCubit>().emailChanged(value),
//         keyboardType: TextInputType.emailAddress,
//         decoration: InputDecoration(
//           labelText: 'Email',
//           prefixIcon: Icon(Icons.email),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }
// }
//
// class LoginPasswordInput extends StatelessWidget {
//   const LoginPasswordInput({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
//       child: TextField(
//         onChanged: (value) => context.read<FirebaseLoginCubit>().passwordChanged(value),
//         obscureText: true,
//         decoration: InputDecoration(
//           labelText: 'Password',
//           prefixIcon: Icon(Icons.lock),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }
// }
//
// class LoginButton extends StatelessWidget {
//   const LoginButton({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: () async {
//             try {
//               context.read<AppCubit>().stateChanged(AppStatus.loading);
//               await context.read<FirebaseLoginCubit>().signInWithEmailAndPassword();
//               if(context.mounted) {
//                 context.read<AppCubit>().stateChanged(AppStatus.loggedIn);
//                 Navigator.of(context).push(MaterialPageRoute(builder: (builder) => HomeScreen()));
//               }
//             } catch (e) {
//               debugPrint(e.toString());
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Login failed: ${e.toString()}')),
//                 );
//               }
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             backgroundColor: Theme.of(context).colorScheme.secondary,
//             foregroundColor: Theme.of(context).colorScheme.onSecondary,
//           ),
//           child: const Text('Login', style: TextStyle(fontSize: 16)),
//         ),
//       ),
//     );
//   }
// }
