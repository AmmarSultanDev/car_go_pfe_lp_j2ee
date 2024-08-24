import 'package:car_go_pfe_lp_j2ee/models/prediction.dart';
import 'package:flutter/material.dart';

class PredictionPlaceUi extends StatefulWidget {
  PredictionPlaceUi({super.key, this.prediction});

  Prediction? prediction;

  @override
  State<PredictionPlaceUi> createState() => _PredictionPlaceUiState();
}

class _PredictionPlaceUiState extends State<PredictionPlaceUi> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.share_location),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.prediction!.main_text!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.prediction!.secondary_text!,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ));
  }
}
