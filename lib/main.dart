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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F9),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('إنشاء اختبار', Icons.edit_note, const CreateExamPage()),
      ('الصفوف الدراسية', Icons.school, const GradesPage()),
      ('المواد الدراسية', Icons.menu_book, const SubjectsPage()),
      ('اختباراتي', Icons.folder_copy, const MyExamsPage()),
      ('معاينة الاختبار', Icons.preview, const PreviewPage()),
      ('الإعدادات', Icons.settings, const SettingsPage()),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'برنامج محمد القاضي التعليمي العلمي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.$3),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$2, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      item.$1,
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
          },
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const SimplePage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateExamPage extends StatelessWidget {
  const CreateExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'إنشاء اختبار',
      message: 'هنا سيتم إنشاء الاختبار وإضافة الأسئلة.',
      icon: Icons.edit_note,
    );
  }
}

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'الصفوف الدراسية',
      message: 'الصفوف من 1 إلى 12 ستكون هنا.',
      icon: Icons.school,
    );
  }
}

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'المواد الدراسية',
      message: 'جميع المواد الدراسية ستكون هنا.',
      icon: Icons.menu_book,
    );
  }
}

class MyExamsPage extends StatelessWidget {
  const MyExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'اختباراتي',
      message: 'ستظهر الاختبارات المحفوظة هنا.',
      icon: Icons.folder_copy,
    );
  }
}

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'معاينة الاختبار',
      message: 'ستظهر معاينة الاختبار هنا.',
      icon: Icons.preview,
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'الإعدادات',
      message: 'إعدادات البرنامج ستكون هنا.',
      icon: Icons.settings,
    );
  }
}
