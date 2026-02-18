import 'package:flutter/material.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Управление инструментами',
      'description': 'Легко добавляйте, редактируйте и отслеживайте все ваши строительные инструменты',
      'icon': Icons.build,
      'color': Colors.blue
    },
    {
      'title': 'Работа с объектами',
      'description': 'Создавайте объекты и перемещаете инструменты между гаражом и объектами',
      'icon': Icons.location_city,
      'color': Colors.orange
    },
    {
      'title': 'Отчеты и PDF',
      'description': 'Создавайте подробные отчеты и делитесь ими с коллегами',
      'icon': Icons.picture_as_pdf,
      'color': Colors.green
    },
    {
      'title': 'Работа офлайн',
      'description': 'Продолжайте работу даже без интернета, данные синхронизируются автоматически',
      'icon': Icons.wifi_off,
      'color': Colors.purple
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    widget.onComplete();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()));
                  },
                  child: Text('Пропустить',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: p['color'].withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(p['icon'], size: 70, color: p['color']),
                          ),
                          const SizedBox(height: 40),
                          Text(p['title'],
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          Text(p['description'],
                              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    ...List.generate(_pages.length, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == i
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                          ),
                        )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else {
                          widget.onComplete();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()));
                        }
                      },
                      child: Text(_currentPage == _pages.length - 1 ? 'Начать' : 'Далее'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
