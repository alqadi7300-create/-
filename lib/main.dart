import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const QadiApp());
}

class QadiApp extends StatelessWidget {
  const QadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'برنامج محمد القاضي التعليمي العلمي',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorSchemeSeed: Colors.indigo,
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
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.school,
              size: 90,
            ),
            const SizedBox(height: 20),
            const Text(
              'ادعم التعليم فالتعليم للجميع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _homeButton(
              context,
              'دخول الطالب',
              Icons.person,
              const StudentLoginPage(),
            ),
            const SizedBox(height: 15),
            _homeButton(
              context,
              'دخول المعلم',
              Icons.admin_panel_settings,
              const TeacherLoginPage(),
            ),
            const SizedBox(height: 15),
            _homeButton(
              context,
              'عن الأستاذ محمد القاضي',
              Icons.info_outline,
              const TeacherBioPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
// ================= بيانات التطبيق =================

const String teacherPassword = '774470090';

const List<String> grades = [
  'الأول الثانوي',
  'الثاني الثانوي',
  'الثالث الثانوي',
];

const List<String> subjects = [
  'الكيمياء',
  'الفيزياء',
  'الأحياء',
];

// ================= أدوات التخزين =================

class AppStorage {
  static Future<SharedPreferences> get prefs async {
    return SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> getStudents() async {
    final p = await prefs;
    final data = p.getString('students');

    if (data == null || data.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      jsonDecode(data).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> saveStudents(
    List<Map<String, dynamic>> students,
  ) async {
    final p = await prefs;
    await p.setString('students', jsonEncode(students));
  }

  static Future<List<Map<String, dynamic>>> getBooks() async {
    final p = await prefs;
    final data = p.getString('books');

    if (data == null || data.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      jsonDecode(data).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> saveBooks(
    List<Map<String, dynamic>> books,
  ) async {
    final p = await prefs;
    await p.setString('books', jsonEncode(books));
  }

  static Future<List<Map<String, dynamic>>> getExams() async {
    final p = await prefs;
    final data = p.getString('exams');

    if (data == null || data.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      jsonDecode(data).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> saveExams(
    List<Map<String, dynamic>> exams,
  ) async {
    final p = await prefs;
    await p.setString('exams', jsonEncode(exams));
  }

  static Future<List<Map<String, dynamic>>> getResults() async {
    final p = await prefs;
    final data = p.getString('results');

    if (data == null || data.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      jsonDecode(data).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> saveResults(
    List<Map<String, dynamic>> results,
  ) async {
    final p = await prefs;
    await p.setString('results', jsonEncode(results));
  }
}// ================= دخول الطالب =================

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final codeController = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> login() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        error = 'أدخل كود الطالب';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    final students = await AppStorage.getStudents();

    Map<String, dynamic>? student;

    for (final item in students) {
      if (item['code'].toString() == code) {
        student = item;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (student == null) {
      setState(() {
        error = 'كود الطالب غير صحيح';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentHomePage(
          student: student!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دخول الطالب'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.person,
                size: 90,
              ),
              const SizedBox(height: 25),
              TextField(
                controller: codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'كود الطالب',
                  hintText: 'أدخل الكود الخاص بك',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 15),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'دخول',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}

// ================= الصفحة الرئيسية للطالب =================

class StudentHomePage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final name = student['name']?.toString() ?? 'الطالب';
    final grade = student['grade']?.toString() ?? 'غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بوابة الطالب'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(
                        Icons.person,
                        size: 45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('الصف: $grade'),
                    Text(
                      'الكود: ${student['code']}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            _button(
              context,
              'الكتب والمذكرات',
              Icons.menu_book,
              SubjectPage(
                grade: grade,
                student: student,
              ),
            ),
            const SizedBox(height: 12),
            _button(
              context,
              'الاختبارات',
              Icons.assignment,
              ExamPage(
                grade: grade,
                student: student,
              ),
            ),
            const SizedBox(height: 12),
            _button(
              context,
              'درجاتي السابقة',
              Icons.bar_chart,
              ResultsPage(
                student: student,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}
// ================= المواد =================

class SubjectPage extends StatelessWidget {
  final String grade;
  final Map<String, dynamic> student;

  const SubjectPage({
    super.key,
    required this.grade,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('مواد $grade'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'اختر المادة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...subjects.map(
              (subject) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfBookPage(
                            grade: grade,
                            subject: subject,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: Text(
                      subject,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ملفات PDF =================

class PdfBookPage extends StatefulWidget {
  final String grade;
  final String subject;

  const PdfBookPage({
    super.key,
    required this.grade,
    required this.subject,
  });

  @override
  State<PdfBookPage> createState() => _PdfBookPageState();
}

class _PdfBookPageState extends State<PdfBookPage> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final allBooks = await AppStorage.getBooks();

    final filtered = allBooks.where((book) {
      return book['grade'].toString() == widget.grade &&
          book['subject'].toString() == widget.subject;
    }).toList();

    if (!mounted) return;

    setState(() {
      books = filtered;
      loading = false;
    });
  }

  Future<void> openPdf(Map<String, dynamic> book) async {
    final path = book['path']?.toString();

    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ملف PDF غير موجود'),
        ),
      );
      return;
    }

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: book['title'].toString(),
          bytes: bytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subject),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : books.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد كتب أو مذكرات مضافة حاليًا',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            size: 35,
                          ),
                          title: Text(
                            book['title']?.toString() ?? 'ملف PDF',
                          ),
                          subtitle: Text(
                            book['subject']?.toString() ?? '',
                          ),
                          trailing: const Icon(
                            Icons.arrow_back_ios,
                          ),
                          onTap: () => openPdf(book),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ================= عارض PDF =================

class PdfViewerPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: PdfPreview(
          build: (format) async => bytes,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: title.endsWith('.pdf')
              ? title
              : '$title.pdf',
        ),
      ),
    );
  }
// ================= صفحة الاختبارات =================

class ExamPage extends StatefulWidget {
  final String grade;
  final Map<String, dynamic> student;

  const ExamPage({
    super.key,
    required this.grade,
    required this.student,
  });

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  List<Map<String, dynamic>> exams = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExams();
  }

  Future<void> loadExams() async {
    final allExams = await AppStorage.getExams();

    final filtered = allExams.where((exam) {
      return exam['grade'].toString() == widget.grade;
    }).toList();

    if (!mounted) return;

    setState(() {
      exams = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الاختبارات'),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : exams.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد اختبارات متاحة حاليًا',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.assignment,
                            size: 35,
                          ),
                          title: Text(
                            exam['title']?.toString() ?? 'اختبار',
                          ),
                          subtitle: Text(
                            '${exam['subject'] ?? ''} - ${exam['questions']?.length ?? 0} أسئلة',
                          ),
                          trailing: const Icon(
                            Icons.arrow_back_ios,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TakeExamPage(
                                  exam: exam,
                                  student: widget.student,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ================= أداء الاختبار =================

class TakeExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> student;

  const TakeExamPage({
    super.key,
    required this.exam,
    required this.student,
  });

  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage> {
  final Map<int, int> answers = {};
  bool saving = false;

  Future<void> submitExam() async {
    if (saving) return;

    final questions = List<Map<String, dynamic>>.from(
      widget.exam['questions'] ?? [],
    );

    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];
      final correct = int.tryParse(
        questions[i]['correct'].toString(),
      );

      if (selected != null && selected == correct) {
        score++;
      }
    }

    setState(() {
      saving = true;
    });

    final results = await AppStorage.getResults();

    results.add({
      'id': const Uuid().v4(),
      'studentCode': widget.student['code'].toString(),
      'studentName': widget.student['name'].toString(),
      'examTitle': widget.exam['title'].toString(),
      'subject': widget.exam['subject'].toString(),
      'score': score,
      'total': questions.length,
      'date': DateTime.now().toIso8601String(),
    });

    await AppStorage.saveResults(results);

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم إنهاء الاختبار'),
        content: Text(
          'درجتك: $score من ${questions.length}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final questions = List<Map<String, dynamic>>.from(
      widget.exam['questions'] ?? [],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.exam['title']?.toString() ?? 'الاختبار',
          ),
          centerTitle: true,
        ),
        body: questions.isEmpty
            ? const Center(
                child: Text('لا توجد أسئلة في هذا الاختبار'),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.exam['subject']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'عدد الأسئلة: ${questions.length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    questions.length,
                    (index) {
                      final question = questions[index];

                      final options = List<String>.from(
                        question['options'] ?? [],
                      );

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${question['question']}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...List.generate(
                                options.length,
                                (optionIndex) {
                                  return RadioListTile<int>(
                                    value: optionIndex,
                                    groupValue: answers[index],
                                    title: Text(
                                      options[optionIndex],
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        answers[index] = value!;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submitExam,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        saving
                            ? 'جارٍ حفظ النتيجة...'
                            : 'إنهاء الاختبار وتسليم الإجابات',
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ================= درجات الطالب =================

class ResultsPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const ResultsPage({
    super.key,
    required this.student,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Map<String, dynamic>> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    final allResults = await AppStorage.getResults();

    final filtered = allResults.where((result) {
      return result['studentCode'].toString() ==
          widget.student['code'].toString();
    }).toList();

    filtered.sort(
      (a, b) => b['date'].toString().compareTo(
            a['date'].toString(),
          ),
    );

    if (!mounted) return;

    setState(() {
      results = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('درجاتي السابقة'),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : results.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج محفوظة حتى الآن',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.bar_chart,
                            size: 35,
                          ),
                          title: Text(
                            result['examTitle']?.toString() ??
                                'اختبار',
                          ),
                          subtitle: Text(
                            '${result['subject'] ?? ''}\n'
                            'الدرجة: ${result['score']} من ${result['total']}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
// ================= دخول المعلم =================

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final controller = TextEditingController();
  String error = '';

  void login() {
    if (controller.text.trim() == teacherPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TeacherHomePage(),
        ),
      );
    } else {
      setState(() {
        error = 'رمز المعلم غير صحيح';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دخول المعلم'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.admin_panel_settings,
                size: 90,
              ),
              const SizedBox(height: 25),
              const Text(
                'منطقة المعلم',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز المعلم',
                  hintText: 'أدخل الرمز السري',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 12),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: login,
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'دخول',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ================= لوحة المعلم =================

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المعلم'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 70,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'برنامج محمد القاضي التعليمي العلمي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'إدارة المحتوى والطلاب والاختبارات',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            _teacherButton(
              context,
              'إدارة الطلاب',
              Icons.people,
              const StudentsAdminPage(),
            ),
            const SizedBox(height: 12),
            _teacherButton(
              context,
              'إدارة الكتب والمذكرات',
              Icons.picture_as_pdf,
              const BooksAdminPage(),
            ),
            const SizedBox(height: 12),
            _teacherButton(
              context,
              'إدارة الاختبارات',
              Icons.assignment,
              const ExamsAdminPage(),
            ),
            const SizedBox(height: 12),
            _teacherButton(
              context,
              'نتائج الطلاب',
              Icons.bar_chart,
              const AllResultsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teacherButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return SizedBox(
      height: 60,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}

// ================= إدارة الطلاب =================

class StudentsAdminPage extends StatefulWidget {
  const StudentsAdminPage({super.key});

  @override
  State<StudentsAdminPage> createState() =>
      _StudentsAdminPageState();
}

class _StudentsAdminPageState
    extends State<StudentsAdminPage> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final data = await AppStorage.getStudents();

    if (!mounted) return;

    setState(() {
      students = data;
    });
  }

  String createCode() {
    return DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(5);
  }

  Future<void> addStudent() async {
    final nameController = TextEditingController();
    String selectedGrade = grades.first;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة طالب'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'اسم الطالب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'الصف الدراسي',
                      border: OutlineInputBorder(),
                    ),
                    items: grades
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedGrade = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name =
                        nameController.text.trim();

                    if (name.isEmpty) return;

                    final code = createCode();

                    students.add({
                      'id': const Uuid().v4(),
                      'name': name,
                      'code': code,
                      'grade': selectedGrade,
                    });

                    await AppStorage.saveStudents(
                      students,
                    );

                    if (!mounted) return;

                    setState(() {});

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إنشاء الطالب. الكود: $code',
                        ),
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Future<void> deleteStudent(int index) async {
    final student = students[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text(
          'هل تريد حذف ${student['name']}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    students.removeAt(index);
    await AppStorage.saveStudents(students);

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الطلاب'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: addStudent,
              icon: const Icon(Icons.person_add),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addStudent,
          icon: const Icon(Icons.add),
          label: const Text('إضافة طالب'),
        ),
        body: students.isEmpty
            ? const Center(
                child: Text(
                  'لا يوجد طلاب مضافون حتى الآن',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(
                        student['name'].toString(),
                      ),
                      subtitle: Text(
                        '${student['grade']}\n'
                        'كود الدخول: ${student['code']}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteStudent(index);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
}// ================= إدارة الكتب والمذكرات =================

class BooksAdminPage extends StatefulWidget {
  const BooksAdminPage({super.key});

  @override
  State<BooksAdminPage> createState() => _BooksAdminPageState();
}

class _BooksAdminPageState extends State<BooksAdminPage> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final data = await AppStorage.getBooks();

    if (!mounted) return;

    setState(() {
      books = data;
      loading = false;
    });
  }

  Future<void> addBook() async {
    String selectedGrade = grades.first;
    String selectedSubject = subjects.first;

    final titleController = TextEditingController();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      titleController.dispose();
      return;
    }

    final sourceFile = File(result.files.single.path!);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة كتاب أو مذكرة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الكتاب أو المذكرة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedGrade,
                      decoration: const InputDecoration(
                        labelText: 'الصف الدراسي',
                        border: OutlineInputBorder(),
                      ),
                      items: grades
                          .map(
                            (grade) => DropdownMenuItem(
                              value: grade,
                              child: Text(grade),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedGrade = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'المادة',
                        border: OutlineInputBorder(),
                      ),
                      items: subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    var title = titleController.text.trim();

                    if (title.isEmpty) {
                      title = sourceFile.path.split(Platform.pathSeparator).last;
                    }

                    try {
                      final directory =
                          await getApplicationDocumentsDirectory();

                      final fileName =                          '${const Uuid().v4()}.pdf';

                      final destination =
                          File('${directory.path}/$fileName');

                      await sourceFile.copy(destination.path);

                      books.add({
                        'id': const Uuid().v4(),
                        'title': title,
                        'grade': selectedGrade,
                        'subject': selectedSubject,
                        'path': destination.path,
                        'date': DateTime.now().toIso8601String(),
                      });

                      await AppStorage.saveBooks(books);

                      if (!mounted) return;

                      setState(() {});

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تمت إضافة الملف بنجاح',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'حدث خطأ أثناء حفظ الملف: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
  }

  Future<void> deleteBook(int index) async {
    final book = books[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text(
          'هل تريد حذف "${book['title']}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final path = book['path']?.toString();

    if (path != null && path.isNotEmpty) {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    books.removeAt(index);

    await AppStorage.saveBooks(books);

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الكتب والمذكرات'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addBook,
          icon: const Icon(Icons.add),
          label: const Text('إضافة PDF'),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : books.isEmpty
                ? const Center(
                    child: Text(
                      'لم تتم إضافة كتب أو مذكرات بعد',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            size: 38,
                          ),
                          title: Text(
                            book['title']?.toString() ?? '',
                          ),
                          subtitle: Text(
                            '${book['grade']} - ${book['subject']}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteBook(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),// ================= إدارة الاختبارات =================

class ExamsAdminPage extends StatefulWidget {
  const ExamsAdminPage({super.key});

  @override
  State<ExamsAdminPage> createState() => _ExamsAdminPageState();
}

class _ExamsAdminPageState extends State<ExamsAdminPage> {
  List<Map<String, dynamic>> exams = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExams();
  }

Future<void> addExam() async {
  final titleController = TextEditingController();

  String selectedGrade = grades.first;
  String selectedSubject = subjects.first;

  final List<Map<String, dynamic>> questions = [];

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إنشاء اختبار جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الاختبار',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'الصف الدراسي',
                      border: OutlineInputBorder(),
                    ),
                    items: grades.map((grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedGrade = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'المادة',
                      border: OutlineInputBorder(),
                    ),
                    items: subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedSubject = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    'الأسئلة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (questions.isEmpty)
                    const Text('لم تتم إضافة أسئلة بعد'),
                  ...List.generate(
                    questions.length,
                    (index) {
                      final question = questions[index];

                      return Card(
                        child: ListTile(
                          title: Text(
                            '${index + 1}. ${question['question']}',
                          ),
                          subtitle: Text(
                            'الإجابة الصحيحة: '
                            '${question['options'][question['correct']]}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setDialogState(() {
                                questions.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final question =
                          await addQuestionDialog(context);

                      if (question != null) {
                        setDialogState(() {
                          questions.add(question);
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة سؤال'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final title =
                      titleController.text.trim();

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'اكتب اسم الاختبار أولًا',
                        ),
                      ),
                    );
                    return;
                  }

                  if (questions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'أضف سؤالًا واحدًا على الأقل',
                        ),
                      ),
                    );
                    return;
                  }

                  exams.add({
                    'id': const Uuid().v4(),
                    'title': title,
                    'grade': selectedGrade,
                    'subject': selectedSubject,
                    'questions': questions,
                    'date':
                        DateTime.now().toIso8601String(),
                  });

                  await AppStorage.saveExams(exams);

                  if (!mounted) return;

                  setState(() {});

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم إنشاء الاختبار بنجاح',
                      ),
                    ),
                  );
                },
                child: const Text('حفظ الاختبار'),
              ),
            ],
          );
        },
      );
    },
  );

  titleController.dispose();
}

titleController.dispose();

titleController.dispose();
}

Future<Map<String, dynamic>?> addQuestionDialog(
  BuildContext context,
) async {
  final questionController = TextEditingController();
  final option1Controller = TextEditingController();
  final option2Controller = TextEditingController();
  final option3Controller = TextEditingController();
  final option4Controller = TextEditingController();

  int correctAnswer = 0;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة سؤال'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'نص السؤال',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: option1Controller,
                    decoration: const InputDecoration(
                      labelText: 'الخيار الأول',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: option2Controller,
                    decoration: const InputDecoration(
                      labelText: 'الخيار الثاني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: option3Controller,
                    decoration: const InputDecoration(
                      labelText: 'الخيار الثالث',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: option4Controller,
                    decoration: const InputDecoration(
                      labelText: 'الخيار الرابع',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    value: correctAnswer,
                    decoration: const InputDecoration(
                      labelText: 'الإجابة الصحيحة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('الخيار الأول'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('الخيار الثاني'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('الخيار الثالث'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('الخيار الرابع'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        correctAnswer = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final question =
                      questionController.text.trim();

                  final options = [
                    option1Controller.text.trim(),
                    option2Controller.text.trim(),
                    option3Controller.text.trim(),
                    option4Controller.text.trim(),
                  ];

                  if (question.isEmpty ||
                      options.any((item) => item.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'أكمل السؤال وجميع الخيارات',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    {
                      'question': question,
                      'options': options,
                      'correct': correctAnswer,
                    },
                  );
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      );
    },
  );

  questionController.dispose();
  option1Controller.dispose();
  option2Controller.dispose();
  option3Controller.dispose();
  option4Controller.dispose();

  return result;
}

Future<void> deleteExam(int index) async {
  final exam = exams[index];

  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('حذف الاختبار'),
      content: Text(
        'هل تريد حذف "${exam['title']}"؟',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('حذف'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  exams.removeAt(index);

  await AppStorage.saveExams(exams);

  if (!mounted) return;

  setState(() {});
}

@override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الاختبارات'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addExam,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء اختبار'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : exams.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد اختبارات مضافة حتى الآن',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];

                    final questions =
                        List<Map<String, dynamic>>.from(
                      exam['questions'] ?? [],
                    );

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.assignment,
                          size: 38,
                        ),
                        title: Text(
                          exam['title']?.toString() ?? '',
                        ),
                        subtitle: Text(
                          '${exam['grade']} - '
                          '${exam['subject']}\n'
                          'عدد الأسئلة: ${questions.length}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteExam(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
    ),
  );
}// ================= نتائج جميع الطلاب =================

class AllResultsPage extends StatefulWidget {
  const AllResultsPage({super.key});

  @override
  State<AllResultsPage> createState() => _AllResultsPageState();
}

class _AllResultsPageState extends State<AllResultsPage> {
  List<Map<String, dynamic>> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    final data = await AppStorage.getResults();

    if (!mounted) return;

    setState(() {
      results = data;
      loading = false;
    });
  }

  Future<void> deleteResult(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف النتيجة'),
        content: const Text(
          'هل تريد حذف هذه النتيجة؟',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    results.removeAt(index);

    await AppStorage.saveResults(results);

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نتائج جميع الطلاب'),
          centerTitle: true,
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : results.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج حتى الآن',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];

                      final score =
                          result['score'] ?? 0;

                      final total =
                          result['total'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                          title: Text(
                            result['studentName']
                                    ?.toString() ??
                                'طالب',
                          ),
                          subtitle: Text(
                            '${result['examTitle'] ?? 'اختبار'}\n'
                            '${result['subject'] ?? ''} - '
                   '${result['grade'] ?? ''}\n'
'الدرجة: $score من $total',
),
isThreeLine: true,
trailing: IconButton(
  icon: const Icon(
    Icons.delete,
  ),
  onPressed: () {
    deleteResult(index);
  },
),
),
);
},
),
),
),
);
}
}
      // ================= بيانات الأستاذ =================

class TeacherBioPage extends StatelessWidget {
  const TeacherBioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الأستاذ محمد القاضي',
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(
              radius: 65,
              child: Icon(
                Icons.person,
                size: 75,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الأستاذ محمد القاضي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'أستاذ الكيمياء والفيزياء والأحياء '
                  'بمدرسة النور الأساسية الثانوية '
                  'بالروحاء - وصاب السافل.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'المؤهل العلمي:\n'
                  'بكالوريوس تربية تخصص كيمياء فيزيائية.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'التخصصات التعليمية:\n'
                  'الكيمياء - الفيزياء - الأحياء',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'للتواصل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'الهاتف: 774470090',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'البريد الإلكتروني: '
                      'alwsabi97@gmail.com',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'ادعم التعليم فالتعليم للجميع',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
