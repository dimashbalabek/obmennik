import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

// Модель валютного курса
class CurrencyRate {
  final String currency;
  final String buy;
  final String sell;

  CurrencyRate({
    required this.currency,
    required this.buy,
    required this.sell,
  });
}

class CurrencyDashboard extends StatefulWidget {
  const CurrencyDashboard({Key? key}) : super(key: key);

  @override
  State<CurrencyDashboard> createState() => _CurrencyDashboardState();
}

class _CurrencyDashboardState extends State<CurrencyDashboard> {
  List<CurrencyRate> _rates = [];

  @override
  void initState() {
    super.initState();
    fetchCurrencyRates();
  }

  // Новая функция для получения и парсинга данных
  Future<void> fetchCurrencyRates() async {
    final url = Uri.parse(
        "https://frosty-hat-108d.dimashbalabek0.workers.dev/?target=https://mig.kz/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var document = html.parse(response.body);
      // Получаем весь текст из body
      var currencyData = document.body?.text ?? "";

      RegExp regExp = RegExp(
        r"(\d+\.\d+)\s*USD\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*EUR\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*RUB\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*KGS\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*GBP\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*CNY\s*(\d+\.\d+)\s*"
        r"(\d+\.\d+)\s*GOLD\s*(\d+\.\d+)",
        multiLine: true,
      );

      var match = regExp.firstMatch(currencyData);
      if (match != null) {
        List<CurrencyRate> newRates = [];

        newRates.add(CurrencyRate(
            currency: "USD", buy: match.group(1)!, sell: match.group(2)!));
        newRates.add(CurrencyRate(
            currency: "EUR", buy: match.group(3)!, sell: match.group(4)!));
        newRates.add(CurrencyRate(
            currency: "RUB", buy: match.group(5)!, sell: match.group(6)!));
        newRates.add(CurrencyRate(
            currency: "KGS", buy: match.group(7)!, sell: match.group(8)!));
        newRates.add(CurrencyRate(
            currency: "GBP", buy: match.group(9)!, sell: match.group(10)!));
        newRates.add(CurrencyRate(
            currency: "CNY", buy: match.group(11)!, sell: match.group(12)!));
        newRates.add(CurrencyRate(
            currency: "GOLD", buy: match.group(13)!, sell: match.group(14)!));

        setState(() {
          _rates = newRates;
        });
      } else {
        debugPrint("Не удалось найти курсы валют.");
      }
    } else {
      debugPrint("Ошибка запроса: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF00472C);

    return Scaffold(
      // Градиентный фон для всего экрана
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mainColor,
              Color(0xFF02633A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: fetchCurrencyRates,
          color: mainColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // SliverAppBar с уменьшенной высотой 100
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 100,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Center(
                    child: Text(
                      "ZAMAN",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              _rates.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final rate = _rates[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Icon(
                                    Icons.monetization_on,
                                    color: Colors.indigo.shade700,
                                    size: 30,
                                  ),
                                ),
                                title: Text(
                                  rate.currency,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        rate.buy,
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        rate.sell,
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _rates.length,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: CurrencyDashboard(),
//   ));
// }
