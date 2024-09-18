import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/info_dialog.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;

  bool isEditing = false;

  TextEditingController? _usernameController;
  TextEditingController? _userEmailController;
  TextEditingController? _userpasswordController;
  TextEditingController? _userconfirmPasswordController;
  TextEditingController? _userphoneController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    user = Provider.of<UserProvider>(context, listen: false).getUser;
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    user = Provider.of<UserProvider>(context, listen: false).getUser;

    _usernameController = TextEditingController(text: user!.displayName);
    _userEmailController = TextEditingController(text: user!.email);
    _userphoneController = TextEditingController(text: user!.phoneNumber);
    _userpasswordController = TextEditingController();
    _userconfirmPasswordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: Card(
        margin: const EdgeInsets.all(16),
        elevation: 5,
        color: Theme.of(context).cardColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.5)
                  : Colors.black.withOpacity(0.2),
            )),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 580,
                  child: ListView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _usernameController,
                              enabled: isEditing,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _userEmailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: isEditing,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _userphoneController,
                              keyboardType: TextInputType.phone,
                              enabled: isEditing,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isEditing)
                            Column(
                              children: [
                                SizedBox(
                                  height: 50,
                                  child: TextField(
                                    controller: _userpasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 50,
                                  child: TextField(
                                    controller: _userconfirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm Password',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // edit and save button
                if (isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                          });
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await const CommonMethods()
                              .checkConnectivity(context);
                          if (context.mounted) {
                            showDialog(
                                context: context,
                                builder: (ctx) => const LoadingDialog(
                                    messageText: 'Updating profile...'));
                          }
                          // update user profile
                          // check if the user is updating the password
                          if (_userpasswordController!.text.isNotEmpty &&
                              _userconfirmPasswordController!.text.isNotEmpty) {
                            if (_userpasswordController!.text !=
                                _userconfirmPasswordController!.text) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                await showDialog(
                                    context: context,
                                    builder: (context) => const InfoDialog(
                                        title: 'Error',
                                        content:
                                            'Password and Confirm Password do not match.'));
                              }
                              return;
                            }

                            await user!
                                .updatePassword(_userpasswordController!.text);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            if (context.mounted) {
                              await showDialog(
                                  context: context,
                                  builder: (context) => const InfoDialog(
                                      title: 'Notice',
                                      content:
                                          'Password updated successfully. \n You will be logged out now.\n Please login again with your new password.'));
                            }

                            await Future.delayed(const Duration(seconds: 3));

                            await AuthMethods().signoutUser();

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            return;
                          }

                          if (_userEmailController!.text != user!.email) {
                            await user!.updateEmail(_userEmailController!.text);

                            if (context.mounted) {
                              await showDialog(
                                  context: context,
                                  builder: (context) => const InfoDialog(
                                      title: 'Notice',
                                      content:
                                          'Email updated successfully. \n You will be logged out now.\n Please verify your new email address to login again.'));
                            }

                            await Future.delayed(const Duration(seconds: 3));

                            await AuthMethods().signoutUser();

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }

                          if (_usernameController!.text != user!.displayName) {
                            await user!.updateProfile(
                                displayName: _usernameController!.text);
                          }

                          if (_userphoneController!.text != user!.phoneNumber) {
                            await user!.updateProfile(
                                phoneNumber: _userphoneController!.text);
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (context.mounted) {
                            Provider.of<UserProvider>(context, listen: false)
                                .setUser = user!;
                          }

                          if (context.mounted) {
                            showDialog(
                                context: context,
                                builder: (context) => const InfoDialog(
                                    title: 'Success',
                                    content: 'Profile updated successfully.'));
                          }

                          setState(() {
                            isEditing = false;
                          });
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                if (!isEditing)
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => const InfoDialog(
                              title: 'Notice',
                              content:
                                  'To change your email or password, you must update them individually.\n Other profile details can be modified together in a single update.'));
                      setState(() {
                        isEditing = true;
                      });
                    },
                    child: const Text('Edit'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
