import 'package:flutter/material.dart';

void main() {
  runApp(const AlqadiEducationApp());
}

class AlqadiEducationApp extends StatelessWidget {
  const AlqadiEducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'برنامج محمد القاضي التعليمي العلمي',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('برنامج محمد القاضي التعليمي العلمي'),
          centerTitle: true,
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _item('إنشاء اختبار', Icons.edit_document),
            _item('الصفوف الدراسية', Icons.school),
            _item('المواد الدراسية', Icons.menu_book),
            _item('اختباراتي', Icons.folder),
            _item('معاينة الاختبار', Icons.preview),
            _item('الإعدادات', Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, IconData icon) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
