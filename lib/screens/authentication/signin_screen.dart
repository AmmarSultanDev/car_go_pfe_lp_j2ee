import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signup_screen.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/screens/home_screen.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  CommonMethods commonMethods = const CommonMethods();

  signin() async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(messageText: 'Signing in ...'),
    );

    String res = await AuthMethods().signinUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (res != 'Success') {
      if (context.mounted) {
        Navigator.of(context).pop();
        commonMethods.displaySnackBar(res, context);
      }
    } else {
      if (context.mounted) {
        await Provider.of<UserProvider>(context, listen: false).refreshUser();
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void checkNetwork() async {
      // Check network connection
      await commonMethods.checkConnectivity(context);
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Image.asset('assets/images/logo_white_borders.png',
                      height: 200, width: 200),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome',
                  ),
                  // text fields
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: () {
                            checkNetwork();
                            signin();
                          },
                          child: const Text(
                            'Sign In',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Don\'t have an account?',
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen()));
                              },
                              child: const Text(
                                'Sign Up',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
