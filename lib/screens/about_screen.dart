import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/logo-cigma-scroll.svg',
                      color: Theme.of(context).primaryColor,
                      height: 100,
                    ),
                    Image.asset(
                      'assets/images/logo_white_borders.png',
                      height: 100,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // app title
                Text(
                  'About CarGo',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 20),
                Divider(
                  color: Theme.of(context).primaryColor,
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to CarGo, the convenient and reliable carpooling app designed to make your trips easier and more affordable. '
                  'Whether you\'re commuting to work, traveling across the city, or just need a quick ride, CarGo connects you with available drivers nearby, '
                  'offering a seamless experience from start to finish.\n\n'
                  'Key Features:\n'
                  '- Easy Place Search: Find your destination quickly using our map-based search.\n'
                  '- Transparent Pricing: Instantly get an estimated trip cost before you book.\n'
                  '- Real-Time Tracking: Track your driver\'s location from the moment they accept your ride request to your final destination.\n'
                  '- Pay in Cash: No need for online payments – simply pay your driver in cash once your trip is complete.\n\n'
                  'With CarGo, you have the flexibility and convenience to travel on your own terms. Enjoy a stress-free, cash-based carpooling experience!\n\n'
                  'For more information or support, please contact the developer directly by email. Thank you for choosing CarGo!',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 20,
                      ),
                  textAlign:
                      TextAlign.start, // Align text properly for readability
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Developed by:',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                        onPressed: () async {
                          final Uri params = Uri(
                            scheme: 'mailto',
                            path: 'ammarsultan1445@gmail.com',
                            query:
                                'subject=CarGo Request Info &body=Please provide further information.',
                          );

                          String url = params.toString();
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            if (kDebugMode) {
                              print('Could not launch $url');
                            }
                          }
                        },
                        child: Text(
                          'Ammar Sultan',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
