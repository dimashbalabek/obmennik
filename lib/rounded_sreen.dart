import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoundUpScreen extends StatelessWidget {
  final double roundedUpTotal;
  final double additionalAmountNeeded;

  RoundUpScreen({
    required this.roundedUpTotal,
    required this.additionalAmountNeeded,
  });

  final NumberFormat numberFormat = NumberFormat("#,###", "ru_RU");

  String formatNumber(double value) {
    return numberFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Округление суммы')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Поднимаем до ${formatNumber(roundedUpTotal)} \$',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Клиент еще должен дать ${formatNumber(additionalAmountNeeded)} тг',
              style: TextStyle(
                  fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
