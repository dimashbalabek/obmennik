import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
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
    _fetchData();
  }

  // Функция для получения и парсинга данных
  Future<void> _fetchData() async {
    try {
      final url = Uri.parse("https://mig.kz/");
      final response = await http.get(url);
      dom.Document html = dom.Document.html(response.body);

      final table = html.querySelector('table');
      if (table == null) {
        debugPrint("Таблица не найдена!");
        return;
      }
      final rows = table.querySelectorAll('tr');
      List<CurrencyRate> tempRates = [];

      for (var row in rows) {
        final buyTd = row.querySelector('td.buy');
        final currencyTd = row.querySelector('td.currency');
        final sellTd = row.querySelector('td.sell');

        if (buyTd != null && currencyTd != null && sellTd != null) {
          final buyValue = buyTd.text.trim();
          final currencyValue = currencyTd.text.trim();
          final sellValue = sellTd.text.trim();

          // Исключаем ненужные валюты
          if (currencyValue == 'KGS' ||
              currencyValue == 'GBP' ||
              currencyValue == 'GOLD') {
            continue;
          }

          tempRates.add(
            CurrencyRate(
              currency: currencyValue,
              buy: buyValue,
              sell: sellValue,
            ),
          );
        }
      }

      setState(() {
        _rates = tempRates;
      });
    } catch (e) {
      debugPrint("Ошибка при получении данных: $e");
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
          onRefresh: _fetchData,
          color: mainColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Уменьшенная высота SliverAppBar до 100,
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
                                      // Icon(Icons.arrow_upward,
                                      //     color: Colors.green.shade700,
                                      //     size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        rate.buy,
                                        style: TextStyle(
                                          fontSize: 16,
                                          // color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Icon(Icons.arrow_downward,
                                      //     color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        rate.sell,
                                        style: TextStyle(
                                          fontSize: 16,
                                          // color: Colors.red.shade700,
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
