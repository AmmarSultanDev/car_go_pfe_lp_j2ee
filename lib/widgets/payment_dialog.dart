import 'package:car_go_pfe_lp_j2ee/global/trip_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/firestore_methods.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.tripId});

  final String tripId; // Added semicolon here

  @override
  State<PaymentDialog> createState() {
    return _PaymentDialogState();
  }
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods commonMethods = const CommonMethods();
  FirestoreMethods firestoreMethods = FirestoreMethods();

  paymentCheck() async {
    if (mounted) {
      showDialog(
          context: context,
          builder: (context) =>
              const LoadingDialog(messageText: 'Collecting payment...'));
    }

    bool paymentStatus =
        await firestoreMethods.checkPaymentStatus(widget.tripId);

    if (mounted) Navigator.of(context).pop();

    if (paymentStatus) {
      if (mounted) {
        commonMethods.displaySnackBar(
            'Payment collected successfully.', context);
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        commonMethods.displaySnackBar('Payment not collected.', context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 21,
            ),
            Text(
              'Payment',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(
              height: 21,
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
              thickness: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              '\$ $fareAmount',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Please pay the fare amount of \$ $fareAmount to the driver.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(
              height: 21,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      paymentCheck();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
