import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/info_dialog.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userphoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  CommonMethods commonMethods = const CommonMethods();

  signUpFormValidation() {
    if (_usernameController.text.trim().length < 3) {
      commonMethods.displaySnackBar(
        'Username must be at least 3 characters long!',
        context,
      );
      return false;
    } else if (_userphoneController.text.trim().length < 10) {
      commonMethods.displaySnackBar(
        'Phone number must be at least 10 characters long!',
        context,
      );
      return false;
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      commonMethods.displaySnackBar(
        'Invalid email address!',
        context,
      );
      return false;
    } else if (_passwordController.text.trim().length < 6) {
      commonMethods.displaySnackBar(
        'Password must be at least 6 characters long!',
        context,
      );
      return false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      commonMethods.displaySnackBar(
        'Passwords do not match!',
        context,
      );
      return false;
    }
  }

  registerNewUser() async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const LoadingDialog(messageText: 'Creating account...'),
      );
    }

    String res = await AuthMethods().signupUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      userphone: _userphoneController.text.trim(),
      context: context,
    );

    if (mounted) Navigator.pop(context);

    if (res != 'Success') {
      // ignore: use_build_context_synchronously
      if (context.mounted) commonMethods.displaySnackBar(res, context);
    } else {
      model.User? user = await AuthMethods().getUserDetails();

      if (mounted) {
        await showDialog(
            context: context,
            builder: (context) => InfoDialog(
                  title: 'Welcome ${user.displayName}',
                  content:
                      'Account created successfully!. Please verify your email before proceeding',
                ));
      }

      await commonMethods.askForLocationPermission();
      await commonMethods.askForNotificationPermission();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _userphoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset('assets/images/logo_white_borders.png',
                    height: 200, width: 200),
                const SizedBox(height: 10),
                const Text(
                  'Create a User\'s Account',
                ),
                // text fields
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _userphoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: 'Enter your phone number',
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Confirm your password',
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () {
                          checkNetwork();
                          if (signUpFormValidation() == false) {
                            return;
                          }

                          registerNewUser();
                        },
                        child: const Text(
                          'Sign Up',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Sign In',
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
    );
  }
}
