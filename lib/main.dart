import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QadiApp());
}

const String appName = 'برنامج محمد القاضي التعليمي العلمي';
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

class QadiApp extends StatelessWidget {
  const QadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF176B5B),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

// ================= الصفحة الرئيسية =================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.school, size: 50),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'برنامج محمد القاضي التعليمي العلمي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'منصة تعليمية للمرحلة الثانوية في الكيمياء والفيزياء والأحياء',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ادعم التعليم فالتعليم للجميع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          _button(
            context,
            Icons.person,
            'دخول الطالب',
            const StudentLoginPage(),
          ),
          _button(
            context,
            Icons.admin_panel_settings,
            'منطقة المعلم',
            const TeacherLoginPage(),
          ),
          _button(
            context,
            Icons.badge,
            'السيرة الذاتية للأستاذ',
            const TeacherBioPage(),
          ),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context,
    IconData icon,
    String text,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          icon: Icon(icon),
          label: Text(
            text,
            style: const TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }
}

// ================= دخول الطالب =================

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final codeController = TextEditingController();
  String error = '';

  Future<void> login() async {
    final code = codeController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('students') ?? '[]';

    final students = List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    Map<String, dynamic>? student;

    for (final item in students) {
      if (item['code'].toString() == code) {
        student = item;
        break;
      }
    }

    if (student == null) {
      setState(() {
        error = 'الكود غير صحيح أو غير مسجل.';
      });
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentHomePage(student: student!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الطالب')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.lock_open,
              size: 75,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أدخل كود الطالب',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: login,
                child: const Text('دخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= واجهة الطالب =================

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({
    super.key,
    required this.student,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String selectedGrade = grades.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبًا ${widget.student['name']}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(widget.student['name']),
              subtitle: Text(
                'كود الطالب: ${widget.student['code']}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedGrade,
            decoration: const InputDecoration(
              labelText: 'اختر الصف',
              border: OutlineInputBorder(),
            ),
            items: grades
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedGrade = value;
                });
              }
            },
          ),
          const SizedBox(height: 15),
          const Text(
            'المواد الدراسية',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...subjects.map(
            (subject) => Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(subject),
                subtitle: Text(selectedGrade),
                trailing: const Icon(Icons.arrow_back_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectPage(
                        grade: selectedGrade,
                        subject: subject,
                        student: widget.student,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultsPage(
                    studentCode: widget.student['code'].toString(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assessment),
            label: const Text('درجاتي ونتائجي'),
          ),
        ],
      ),
    );
  }
}

// ================= المادة =================

class SubjectPage extends StatefulWidget {
  final String grade;
  final String subject;
  final Map<String, dynamic> student;

  const SubjectPage({
    super.key,
    required this.grade,
    required this.subject,
    required this.student,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> exams = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final booksRaw = prefs.getString('books') ?? '[]';
    final examsRaw = prefs.getString('exams') ?? '[]';

    final allBooks = List<Map<String, dynamic>>.from(
      (jsonDecode(booksRaw) as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    final allExams = List<Map<String, dynamic>>.from(
      (jsonDecode(examsRaw) as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    setState(() {
      books = allBooks
          .where(
            (b) =>
                b['grade'] == widget.grade &&
                b['subject'] == widget.subject,
          )
          .toList();

      exams = allExams
          .where(
            (e) =>
                e['grade'] == widget.grade &&
                e['subject'] == widget.subject,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.school),
              title: Text(widget.grade),
              subtitle: Text(widget.subject),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '📚 الملازم والكتب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (books.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا توجد ملازم أو كتب مضافة لهذه المادة حاليًا.',
                ),
              ),
            ),
          ...books.map(
            (book) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                ),
                title: Text(book['title']),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfBookPage(
                        title: book['title'],
                        path: book['path'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '📝 الاختبارات المباشرة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (exams.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا توجد اختبارات متاحة لهذه المادة حاليًا.',
                ),
              ),
            ),
          ...exams.map(
            (exam) => Card(
              child: ListTile(
                leading: const Icon(Icons.quiz),
                title: Text(exam['title']),
                subtitle: Text(
                  '${(exam['questions'] as List).length} سؤال',
                ),
                trailing: const Icon(Icons.arrow_back_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamPage(
                        exam: exam,
                        student: widget.student,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= عرض الكتاب =================

class PdfBookPage extends StatelessWidget {
  final String title;
  final String path;

  const PdfBookPage({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final exists = File(path).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 90,
                color: Colors.red,
              ),
              const SizedBox(height: 15),
              Text(
                exists
                    ? 'تم العثور على الملف داخل مكتبة التطبيق.'
                    : 'الملف غير موجود.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'هذه الصفحة جاهزة لربط عارض PDF الداخلي في النسخة النهائية.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= الاختبار =================

class ExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> student;

  const ExamPage({
    super.key,
    required this.exam,
    required this.student,
  });

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final Map<int, int> answers = {};

  Future<void> finishExam() async {
    final questions = List<Map<String, dynamic>>.from(
      (widget.exam['questions'] as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i]['correct']) {
        score++;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('results') ?? '[]';

    final results = List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    results.add({
      'studentCode': widget.student['code'],
      'studentName': widget.student['name'],
      'exam': widget.exam['title'],
      'grade': widget.exam['grade'],
      'subject': widget.exam['subject'],
      'score': score,
      'total': questions.length,
      'date': DateTime.now().toIso8601String(),
    });

    await prefs.setString(
      'results',
      jsonEncode(results),
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نتيجة الاختبار'),
        content: Text(
          'أحسنت ${widget.student['name']}\n\n'
          'درجتك: $score من ${questions.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = List<Map<String, dynamic>>.from(
      (widget.exam['questions'] as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam['title']),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...List.generate(
            questions.length,
            (index) {
              final q = questions[index];

              final choices = List<String>.from(
                q['choices'] ?? [],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${q['text']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        choices.length,
                        (choiceIndex) {
                          return RadioListTile<int>(
                            value: choiceIndex,
                            groupValue: answers[index],
                            title: Text(choices[choiceIndex]),
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
            height: 55,
            child: FilledButton.icon(
              onPressed:
                  questions.isEmpty ? null : finishExam,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'إنهاء الاختبار وحفظ الدرجة',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= دخول المعلم =================

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() =>
      _TeacherLoginPageState();
}

class _TeacherLoginPageState
    extends State<TeacherLoginPage> {
  final controller = TextEditingController();
  String error = '';

  void login() {
    if (controller.text.t
