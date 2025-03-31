import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:untitled1/curse.dart';
import 'package:untitled1/rounded_sreen.dart';

/// Formatter для поля суммы в тенге, который визуально разбивает число на группы по 3 цифры
/// (например, 1234 -> "1 234", 12345 -> "12 345", 1234567 -> "1 234 567").
class TengeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Убираем пробелы
    String digits = newValue.text.replaceAll(" ", "");
    if (digits.isEmpty) return newValue.copyWith(text: "");

    // Если цифр меньше 4, форматировать не нужно.
    if (digits.length < 4) {
      return TextEditingValue(
        text: digits,
        selection: newValue.selection,
      );
    }

    // Форматирование по группам по 3 цифры с конца
    StringBuffer buffer = StringBuffer();
    int offset = digits.length % 3;
    if (offset == 0) offset = 3;
    buffer.write(digits.substring(0, offset));
    for (int i = offset; i < digits.length; i += 3) {
      buffer.write(" ");
      buffer.write(digits.substring(i, i + 3));
    }
    String formatted = buffer.toString();

    // Рассчитываем позицию курсора
    int newCursorPosition =
        formatted.length - (digits.length - newValue.selection.end);
    if (newCursorPosition < 0) newCursorPosition = 0;
    if (newCursorPosition > formatted.length)
      newCursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}

/// Основной виджет с переключением между страницами.
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Индекс выбранной страницы: 0 — Конвертер валют, 1 — Курсы.
  int _currentIndex = 0;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  bool isTengeToCurrency = true;
  double? total, cashBack, roundedUpTotal, additionalAmountNeeded;
  final NumberFormat numberFormat = NumberFormat("#,###", "ru_RU");

  @override
  void initState() {
    super.initState();
    amountController.addListener(validateAndCalculate);
    rateController.addListener(validateAndCalculate);
  }

  @override
  void dispose() {
    amountController.removeListener(validateAndCalculate);
    rateController.removeListener(validateAndCalculate);
    amountController.dispose();
    rateController.dispose();
    super.dispose();
  }

  void validateAndCalculate() {
    String amountText =
        amountController.text.replaceAll(",", ".").replaceAll(" ", "");
    String rateText =
        rateController.text.replaceAll(",", ".").replaceAll(" ", "");

    double? amount = double.tryParse(amountText);
    double? rate = double.tryParse(rateText);

    if (amount == null || amount == 0 || rate == null || rate == 0) {
      setState(() {
        total = cashBack = roundedUpTotal = additionalAmountNeeded = null;
      });
      return;
    }
    calculate(amount, rate);
  }

  void calculate(double amount, double rate) {
    setState(() {
      if (isTengeToCurrency) {
        double rawTotal = amount / rate;
        double roundedTotal = (rawTotal / 100).floor() * 100;
        double roundedUp = ((rawTotal + 99) / 100).floor() * 100;
        double remainingTenge = (roundedUp - rawTotal) * rate;

        total = roundedTotal;
        cashBack = (rawTotal - roundedTotal) * rate;
        roundedUpTotal = roundedUp;
        additionalAmountNeeded = remainingTenge;
      } else {
        total = amount * rate;
        cashBack = null;
        roundedUpTotal = null;
        additionalAmountNeeded = null;
      }
    });
  }

  String formatNumber(double? value) {
    return value == null ? "0" : numberFormat.format(value);
  }

  Widget buildConversionPage() {
    bool insufficient = isTengeToCurrency && (total != null && total == 0);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ToggleButtons(
              isSelected: [isTengeToCurrency, !isTengeToCurrency],
              onPressed: (index) {
                setState(() {
                  isTengeToCurrency = index == 0;
                  amountController.clear();
                  total = null;
                });
              },
              children: [
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Клиент дает тенге')),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Клиент дает валюту')),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [TengeInputFormatter()],
              decoration: InputDecoration(
                labelText:
                    isTengeToCurrency ? 'Сумма в тенге' : 'Сумма в валюте',
              ),
            ),
            TextField(
              controller: rateController,
              decoration: InputDecoration(labelText: 'Курс'),
            ),
            SizedBox(height: 20),
            if (total != null)
              insufficient
                  ? Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          'Суммма не хватает. НЕ можем дат тенге/валюту',
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTengeToCurrency
                              ? 'Сумма: ${formatNumber(total)} \$'
                              : 'Сумма в тенге: ${formatNumber(total)} тг',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (cashBack != null)
                          Text(
                            'Сдача в тенге: ${formatNumber(cashBack)} тг',
                            style: TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Widget buildOtherPage() {
    return CurrencyDashboard();
  }

  @override
  Widget build(BuildContext context) {
    bool insufficient = isTengeToCurrency && (total != null && total == 0);

    // Если условия конвертации выполнены, формируем кнопку "Поднять до ..."
    Widget? liftUpButton;
    if (_currentIndex == 0 &&
        !insufficient &&
        isTengeToCurrency &&
        roundedUpTotal != null) {
      liftUpButton = TextButton(
        onPressed: () {
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
        },
        child: Text('Поднять до ${formatNumber(roundedUpTotal)}'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Конвертер валют' : 'Курсы'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            child: Text(
              'Конвертер валют',
              style: TextStyle(
                  color: _currentIndex == 0 ? Colors.white : Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            child: Text(
              'Курсы',
              style: TextStyle(
                  color: _currentIndex == 1 ? Colors.white : Colors.white70),
            ),
          ),
          if (liftUpButton != null) liftUpButton,
        ],
      ),
      body: _currentIndex == 0 ? buildConversionPage() : buildOtherPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_exchange), label: 'Конвертер валют'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Курсы'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0 && liftUpButton != null
          ? FloatingActionButton.extended(
              onPressed: () {
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
              },
              label: Text('Поднять до ${formatNumber(roundedUpTotal)}'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainScreen(),
  ));
}
