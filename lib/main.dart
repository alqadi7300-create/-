import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudSync.initialize();
  runApp(const QadiApp());
}

const teacherPassword = '774470090';

const grades = <String>[
  'الأول الثانوي',
  'الثاني الثانوي',
  'الثالث الثانوي',
];

const subjects = <String>[
  'الكيمياء',
  'الفيزياء',
  'الأحياء',
];

const questionTypes = <String>[
  'اختيار من متعدد',
  'صح أو خطأ',
  'إجابة قصيرة',
];

class QadiApp extends StatelessWidget {
  const QadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'برنامج محمد القاضي التعليمي العلمي',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

Widget rtl(Widget child) =>
    Directionality(textDirection: TextDirection.rtl, child: child);

class AppStorage {
  static Future<SharedPreferences> get prefs =>
      SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> _get(String key) async {
    final p = await prefs;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> _save(
      String key, List<Map<String, dynamic>> value) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>> getStudents() => _get('students');
  static Future<void> saveStudents(List<Map<String, dynamic>> v) => _save('students', v);
  static Future<List<Map<String, dynamic>>> getBooks() => _get('books');
  static Future<void> saveBooks(List<Map<String, dynamic>> v) => _save('books', v);
  static Future<List<Map<String, dynamic>>> getExams() => _get('exams');
  static Future<void> saveExams(List<Map<String, dynamic>> v) => _save('exams', v);
  static Future<List<Map<String, dynamic>>> getResults() => _get('results');
  static Future<void> saveResults(List<Map<String, dynamic>> v) => _save('results', v);
  static Future<List<Map<String, dynamic>>> getAttempts() => _get('exam_attempts');
  static Future<void> saveAttempts(List<Map<String, dynamic>> v) => _save('exam_attempts', v);

  static Future<void> saveStudentSession(String code) async {
    final p = await prefs;
    await p.setString('logged_student_code', code);
  }

  static Future<String?> getStudentSession() async {
    final p = await prefs;
    return p.getString('logged_student_code');
  }

  static Future<void> clearStudentSession() async {
    final p = await prefs;
    await p.remove('logged_student_code');
  }

  static Future<void> saveTeacherSession(bool value) async {
    final p = await prefs;
    await p.setBool('logged_teacher', value);
  }

  static Future<bool> getTeacherSession() async {
    final p = await prefs;
    return p.getBool('logged_teacher') ?? false;
  }

  static Future<void> clearTeacherSession() async {
    final p = await prefs;
    await p.remove('logged_teacher');
  }

  static Future<String?> getTeacherPhoto() async {
    final p = await prefs;
    return p.getString('teacher_photo_base64');
  }

  static Future<void> saveTeacherPhoto(String base64) async {
    final p = await prefs;
    await p.setString('teacher_photo_base64', base64);
  }

  static Future<void> removeTeacherPhoto() async {
    final p = await prefs;
    await p.remove('teacher_photo_base64');
  }
}


// ================= المزامنة السحابية =================

class CloudSync {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      _ready = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      // يبقى التطبيق يعمل محليًا إذا لم يتوفر الإنترنت أو تعذر الاتصال.
      _ready = false;
    }
  }

  static Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      _ready = FirebaseAuth.instance.currentUser != null;
      return _ready;
    } catch (_) {
      return false;
    }
  }

  static CollectionReference<Map<String, dynamic>> get _students =>
      FirebaseFirestore.instance.collection('students');

  static Future<List<Map<String, dynamic>>?> getStudents() async {
    if (!await _ensureReady()) return null;
    try {
      final snapshot = await _students.get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        return data;
      }).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentByCode(String code) async {
    if (!await _ensureReady()) return null;
    try {
      final snapshot = await _students
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveStudent(Map<String, dynamic> student) async {
    if (!await _ensureReady()) return false;
    try {
      final id = student['id']?.toString();
      if (id == null || id.isEmpty) return false;
      await _students.doc(id).set(
        Map<String, dynamic>.from(student),
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteStudent(String id) async {
    if (!await _ensureReady()) return false;
    try {
      await _students.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ================= الرئيسية =================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('برنامج محمد القاضي التعليمي العلمي'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 18),
              const Icon(Icons.school, size: 90),
              const SizedBox(height: 18),
              const Text(
                'برنامج محمد القاضي التعليمي العلمي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              _go(context, 'دخول الطالب', Icons.person, const StudentLoginPage()),
              _gap(),
              _go(context, 'دخول المعلم', Icons.admin_panel_settings,
                  const TeacherLoginPage()),
              _gap(),
              _go(context, 'عن الأستاذ محمد القاضي', Icons.info_outline,
                  const TeacherBioPage()),
            ],
          ),
        ),
      );

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 58,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
          icon: Icon(i),
          label: Text(t, style: const TextStyle(fontSize: 18)),
        ),
      );

  Widget _gap() => const SizedBox(height: 12);
}

// ================= دخول الطالب =================

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final controller = TextEditingController();
  String error = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final savedCode = await AppStorage.getStudentSession();
    if (savedCode == null || savedCode.isEmpty) return;

    Map<String, dynamic>? student;

    // نحاول أولًا جلب بيانات الطالب من السحابة حتى يعمل الكود على أي هاتف.
    student = await CloudSync.getStudentByCode(savedCode);

    // إذا لم تتوفر السحابة/الإنترنت نستخدم النسخة المحلية.
    if (student == null) {
      final students = await AppStorage.getStudents();
      for (final s in students) {
        if (s['code']?.toString() == savedCode) {
          student = s;
          break;
        }
      }
    }

    if (student != null) {
      await AppStorage.saveStudents([
        ...await AppStorage.getStudents().then((local) {
          final index = local.indexWhere(
            (s) => s['id']?.toString() == student!['id']?.toString(),
          );
          if (index >= 0) {
            local[index] = Map<String, dynamic>.from(student!);
          } else {
            local.add(Map<String, dynamic>.from(student!));
          }
          return local;
        }),
      ]);
    }

    if (!mounted || student == null || student['active'] == false) {
      if (student == null || student['active'] == false) {
        await AppStorage.clearStudentSession();
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => StudentHomePage(student: student!)),
    );
  }

  Future<void> login() async {
    final code = controller.text.trim();
    if (code.isEmpty) {
      setState(() => error = 'أدخل كود الطالب');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });

    // البحث في Firestore أولًا حتى يتمكن الطالب من استخدام كوده
    // الذي أنشأه المعلم على هاتف آخر.
    Map<String, dynamic>? student =
        await CloudSync.getStudentByCode(code);

    // تشغيل التطبيق بدون إنترنت يظل ممكنًا من خلال التخزين المحلي.
    if (student == null) {
      final students = await AppStorage.getStudents();
      for (final s in students) {
        if (s['code']?.toString() == code) {
          student = s;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() => loading = false);
    if (student == null) {
      setState(() => error = 'كود الطالب غير صحيح');
      return;
    }
    if (student['active'] == false) {
      setState(() => error = 'تم إيقاف هذا الطالب من قبل المعلم');
      return;
    }

    await AppStorage.saveStudentSession(code);
    await AppStorage.saveStudents([
      ...await AppStorage.getStudents().then((local) {
        final index = local.indexWhere(
          (s) => s['id']?.toString() == student!['id']?.toString(),
        );
        if (index >= 0) {
          local[index] = Map<String, dynamic>.from(student!);
        } else {
          local.add(Map<String, dynamic>.from(student!));
        }
        return local;
      }),
    ]);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => StudentHomePage(student: student!)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('دخول الطالب'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 35),
                const Icon(Icons.person, size: 90),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'كود الطالب',
                    hintText: 'أدخل الكود الخاص بك',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                if (error.isNotEmpty)
                  Text(error,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ================= بوابة الطالب =================

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({super.key, required this.student});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int maleCount = 0;
  int femaleCount = 0;
  List<Map<String, dynamic>> topStudents = [];
  bool loadingStats = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    final students = await AppStorage.getStudents();
    final results = await AppStorage.getResults();
    final grade = widget.student['grade']?.toString() ?? grades.first;

    maleCount = students.where((s) => s['gender']?.toString() == 'ذكر').length;
    femaleCount = students.where((s) => s['gender']?.toString() == 'أنثى').length;

    final classStudents = students.where((s) => s['grade']?.toString() == grade).toList();
    final ranked = <Map<String, dynamic>>[];
    for (final s in classStudents) {
      final code = s['code']?.toString() ?? '';
      final mine = results.where((r) =>
          r['studentCode']?.toString() == code &&
          r['grade']?.toString() == grade).toList();
      if (mine.isEmpty) continue;
      double totalPercent = 0;
      for (final r in mine) {
        final score = num.tryParse(r['score']?.toString() ?? '') ?? 0;
        final total = num.tryParse(r['total']?.toString() ?? '') ?? 0;
        if (total > 0) totalPercent += (score / total) * 100;
      }
      ranked.add({
        'name': s['name']?.toString() ?? 'طالب',
        'average': totalPercent / mine.length,
      });
    }
    ranked.sort((a, b) =>
        (b['average'] as double).compareTo(a['average'] as double));

    if (!mounted) return;
    setState(() {
      topStudents = ranked.take(3).toList();
      loadingStats = false;
    });
  }

  Future<void> logout() async {
    await AppStorage.clearStudentSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name']?.toString() ?? 'الطالب';
    final grade = widget.student['grade']?.toString() ?? grades.first;
    return rtl(
      Scaffold(
        appBar: AppBar(
          title: const Text('بوابة الطالب'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تحديث الإحصاءات',
              onPressed: loadStats,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(Icons.person, size: 44),
                    ),
                    const SizedBox(height: 10),
                    Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                    Text('الصف: $grade'),
                    Text('الكود: ${widget.student['code'] ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('إحصائية الطلاب المسجلين في البرنامج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _statTile('الذكور', maleCount, Icons.male)),
                        const SizedBox(width: 10),
                        Expanded(child: _statTile('الإناث', femaleCount, Icons.female)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🏆 أوائل الصف', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('أعلى متوسط درجات في $grade', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    if (loadingStats)
                      const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                    else if (topStudents.isEmpty)
                      const Text('لم تتوفر نتائج كافية لعرض الأوائل بعد.', textAlign: TextAlign.center)
                    else
                      ...List.generate(topStudents.length, (i) {
                        final s = topStudents[i];
                        final medal = ['🥇', '🥈', '🥉'][i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(medal)),
                          title: Text(s['name']?.toString() ?? 'طالب', style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text('${(s['average'] as double).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _go(context, 'الكتب والمذكرات', Icons.menu_book, SubjectPage(grade: grade)),
            _gap(),
            _go(context, 'الاختبارات', Icons.assignment, ExamPage(grade: grade, student: widget.student)),
            _gap(),
            _go(context, 'درجاتي السابقة', Icons.bar_chart, ResultsPage(student: widget.student)),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, int value, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
        child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 5), Text(label), Text('$value', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold))]),
      );

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () async {
            await Navigator.push(c, MaterialPageRoute(builder: (_) => p));
            if (mounted) loadStats();
          },
          icon: Icon(i),
          label: Text(t),
        ),
      );

  Widget _gap() => const SizedBox(height: 10);
}

// ================= المواد والكتب =================

class SubjectPage extends StatelessWidget {
  final String grade;

  const SubjectPage({super.key, required this.grade});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: Text('مواد $grade'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('اختر المادة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              for (final subject in subjects) ...[
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PdfBookPage(grade: grade, subject: subject),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: Text(subject),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
}

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
    final all = await AppStorage.getBooks();
    final filtered = all
        .where((b) =>
            b['grade']?.toString() == widget.grade &&
            b['subject']?.toString() == widget.subject)
        .toList();
    if (!mounted) return;
    setState(() {
      books = filtered;
      loading = false;
    });
  }

  Future<void> openPdf(Map<String, dynamic> book) async {
    final path = book['path']?.toString();
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ملف PDF غير موجود')));
      }
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: book['title']?.toString() ?? 'ملف PDF',
          bytes: bytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: Text(widget.subject), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
                  ? const Center(
                      child: Text('لا توجد كتب أو مذكرات مضافة حاليًا'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        return Card(
                          child: ListTile(
                            leading:
                                const Icon(Icons.picture_as_pdf, size: 36),
                            title: Text(b['title']?.toString() ?? 'PDF'),
                            subtitle: Text(
                                '${b['grade'] ?? ''} - ${b['subject'] ?? ''}'),
                            trailing: const Icon(Icons.arrow_back_ios),
                            onTap: () => openPdf(b),
                          ),
                        );
                      },
                    ),
        ),
      );
}

class PdfViewerPage extends StatefulWidget {
  final String title;
  final Uint8List bytes;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.bytes,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final pdfx.PdfControllerPinch controller;

  @override
  void initState() {
    super.initState();
    controller = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'إعادة فتح الصفحة',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  controller.loadDocument(pdfx.PdfDocument.openData(widget.bytes));
                },
              ),
            ],
          ),
          body: pdfx.PdfViewPinch(
            controller: controller,
            scrollDirection: Axis.vertical,
          ),
        ),
      );
}

class ExamPage extends StatefulWidget {
  final String grade;
  final Map<String, dynamic> student;

  const ExamPage({super.key, required this.grade, required this.student});

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
    final all = await AppStorage.getExams();
    final filtered =
        all.where((e) => e['grade']?.toString() == widget.grade).toList();
    if (!mounted) return;
    setState(() {
      exams = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('الاختبارات'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : exams.isEmpty
                  ? const Center(child: Text('لا توجد اختبارات متاحة حاليًا'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: exams.length,
                      itemBuilder: (_, i) {
                        final e = exams[i];
                        final questions =
                            List<Map<String, dynamic>>.from(e['questions'] ?? []);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment, size: 35),
                            title: Text(e['title']?.toString() ?? 'اختبار'),
                            subtitle: Text(
                                '${e['subject'] ?? ''} - ${questions.length} أسئلة'),
                            trailing: const Icon(Icons.arrow_back_ios),
                            onTap: () async {
                              final attempts = await AppStorage.getAttempts();
                              final studentCode = widget.student['code']?.toString() ?? '';
                              final examId = e['id']?.toString() ?? '';
                              final already = attempts.any((a) =>
                                  a['studentCode']?.toString() == studentCode &&
                                  a['examId']?.toString() == examId);
                              if (!context.mounted) return;
                              if (already) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('لقد أجريت هذا الاختبار من قبل، ولا يمكن إعادته.')),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TakeExamPage(exam: e, student: widget.student),
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

// ================= حل الاختبار =================

class TakeExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> student;

  const TakeExamPage({super.key, required this.exam, required this.student});

  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage> {
  final Map<int, dynamic> answers = {};
  bool saving = false;

  Future<void> submitExam() async {
    if (saving) return;
    final questions =
        List<Map<String, dynamic>>.from(widget.exam['questions'] ?? []);
    final attempts = await AppStorage.getAttempts();
    final studentCode = widget.student['code']?.toString() ?? '';
    final examId = widget.exam['id']?.toString() ?? '';
    final already = attempts.any((a) =>
        a['studentCode']?.toString() == studentCode &&
        a['examId']?.toString() == examId);
    if (already) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('الاختبار مغلق'),
            content: Text('لقد أجريت هذا الاختبار من قبل، ولا يمكن إعادته.'),
          ),
        );
      }
      return;
    }
    int score = 0;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final type = q['type']?.toString() ?? questionTypes.first;
      if (type == 'صح أو خطأ') {
        if (answers[i]?.toString() == q['correctText']?.toString()) score++;
      } else if (type == 'إجابة قصيرة') {
        final a = answers[i]?.toString().trim().toLowerCase() ?? '';
        final c = q['correctText']?.toString().trim().toLowerCase() ?? '';
        if (a.isNotEmpty && a == c) score++;
      } else {
        if (answers[i] == q['correct']) score++;
      }
    }

    setState(() => saving = true);
    attempts.add({
      'id': const Uuid().v4(),
      'studentCode': studentCode,
      'examId': examId,
      'date': DateTime.now().toIso8601String(),
    });
    await AppStorage.saveAttempts(attempts);
    final results = await AppStorage.getResults();
    results.add({
      'id': const Uuid().v4(),
      'studentCode': widget.student['code']?.toString() ?? '',
      'studentName': widget.student['name']?.toString() ?? '',
      'grade': widget.exam['grade']?.toString() ?? '',
      'examTitle': widget.exam['title']?.toString() ?? '',
      'subject': widget.exam['subject']?.toString() ?? '',
      'score': score,
      'total': questions.length,
      'date': DateTime.now().toIso8601String(),
    });
    await AppStorage.saveResults(results);
    if (!mounted) return;
    setState(() => saving = false);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم إنهاء الاختبار'),
        content: Text('درجتك: $score من ${questions.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget questionWidget(Map<String, dynamic> q, int index) {
    final type = q['type']?.toString() ?? questionTypes.first;
    final text = q['question']?.toString() ?? '';

    if (type == 'صح أو خطأ') {
      return Card(
        child: Column(
          children: [
            ListTile(
              title: Text('${index + 1}. $text',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            RadioListTile<String>(
              value: 'صح',
              groupValue: answers[index]?.toString(),
              title: const Text('صح'),
              onChanged: answers.containsKey(index) ? null : (v) => setState(() => answers[index] = v),
            ),
            RadioListTile<String>(
              value: 'خطأ',
              groupValue: answers[index]?.toString(),
              title: const Text('خطأ'),
              onChanged: answers.containsKey(index) ? null : (v) => setState(() => answers[index] = v),
            ),
          ],
        ),
      );
    }

    if (type == 'إجابة قصيرة') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. $text',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                onChanged: answers.containsKey(index) ? null : (v) {
                  if (v.trim().isNotEmpty) setState(() => answers[index] = v);
                },
                decoration: const InputDecoration(labelText: 'اكتب إجابتك'),
              ),
            ],
          ),
        ),
      );
    }

    final options = List<String>.from(q['options'] ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. $text',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ...List.generate(
              options.length,
              (j) => RadioListTile<int>(
                value: j,
                groupValue: answers[index] as int?,
                title: Text(options[j]),
                onChanged: answers.containsKey(index) ? null : (v) => setState(() => answers[index] = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions =
        List<Map<String, dynamic>>.from(widget.exam['questions'] ?? []);
    return rtl(
      Scaffold(
        appBar: AppBar(
          title: Text(widget.exam['title']?.toString() ?? 'الاختبار'),
          centerTitle: true,
        ),
        body: questions.isEmpty
            ? const Center(child: Text('لا توجد أسئلة في هذا الاختبار'))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(widget.exam['subject']?.toString() ?? ''),
                      subtitle: Text('عدد الأسئلة: ${questions.length}'),
                    ),
                  ),
                  ...List.generate(
                    questions.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: questionWidget(questions[i], i),
                    ),
                  ),
                  SizedBox(
                    height: 55,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submitExam,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                          saving ? 'جارٍ الحفظ...' : 'إنهاء الاختبار وتسليم الإجابات'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ================= النتائج =================

class ResultsPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const ResultsPage({super.key, required this.student});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Map<String, dynamic>> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all = await AppStorage.getResults();
    final filtered = all
        .where((r) =>
            r['studentCode']?.toString() ==
            widget.student['code']?.toString())
        .toList()
        .reversed
        .toList();
    if (!mounted) return;
    setState(() {
      results = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('درجاتي السابقة'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('لا توجد نتائج محفوظة حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.bar_chart),
                            title: Text(r['examTitle']?.toString() ?? 'اختبار'),
                            subtitle: Text(
                              '${r['subject'] ?? ''}\nالدرجة: ${r['score']} من ${r['total']}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
        ),
      );
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

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!await AppStorage.getTeacherSession() || !mounted) return;
    await AppStorage.saveTeacherSession(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomePage()),
    );
  }

  Future<void> login() async {
    if (controller.text.trim() != teacherPassword) {
      setState(() => error = 'رمز المعلم غير صحيح');
      return;
    }
    await AppStorage.saveTeacherSession(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomePage()),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('دخول المعلم'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 35),
                const Icon(Icons.admin_panel_settings, size: 90),
                const SizedBox(height: 22),
                TextField(
                  controller: controller,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'رمز المعلم'),
                ),
                const SizedBox(height: 12),
                if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(onPressed: login, child: const Text('دخول')),
                ),
              ],
            ),
          ),
        ),
      );
}

// ================= لوحة المعلم =================

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('لوحة المعلم'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: () async {
                  await AppStorage.clearTeacherSession();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 58),
                      SizedBox(height: 8),
                      Text('إدارة الطلاب والكتب والاختبارات والنتائج'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _go(context, 'إدارة الطلاب', Icons.people, const StudentsAdminPage()),
              _gap(),
              _go(context, 'صورة المعلم', Icons.photo_camera, const TeacherPhotoPage()),
              _gap(),
              _go(context, 'إدارة الكتب والمذكرات', Icons.picture_as_pdf,
                  const BooksAdminPage()),
              _gap(),
              _go(context, 'إدارة الاختبارات', Icons.assignment,
                  const ExamsAdminPage()),
              _gap(),
              _go(context, 'نتائج الطلاب', Icons.bar_chart, const AllResultsPage()),
            ],
          ),
        ),
      );

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
          icon: Icon(i),
          label: Text(t),
        ),
      );

  Widget _gap() => const SizedBox(height: 10);
}

// ================= إدارة الطلاب =================

class StudentsAdminPage extends StatefulWidget {
  const StudentsAdminPage({super.key});

  @override
  State<StudentsAdminPage> createState() => _StudentsAdminPageState();
}

class _StudentsAdminPageState extends State<StudentsAdminPage> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    // السحابة هي المصدر المشترك بين هاتف المعلم وهواتف الطلاب.
    // عند عدم توفر الإنترنت نعود تلقائيًا إلى النسخة المحلية.
    final cloudData = await CloudSync.getStudents();
    if (cloudData != null) {
      await AppStorage.saveStudents(cloudData);
      if (mounted) setState(() => students = cloudData);
      return;
    }

    final localData = await AppStorage.getStudents();
    if (mounted) setState(() => students = localData);
  }

  String createCode() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(5);
  }

  Future<void> addStudent() async {
    final nameController = TextEditingController();
    var selectedGrade = grades.first;
    var selectedGender = 'ذكر';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة طالب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الطالب'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'الجنس'),
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedGender = v);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                items: grades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedGrade = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();
    if (name.isEmpty) return;

    final code = createCode();
    final student = <String, dynamic>{
      'id': const Uuid().v4(),
      'name': name,
      'grade': selectedGrade,
      'gender': selectedGender,
      'code': code,
      'active': true,
    };

    students.add(student);
    await AppStorage.saveStudents(students);

    final synced = await CloudSync.saveStudent(student);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'تم إنشاء الطالب ومزامنة الكود مع السحابة. الكود: $code'
              : 'تم إنشاء الطالب محليًا. تعذر المزامنة حاليًا. الكود: $code',
        ),
      ),
    );
  }

  Future<void> toggleStudent(int index) async {
    students[index]['active'] = students[index]['active'] == false;
    await AppStorage.saveStudents(students);
    final synced = await CloudSync.saveStudent(students[index]);
    if (mounted) setState(() {});
    if (mounted) {
      final stopped = students[index]['active'] == false;
      final message = stopped
          ? 'تم إخراج الطالب وإيقاف حسابه'
          : 'تم إعادة السماح للطالب بالدخول';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced ? message : '$message، لكن تعذر مزامنة التغيير حاليًا',
          ),
        ),
      );
    }
  }

  Future<void> changeStudentCode(int index) async {
    final c = TextEditingController(text: students[index]['code']?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغيير كود الطالب'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'الكود الجديد')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    final newCode = result?.trim() ?? '';
    c.dispose();
    if (newCode.isEmpty) return;
    final duplicate = students.asMap().entries.any((e) => e.key != index && e.value['code']?.toString() == newCode);
    if (duplicate) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الكود مستخدم لطالب آخر')));
      return;
    }
    students[index]['code'] = newCode;
    await AppStorage.saveStudents(students);
    final synced = await CloudSync.saveStudent(students[index]);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced
                ? 'تم تغيير الكود ومزامنته مع السحابة'
                : 'تم تغيير الكود محليًا، لكن تعذر مزامنته حاليًا',
          ),
        ),
      );
    }
  }

  Future<void> deleteStudent(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text('هل تريد حذف "${students[index]['name']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    final studentId = students[index]['id']?.toString() ?? '';
    students.removeAt(index);
    await AppStorage.saveStudents(students);
    final synced = studentId.isNotEmpty
        ? await CloudSync.deleteStudent(studentId)
        : false;
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced
                ? 'تم حذف الطالب من الهاتف والسحابة'
                : 'تم حذف الطالب محليًا، لكن تعذر حذفه من السحابة حاليًا',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('إدارة الطلاب'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addStudent,
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة طالب'),
          ),
          body: students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب مضافون'))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(s['name']?.toString() ?? ''),
                        subtitle: Text('${s['grade']} - ${s['gender'] ?? 'ذكر'}\nالكود: ${s['code']}\nالحالة: ${s['active'] == false ? 'موقوف' : 'نشط'}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle') toggleStudent(i);
                            if (value == 'code') changeStudentCode(i);
                            if (value == 'delete') deleteStudent(i);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'toggle', child: Text(s['active'] == false ? 'إعادة السماح بالدخول' : 'إخراج الطالب وإيقافه')),
                            const PopupMenuItem(value: 'code', child: Text('تغيير كود الطالب')),
                            const PopupMenuItem(value: 'delete', child: Text('حذف الطالب')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

// ================= صورة المعلم - للمعلم فقط =================

class TeacherPhotoPage extends StatefulWidget {
  const TeacherPhotoPage({super.key});

  @override
  State<TeacherPhotoPage> createState() => _TeacherPhotoPageState();
}

class _TeacherPhotoPageState extends State<TeacherPhotoPage> {
  String? photoBase64;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final value = await AppStorage.getTeacherPhoto();
    if (!mounted) return;
    setState(() { photoBase64 = value; loading = false; });
  }

  Future<void> pickPhoto() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (picked == null) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null) return;
    await AppStorage.saveTeacherPhoto(base64Encode(bytes));
    if (mounted) setState(() => photoBase64 = base64Encode(bytes));
  }

  Future<void> removePhoto() async {
    await AppStorage.removeTeacherPhoto();
    if (mounted) setState(() => photoBase64 = null);
  }

  @override
  Widget build(BuildContext context) => rtl(Scaffold(
    appBar: AppBar(title: const Text('صورة المعلم - للمعلم فقط'), centerTitle: true),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('هذه الصفحة داخل لوحة المعلم فقط، والطالب لا يستطيع تغيير الصورة.', textAlign: TextAlign.center),
        const SizedBox(height: 25),
        Center(child: CircleAvatar(
          radius: 75,
          backgroundImage: photoBase64 == null ? null : MemoryImage(base64Decode(photoBase64!)),
          child: photoBase64 == null ? const Icon(Icons.person, size: 80) : null,
        )),
        const SizedBox(height: 25),
        FilledButton.icon(onPressed: pickPhoto, icon: const Icon(Icons.photo), label: const Text('اختيار صورة المعلم')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: photoBase64 == null ? null : removePhoto, icon: const Icon(Icons.delete), label: const Text('حذف الصورة')),
      ],
    ),
  ));
}

// ================= إدارة الكتب =================

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
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getBooks();
    if (!mounted) return;
    setState(() {
      books = data;
      loading = false;
    });
  }

  Future<void> addBook() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final source = File(picked.files.single.path!);
    final titleController = TextEditingController();
    var grade = grades.first;
    var subject = subjects.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة كتاب أو مذكرة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'اسم الكتاب أو المذكرة'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: grade,
                  decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                  items: grades
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => grade = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'المادة'),
                  items: subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => subject = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (ok != true) {
      titleController.dispose();
      return;
    }

    final title = titleController.text.trim().isEmpty
        ? source.path.split(Platform.pathSeparator).last
        : titleController.text.trim();
    titleController.dispose();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final destination = File('${dir.path}/${const Uuid().v4()}.pdf');
      await source.copy(destination.path);

      books.add({
        'id': const Uuid().v4(),
        'title': title,
        'grade': grade,
        'subject': subject,
        'path': destination.path,
        'date': DateTime.now().toIso8601String(),
      });
      await AppStorage.saveBooks(books);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الملف بنجاح')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  Future<void> deleteBook(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل تريد حذف "${books[index]['title']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;

    final path = books[index]['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    books.removeAt(index);
    await AppStorage.saveBooks(books);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
              title: const Text('إدارة الكتب والمذكرات'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addBook,
            icon: const Icon(Icons.add),
            label: const Text('إضافة PDF'),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
                  ? const Center(child: Text('لم تتم إضافة كتب أو مذكرات بعد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf, size: 38),
                            title: Text(b['title']?.toString() ?? ''),
                            subtitle: Text('${b['grade']} - ${b['subject']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteBook(i),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= إنشاء السؤال =================

Future<Map<String, dynamic>?> addQuestionDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final qController =
      TextEditingController(text: initial?['question']?.toString() ?? '');
  final optionControllers = List.generate(
    4,
    (i) => TextEditingController(
        text: List<String>.from(initial?['options'] ?? const []).length > i
            ? List<String>.from(initial?['options'] ?? const [])[i]
            : ''),
  );
  final correctTextController =
      TextEditingController(text: initial?['correctText']?.toString() ?? '');
  var type = initial?['type']?.toString() ?? questionTypes.first;
  var correct = int.tryParse(initial?['correct']?.toString() ?? '') ?? 0;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(initial == null ? 'إضافة سؤال' : 'تعديل سؤال'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'نوع السؤال'),
                items: questionTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'نص السؤال'),
              ),
              if (type == 'اختيار من متعدد') ...[
                const SizedBox(height: 10),
                for (var i = 0; i < 4; i++) ...[
                  TextField(
                    controller: optionControllers[i],
                    decoration: InputDecoration(labelText: 'الخيار ${i + 1}'),
                  ),
                  const SizedBox(height: 7),
                ],
                DropdownButtonFormField<int>(
                  value: correct,
                  decoration:
                      const InputDecoration(labelText: 'الإجابة الصحيحة'),
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                        value: i, child: Text('الخيار ${i + 1}')),
                  ),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => correct = v);
                  },
                ),
              ] else if (type == 'صح أو خطأ') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: ['صح', 'خطأ']
                          .contains(correctTextController.text)
                      ? correctTextController.text
                      : 'صح',
                  decoration:
                      const InputDecoration(labelText: 'الإجابة الصحيحة'),
                  items: const [
                    DropdownMenuItem(value: 'صح', child: Text('صح')),
                    DropdownMenuItem(value: 'خطأ', child: Text('خطأ')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => correctTextController.text = v);
                    }
                  },
                ),
              ] else ...[
                const SizedBox(height: 10),
                TextField(
                  controller: correctTextController,
                  decoration:
                      const InputDecoration(labelText: 'الإجابة النموذجية'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final question = qController.text.trim();
              if (question.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اكتب نص السؤال')));
                return;
              }

              if (type == 'اختيار من متعدد') {
                final options =
                    optionControllers.map((c) => c.text.trim()).toList();
                if (options.any((x) => x.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أكمل جميع الخيارات')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'type': type,
                  'question': question,
                  'options': options,
                  'correct': correct,
                  'correctText': options[correct],
                });
              } else {
                final answer = correctTextController.text.trim();
                if (answer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أدخل الإجابة الصحيحة')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'type': type,
                  'question': question,
                  'options': <String>[],
                  'correct': 0,
                  'correctText': answer,
                });
              }
            },
            child: Text(initial == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    ),
  );

  qController.dispose();
  for (final c in optionControllers) {
    c.dispose();
  }
  correctTextController.dispose();
  return result;
}

// ================= إدارة الاختبارات =================

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
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getExams();
    if (!mounted) return;
    setState(() {
      exams = data;
      loading = false;
    });
  }

  Future<Map<String, dynamic>?> examDialog({
    Map<String, dynamic>? old,
  }) async {
    final titleController =
        TextEditingController(text: old?['title']?.toString() ?? '');
    var grade = old?['grade']?.toString() ?? grades.first;
    var subject = old?['subject']?.toString() ?? subjects.first;
    final questions = List<Map<String, dynamic>>.from(
        (old?['questions'] as List?) ?? const []);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(old == null ? 'إنشاء اختبار جديد' : 'تعديل الاختبار'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'اسم الاختبار'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                    items: grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => grade = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: subject,
                    decoration: const InputDecoration(labelText: 'المادة'),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => subject = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('الأسئلة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  if (questions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('لم تتم إضافة أسئلة بعد'),
                    ),
                  ...List.generate(
                    questions.length,
                    (i) {
                      final q = questions[i];
                      return Card(
                        child: ListTile(
                          title: Text('${i + 1}. ${q['question']}'),
                          subtitle: Text(q['type']?.toString() ?? ''),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final edited = await addQuestionDialog(
                                    context,
                                    initial: q,
                                  );
                                  if (edited != null) {
                                    setDialogState(
                                        () => questions[i] = edited);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    setDialogState(() => questions.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final q = await addQuestionDialog(context);
                      if (q != null) setDialogState(() => questions.add(q));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة سؤال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty || questions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أدخل اسم الاختبار وأضف سؤالًا واحدًا على الأقل')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'id': old?['id'] ?? const Uuid().v4(),
                  'title': title,
                  'grade': grade,
                  'subject': subject,
                  'questions': questions,
                  'date': old?['date'] ?? DateTime.now().toIso8601String(),
                });
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    return result;
  }

  Future<void> addExam() async {
    final e = await examDialog();
    if (e == null) return;
    exams.add(e);
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> editExam(int index) async {
    final e = await examDialog(old: exams[index]);
    if (e == null) return;
    exams[index] = e;
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> deleteExam(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الاختبار'),
        content: Text('هل تريد حذف "${exams[index]['title']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    exams.removeAt(index);
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> previewExam(Map<String, dynamic> exam) async {
    final questions =
        List<Map<String, dynamic>>.from(exam['questions'] ?? []);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPreviewPage(exam: exam, questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('إدارة الاختبارات'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addExam,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء اختبار'),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : exams.isEmpty
                  ? const Center(child: Text('لا توجد اختبارات مضافة حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: exams.length,
                      itemBuilder: (_, i) {
                        final e = exams[i];
                        final qs =
                            List<Map<String, dynamic>>.from(e['questions'] ?? []);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment, size: 36),
                            title: Text(e['title']?.toString() ?? ''),
                            subtitle: Text(
                                '${e['grade']} - ${e['subject']}\nعدد الأسئلة: ${qs.length}'),
                            isThreeLine: true,
                            onTap: () => previewExam(e),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                    tooltip: 'تعديل',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => editExam(i)),
                                IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => deleteExam(i)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= معاينة وتصدير الاختبار =================

class ExamPreviewPage extends StatelessWidget {
  final Map<String, dynamic> exam;
  final List<Map<String, dynamic>> questions;

  const ExamPreviewPage({
    super.key,
    required this.exam,
    required this.questions,
  });

  Future<Uint8List> buildPdf() async {
    final lines = <String>[
      'برنامج محمد القاضي التعليمي العلمي',
      'الاختبار: ${exam['title'] ?? ''}',
      'الصف: ${exam['grade'] ?? ''}',
      'المادة: ${exam['subject'] ?? ''}',
      '',
    ];

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      lines.add('${i + 1}. ${q['question'] ?? ''}');
      final type = q['type']?.toString() ?? '';
      if (type == 'اختيار من متعدد') {
        final options = List<String>.from(q['options'] ?? []);
        for (var j = 0; j < options.length; j++) {
          lines.add('   ${String.fromCharCode(65 + j)}- ${options[j]}');
        }
      } else if (type == 'صح أو خطأ') {
        lines.add('   (صح)     (خطأ)');
      } else {
        lines.add('   الإجابة: __________________________');
      }
      lines.add('');
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Text(
            'برنامج محمد القاضي التعليمي العلمي',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('الاختبار: ${exam['title'] ?? ''}'),
          pw.Text('الصف: ${exam['grade'] ?? ''}'),
          pw.Text('المادة: ${exam['subject'] ?? ''}'),
          pw.SizedBox(height: 14),
          ...lines.skip(5).map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(line, textDirection: pw.TextDirection.rtl),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('معاينة الاختبار'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'تصدير PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  final bytes = await buildPdf();
                  if (!context.mounted) return;
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'برنامج محمد القاضي التعليمي العلمي',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('الاختبار: ${exam['title'] ?? ''}'),
                      Text('المادة: ${exam['subject'] ?? ''}'),
                      Text('الصف: ${exam['grade'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                questions.length,
                (i) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: _questionView(questions[i], i),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _questionView(Map<String, dynamic> q, int i) {
    final type = q['type']?.toString() ?? '';
    final children = <Widget>[
      Text('${i + 1}. ${q['question'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    ];

    if (type == 'اختيار من متعدد') {
      final options = List<String>.from(q['options'] ?? []);
      children.addAll(List.generate(
        options.length,
        (j) => Text('${String.fromCharCode(65 + j)}- ${options[j]}'),
      ));
    } else if (type == 'صح أو خطأ') {
      children.add(const Text('صح  ☐      خطأ  ☐'));
    } else {
      children.add(const Text('الإجابة: __________________________'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ================= جميع النتائج =================

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
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getResults();
    if (!mounted) return;
    setState(() {
      results = data;
      loading = false;
    });
  }

  Future<void> deleteResult(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف النتيجة'),
        content: const Text('هل تريد حذف هذه النتيجة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    results.removeAt(index);
    await AppStorage.saveResults(results);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar:
              AppBar(title: const Text('نتائج جميع الطلاب'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('لا توجد نتائج حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                                r['studentName']?.toString() ?? 'طالب'),
                            subtitle: Text(
                              '${r['examTitle'] ?? 'اختبار'}\n'
                              '${r['grade'] ?? ''} - ${r['subject'] ?? ''}\n'
                              'الدرجة: ${r['score'] ?? 0} من ${r['total'] ?? 0}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteResult(i),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= السيرة =================

class TeacherBioPage extends StatefulWidget {
  const TeacherBioPage({super.key});

  @override
  State<TeacherBioPage> createState() => _TeacherBioPageState();
}

class _TeacherBioPageState extends State<TeacherBioPage> {
  String? photoBase64;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final value = await AppStorage.getTeacherPhoto();
    if (!mounted) return;
    setState(() {
      photoBase64 = value;
      loading = false;
    });
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  child: Icon(icon, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('عن الأستاذ محمد القاضي'),
            centerTitle: true,
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    // صورة واسم المعلم في أعلى الصفحة.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 86,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              photoBase64 == null || photoBase64!.isEmpty
                                  ? null
                                  : MemoryImage(base64Decode(photoBase64!)),
                          child: photoBase64 == null || photoBase64!.isEmpty
                              ? const Icon(Icons.person, size: 90)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الأستاذ محمد القاضي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'معلم الكيمياء والفيزياء والأحياء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'العلم رسالة، والتعليم أثر يبقى.\n'
                        'نسعى معًا لنجعل المعرفة أقرب، والفهم أعمق، والنجاح ممكنًا لكل طالب.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionCard(
                      icon: Icons.school_outlined,
                      title: 'نبذة عن الأستاذ',
                      child: const Text(
                        'الأستاذ محمد القاضي معلم متخصص في الكيمياء والفيزياء والأحياء، '
                        'يعمل على تقديم العلوم بأسلوب واضح ومنظم يربط المعلومة بالفهم والتطبيق، '
                        'ويحرص على أن تكون التقنية وسيلة حقيقية لتسهيل التعلم ومساعدة الطالب على بناء ثقته بنفسه.',
                        style: TextStyle(fontSize: 17, height: 1.9),
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.workspace_premium_outlined,
                      title: 'السيرة العلمية والمهنية',
                      child: const Text(
                        '• المؤهل العلمي: بكالوريوس تربية.\n'
                        '• التخصص: كيمياء فيزيائية.\n'
                        '• المواد التعليمية: الكيمياء والفيزياء والأحياء.\n'
                        '• جهة العمل: مدرسة النور الأساسية الثانوية بالروحاء - وصاب السافل.\n'
                        '• الاهتمام المهني: تطوير أساليب التعليم، تبسيط المفاهيم العلمية، '
                        'وتوظيف الوسائل والتقنية لخدمة الطالب والمعلم.\n'
                        '• الرؤية التعليمية: بناء طالب يفهم العلم ويستطيع استخدامه، لا طالب يحفظه فقط.',
                        style: TextStyle(fontSize: 17, height: 1.9),
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.lightbulb_outline,
                      title: 'الرؤية التعليمية',
                      child: const Text(
                        'أن يكون التعليم واضحًا، عمليًا، متاحًا، ومحفزًا على التفكير. '
                        'فالهدف ليس جمع المعلومات فقط، بل تحويلها إلى فهم ومهارة وثقة وقدرة على حل المشكلات.',
                        style: TextStyle(fontSize: 17, height: 1.9),
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'رسائل تشجيعية للطلاب',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _MotivationLine(text: 'لا تقل: لا أستطيع، بل قل: سأحاول حتى أستطيع.'),
                          _MotivationLine(text: 'كل مسألة صعبة اليوم، قد تصبح مهارة قوية غدًا.'),
                          _MotivationLine(text: 'الفهم خطوة، والممارسة طريق، والاستمرار هو مفتاح التقدم.'),
                          _MotivationLine(text: 'اجعل كل يوم فرصة لتتعلم شيئًا جديدًا وتقترب من هدفك.'),
                          _MotivationLine(text: 'الخطأ ليس نهاية الطريق؛ الخطأ فرصة لفهم أفضل.'),
                          _MotivationLine(text: 'ثق بقدرتك، نظم وقتك، وابدأ من حيث أنت.'),
                          _MotivationLine(text: 'نجاحك يبدأ بقرار صغير: أن تبدأ اليوم ولا تؤجل.'),
                        ],
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.menu_book_outlined,
                      title: 'رسالة إلى الطالب',
                      child: const Text(
                        'يا طالب العلم، لا تجعل صعوبة البداية سببًا للتراجع. '
                        'اقرأ، افهم، اسأل، جرّب، ثم أعد المحاولة. '
                        'ومع كل درس تتقنه، أنت لا تجمع درجات فقط؛ أنت تبني مستقبلك خطوة بعد خطوة.\n\n'
                        'هذا التطبيق صُمم ليكون رفيقًا تعليميًا يساعدك على الوصول إلى المذكرات والكتب والاختبارات، '
                        'ويمنحك مساحة للتدرب ومراجعة ما تعلمته.',
                        style: TextStyle(fontSize: 17, height: 1.9),
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.contact_mail_outlined,
                      title: 'بيانات التواصل',
                      child: const Text(
                        'الهاتف: 774470090\n'
                        'البريد الإلكتروني: alwsabi97@gmail.com',
                        style: TextStyle(fontSize: 17, height: 1.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'برنامج محمد القاضي التعليمي العلمي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'نتعلم اليوم لنصنع غدًا أفضل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
        ),
      );
}

class _MotivationLine extends StatelessWidget {
  final String text;

  const _MotivationLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle_outline, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}
