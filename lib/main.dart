import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  bool isTengeToCurrency = false;
  double? total, cashBack, roundedUpTotal, additionalAmountNeeded;
  final NumberFormat numberFormat = NumberFormat("#,###", "ru_RU");

  @override
  void initState() {
    super.initState();
    amountController.addListener(calculate);
    rateController.addListener(calculate);
  }

  @override
  void dispose() {
    amountController.removeListener(calculate);
    rateController.removeListener(calculate);
    amountController.dispose();
    rateController.dispose();
    super.dispose();
  }

  String cleanInput(String text) {
    return text.replaceAll(" ", "").replaceAll(",", ".");
  }

  void calculate() {
    double amount = double.tryParse(cleanInput(amountController.text)) ?? 0;
    double rate =
        double.tryParse(rateController.text.replaceAll(",", ".")) ?? 1;
    if (amount > 0 && rate > 0) {
      setState(() {
        double rawTotal = amount / rate;
        double roundedTotal = (rawTotal ~/ 100) * 100;
        double roundedUp = ((rawTotal + 99) ~/ 100) * 100;
        double remainingTenge = (roundedUp - rawTotal) * rate;
        total = roundedTotal;
        cashBack = (rawTotal - roundedTotal) * rate;
        roundedUpTotal = roundedUp;
        additionalAmountNeeded = remainingTenge;
      });
    } else {
      setState(() {
        total = null;
        cashBack = null;
        roundedUpTotal = null;
        additionalAmountNeeded = null;
      });
    }
  }

  String formatNumber(double? value) {
    if (value == null) return "0";
    return numberFormat.format(value);
  }

  String formatTengeInput(String text) {
    String cleaned = cleanInput(text);
    if (cleaned.isEmpty) return "";
    int length = cleaned.length;

    if (length > 8) return cleaned;

    List<String> parts = [];
    for (int i = length; i > 0; i -= 3) {
      int start = (i - 3) > 0 ? i - 3 : 0;
      parts.insert(0, cleaned.substring(start, i));
    }

    return parts.join(" ");
  }

  void navigateToRoundUpPage() {
    if (roundedUpTotal != null && additionalAmountNeeded != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoundUpScreen(
            roundedUpTotal: roundedUpTotal!,
            additionalAmountNeeded: additionalAmountNeeded!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Курс обмена валют'),
        actions: [
          if (roundedUpTotal != null)
            TextButton(
              onPressed: navigateToRoundUpPage,
              child: Text('Поднять до ${formatNumber(roundedUpTotal)}'),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Сумма в тенге'),
              onChanged: (value) {
                String formatted = formatTengeInput(value);
                amountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Курс'),
            ),
            SizedBox(height: 20),
            if (total != null) ...[
              Text('Сумма: ${formatNumber(total)} \$',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Сдача в тенге: ${formatNumber(cashBack)} тг',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

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

void main() {
  runApp(MaterialApp(home: CurrencyConverterScreen()));
}
