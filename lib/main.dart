import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AlqadiEducationApp());

const grades = ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'];
const subjects = ['الكيمياء', 'الفيزياء', 'الأحياء'];

class Lesson {
  Lesson({required this.title, required this.body, required this.grade, required this.subject, this.filePath});
  final String title;
  final String body;
  final String grade;
  final String subject;
  final String? filePath;

  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'grade': grade, 'subject': subject, 'filePath': filePath};
  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    grade: json['grade'] as String? ?? grades.first,
    subject: json['subject'] as String? ?? subjects.first,
    filePath: json['filePath'] as String?,
  );
}

class AlqadiEducationApp extends StatelessWidget {
  const AlqadiEducationApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'برنامج محمد القاضي التعليمي العلمي',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b5b)), useMaterial3: true),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lesson> lessons = [];
  String selectedGrade = grades.first;
  String selectedSubject = subjects.first;
  bool teacherMode = false;
  final teacherCode = TextEditingController();

  @override
  void initState() { super.initState(); _loadLessons(); }
  @override
  void dispose() { teacherCode.dispose(); super.dispose(); }

  Future<void> _loadLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('lessons') ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      if (mounted) setState(() => lessons = decoded.map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map))).toList());
    } catch (_) {}
  }

  Future<void> _saveLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lessons', jsonEncode(lessons.map((e) => e.toJson()).toList()));
  }

  Future<void> _openTeacher() async {
    final code = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('دخول المعلم'),
      content: TextField(controller: teacherCode, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز المعلم التجريبي')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, teacherCode.text.trim()), child: const Text('دخول')),
      ],
    ));
    if (code == '1234' && mounted) setState(() => teacherMode = true);
    else if (code != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز غير صحيح. الرمز التجريبي هو 1234')));
  }

  Future<void> _addLesson() async {
    final title = TextEditingController();
    final body = TextEditingController();
    String grade = selectedGrade;
    String subject = selectedSubject;
    String? filePath;
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
      title: const Text('إضافة درس جديد'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الدرس')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: grade, decoration: const InputDecoration(labelText: 'الصف'), items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => refresh(() => grade = v ?? grade)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: subject, decoration: const InputDecoration(labelText: 'المادة'), items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => refresh(() => subject = v ?? subject)),
        const SizedBox(height: 8),
        TextField(controller: body, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'شرح الدرس', alignLabelWithHint: true)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () async { final result = await FilePicker.platform.pickFiles(); if (result != null) refresh(() => filePath = result.files.single.path); }, icon: const Icon(Icons.attach_file), label: Text(filePath == null ? 'إرفاق ملف (اختياري)' : 'تم اختيار ملف')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ الدرس'))],
    )));
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() => lessons.insert(0, Lesson(title: title.text.trim(), body: body.text.trim(), grade: grade, subject: subject, filePath: filePath)));
      await _saveLessons();
    }
    title.dispose(); body.dispose();
  }

  Future<void> _saveLessonOffline(Lesson lesson) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = lesson.title.replaceAll(RegExp(r'[^\w\- ء-ي]'), '_');
    final file = File('${dir.path}/${safeTitle.isEmpty ? 'lesson' : safeTitle}.txt');
    await file.writeAsString('${lesson.title}\n${lesson.grade} - ${lesson.subject}\n\n${lesson.body}');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ الدرس داخل التطبيق: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    final visible = lessons.where((l) => l.grade == selectedGrade && l.subject == selectedSubject).toList();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('محمد القاضي | التعليم العلمي'), actions: [
        if (teacherMode) IconButton(tooltip: 'إضافة درس', onPressed: _addLesson, icon: const Icon(Icons.add_circle_outline)),
        IconButton(tooltip: teacherMode ? 'إنهاء وضع المعلم' : 'دخول المعلم', onPressed: () => teacherMode ? setState(() => teacherMode = false) : _openTeacher(), icon: Icon(teacherMode ? Icons.admin_panel_settings : Icons.person_outline)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مرحباً بك في برنامج محمد القاضي التعليمي العلمي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('اختر صفك ومادتك للوصول إلى الدروس والمواد التعليمية.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: selectedGrade, decoration: const InputDecoration(labelText: 'الصف الدراسي', border: OutlineInputBorder()), items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => selectedGrade = v ?? selectedGrade)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: subjects.map((s) => ChoiceChip(label: Text(s), selected: selectedSubject == s, onSelected: (_) => setState(() => selectedSubject = s)).toList()),
        ]))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: Text('دروس ${selectedSubject} - ${selectedGrade}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), if (teacherMode) const Chip(label: Text('وضع المعلم'))]),
        if (visible.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('لا توجد دروس مضافة لهذه المادة بعد.')))),
        ...visible.map((lesson) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.menu_book)),
          title: Text(lesson.title),
          subtitle: Text(lesson.body.isEmpty ? (lesson.filePath == null ? 'لا يوجد شرح نصي' : 'يوجد ملف مرفق') : lesson.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(onSelected: (v) async {
            if (v == 'save') await _saveLessonOffline(lesson);
            if (v == 'delete' && teacherMode) { setState(() => lessons.remove(lesson)); await _saveLessons(); }
          }, itemBuilder: (_) => [const PopupMenuItem(value: 'save', child: Text('حفظ الدرس للاستخدام دون إنترنت')), if (teacherMode) const PopupMenuItem(value: 'delete', child: Text('حذف الدرس'))]),
          onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(lesson.title), content: SingleChildScrollView(child: Text(lesson.body.isEmpty ? 'لا يوجد شرح نصي لهذا الدرس.' : lesson.body)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]),
        ))),
        const SizedBox(height: 12),
        const Text('أقسام قيد التطوير: الكتب والملازم، الاختبارات، النتائج، ولوحة الشرف.', style: TextStyle(color: Colors.black54)),
      ]),
      floatingActionButton: teacherMode ? FloatingActionButton.extended(onPressed: _addLesson, icon: const Icon(Icons.add), label: const Text('إضافة درس')) : null,
    ));
  }
}
