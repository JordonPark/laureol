import 'package:flutter/widgets.dart';

void main() => runApp(const LaureolApp());

class LaureolApp extends StatelessWidget {
  const LaureolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: '라우럴! 볼륨 좀 올려',
      color: const Color(0xFF171329),
      builder: (context, child) => const ColoredBox(
        color: Color(0xFF171329),
        child: SafeArea(
          child: Center(
            child: Text(
              '라우럴! 볼륨 좀 올려',
              style: TextStyle(
                color: Color(0xFFF7F2FF),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
