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
        fontFamily: 'sans',
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
            _item(context, 'إنشاء اختبار', Icons.edit_document),
            _item(context, 'الصفوف الدراسية', Icons.school),
            _item(context, 'المواد الدراسية', Icons.menu_book),
            _item(context, 'اختباراتي', Icons.folder),
            _item(context, 'معاينة الاختبار', Icons.preview),
            _item(context, 'إعدادات', Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon) {
