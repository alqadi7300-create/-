import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()=>runApp(const AlqadiApp());
const grades=['الأول الثانوي','الثاني الثانوي','الثالث الثانوي'];
const subjects=['الكيمياء','الفيزياء','الأحياء'];
const kinds=['درس','كتاب ومذكرة','اختبار','بحث','مقال'];
const navy=Color(0xFF172B4D), teal=Color(0xFF267D78), bg=Color(0xFFF5F7FA);

class Entry {
 final String id,title,grade,subject,type,body;
 final String? path;
 Entry({required this.id,required this.title,required this.grade,required this.subject,required this.type,this.body='',this.path});
 Map<String,dynamic> toJson()=>{'id':id,'title':title,'grade':grade,'subject':subject,'type':type,'body':body,'path':path};
 factory Entry.fromJson(Map<String,dynamic> j)=>Entry(id:j['id']??'',title:j['title']??'',grade:j['grade']??grades.first,subject:j['subject']??subjects.first,type:j['type']??'درس',body:j['body']??'',path:j['path']);
}
class Student {
 final String name,code,grade;
 Student(this.name,this.code,this.grade);
 Map<String,dynamic> toJson()=>{'name':name,'code':code,'grade':grade};
 factory Student.fromJson(Map<String,dynamic> j)=>Student(j['name']??'',j['code']??'',j['grade']??grades.first);
}
class Honor {
 final String name,grade,subject,note;
 Honor(this.name,this.grade,this.subject,this.note);
 Map<String,dynamic> toJson()=>{'name':name,'grade':grade,'subject':subject,'note':note};
 factory Honor.fromJson(Map<String,dynamic> j)=>Honor(j['name']??'',j['grade']??grades.first,j['subject']??subjects.first,j['note']??'');
}

class AlqadiApp extends StatelessWidget {
 const AlqadiApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'منصة محمد القاضي العلمية',
 theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:bg,colorScheme:ColorScheme.fromSeed(seedColor:teal),appBarTheme:const AppBarTheme(backgroundColor:bg,foregroundColor:navy,elevation:0),cardTheme:CardThemeData(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:const BorderSide(color:Color(0xFFE5EBF1))))),
 home:const MainPage());
}
class MainPage extends StatefulWidget {const MainPage({super.key});@override State<MainPage> createState()=>_MainPageState();}
class _MainPageState extends State<MainPage>{
 List<Entry> entries=[]; List<Student> students=[]; List<Honor> honors=[];
 Map<String,Map<String,int>> marks={};
 bool teacher=false; int tab=0; String grade=grades.first,subject=subjects.first,query='';
 final search=TextEditingController(),name=TextEditingController(),code=TextEditingController();
 @override void initState(){super.initState();load();}
 @override void dispose(){search.dispose();name.dispose();code.dispose();super.dispose();}
 Future<void> load() async {
  final p=await SharedPreferences.getInstance();
  try{entries=(jsonDecode(p.getString('entries')??'[]') as List).map((x)=>Entry.fromJson(Map<String,dynamic>.from(x))).toList();students=(jsonDecode(p.getString('students')??'[]') as List).map((x)=>Student.fromJson(Map<String,dynamic>.from(x))).toList();honors=(jsonDecode(p.getString('honors')??'[]') as List).map((x)=>Honor.fromJson(Map<String,dynamic>.from(x))).toList();marks=Map<String,Map<String,int>>.from((jsonDecode(p.getString('marks')??'{}') as Map).map((k,v)=>MapEntry(k,Map<String,int>.from(v))));}catch(_){}
  if(mounted)setState((){});
 }
 Future<void> save() async {final p=await SharedPreferences.getInstance();await p.setString('entries',jsonEncode(entries.map((x)=>x.toJson()).toList()));await p.setString('students',jsonEncode(students.map((x)=>x.toJson()).toList()));await p.setString('honors',jsonEncode(honors.map((x)=>x.toJson()).toList()));await p.setString('marks',jsonEncode(marks));}
 Future<void> login() async {code.clear();final v=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('دخول المعلم'),content:TextField(controller:code,obscureText:true,decoration:const InputDecoration(labelText:'رمز المعلم التجريبي')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,code.text.trim()),child:const Text('دخول'))]));if(v=='1234'&&mounted)setState(()=>teacher=true);else if(v!=null&&mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الرمز التجريبي هو 1234؛ يلزم تغييره قبل النشر')));}
 IconData subIcon(String s)=>s=='الكيمياء'?Icons.science_rounded:s=='الفيزياء'?Icons.bolt_rounded:Icons.biotech_rounded;
 IconData kindIcon(String s)=>s=='كتاب ومذكرة'?Icons.menu_book_rounded:s=='اختبار'?Icons.quiz_rounded:s=='بحث'?Icons.manage_search_rounded:s=='مقال'?Icons.article_rounded:Icons.play_lesson_rounded;
 Future<void> addEntry(String kind) async {
  final t=TextEditingController(),b=TextEditingController();String g=grade,s=subject;String? path;
  final ok=await showDialog<bool>(context:context,builder:(d)=>StatefulBuilder(builder:(d,refresh)=>AlertDialog(title:Text('إضافة '+kind),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
   TextField(controller:t,decoration:const InputDecoration(labelText:'العنوان')),const SizedBox(height:8),
   DropdownButtonFormField<String>(value:g,decoration:const InputDecoration(labelText:'المستوى'),items:grades.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>refresh(()=>g=v??g)),const SizedBox(height:8),
   DropdownButtonFormField<String>(value:s,decoration:const InputDecoration(labelText:'المادة'),items:subjects.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>refresh(()=>s=v??s)),const SizedBox(height:8),
   TextField(controller:b,minLines:3,maxLines:7,decoration:const InputDecoration(labelText:'النص أو الوصف')),OutlinedButton.icon(onPressed:()async{final f=await FilePicker.platform.pickFiles();if(f!=null)refresh(()=>path=f.files.single.path);},icon:const Icon(Icons.upload_file),label:Text(path==null?'اختيار ملف':'تم اختيار ملف'))
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))])));
  if(ok==true&&t.text.trim().isNotEmpty){setState(()=>entries.insert(0,Entry(id:DateTime.now().microsecondsSinceEpoch.toString(),title:t.text.trim(),grade:g,subject:s,type:kind,body:b.text.trim(),path:path)));await save();}t.dispose();b.dispose();
 }
 Future<void> addStudent() async {name.clear();final n=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text('طالب جديد — '+grade),content:TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الطالب')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,name.text.trim()),child:const Text('توليد الكود'))]));if(n!=null&&n.isNotEmpty){final suffix=DateTime.now().millisecondsSinceEpoch.toString();final c=(grade==grades[0]?'1':grade==grades[1]?'2':'3')+suffix.substring(suffix.length-6);setState(()=>students.add(Student(n,c,grade)));await save();if(mounted)showDialog<void>(context:context,builder:(d)=>AlertDialog(title:const Text('كود التسجيل'),content:SelectableText('الطالب: '+n+'\nالكود: '+c),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('تم'))]));}}
 Future<void> addHonor() async {final n=TextEditingController(),note=TextEditingController();String s=subject;final ok=await showDialog<bool>(context:context,builder:(d)=>StatefulBuilder(builder:(d,refresh)=>AlertDialog(title:Text('إضافة متفوق — '+grade),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'اسم الطالب')),DropdownButtonFormField<String>(value:s,decoration:const InputDecoration(labelText:'المادة'),items:subjects.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>refresh(()=>s=v??s)),TextField(controller:note,decoration:const InputDecoration(labelText:'الدرجة أو ملاحظة'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))])));if(ok==true&&n.text.trim().isNotEmpty){setState(()=>honors.add(Honor(n.text.trim(),grade,s,note.text.trim())));await save();}n.dispose();note.dispose();}
 Future<void> editMark(Student st) async {final c=TextEditingController(text:(marks[st.code]?[subject]??0).toString());final v=await showDialog<int>(context:context,builder:(d)=>AlertDialog(title:Text('درجة '+st.name),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الدرجة')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,int.tryParse(c.text)),child:const Text('حفظ'))]));if(v!=null){setState(()=>marks.putIfAbsent(st.code,()=>{})[subject]=v);await save();}c.dispose();}
 Future<void> download(Entry e) async {try{final d=await getApplicationDocumentsDirectory();final safe=e.title.replaceAll(RegExp(r'[^\w\- ء-ي]'),'_');final f=File(d.path+'/'+(safe.isEmpty?'lesson':safe)+'.txt');await f.writeAsString(e.title+'\n'+e.grade+' • '+e.subject+' • '+e.type+'\n\n'+e.body);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ النص محليًا ويمكن قراءته دون إنترنت من قسم المحفوظات داخل التطبيق.'))); }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر حفظ المحتوى')));}}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('منصة محمد القاضي العلمية',style:TextStyle(fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:teacher?()=>setState(()=>teacher=false):login,icon:Icon(teacher?Icons.admin_panel_settings:Icons.person_outline),tooltip:'لوحة المعلم')]),body:IndexedStack(index:tab,children:[home(),library(),honorPage(),adminPage()]),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),label:'الرئيسية'),NavigationDestination(icon:Icon(Icons.local_library_outlined),label:'المكتبة'),NavigationDestination(icon:Icon(Icons.emoji_events_outlined),label:'الأوائل'),NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'المعلم')])));

 Widget tile(IconData icon,String title,String sub,VoidCallback tap)=>Card(child:ListTile(onTap:tap,contentPadding:const EdgeInsets.all(10),leading:Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFE7F2F0),borderRadius:BorderRadius.circular(15)),child:Icon(icon,color:teal)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_left)));
 Widget home()=>ListView(padding:const EdgeInsets.all(16),children:[
  Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[navy,teal]),borderRadius:BorderRadius.circular(26)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('من المعرفة تبدأ الرحلة',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w900)),SizedBox(height:8),Text('كتب وأبحاث ومقالات ودروس علمية في مساحة واحدة.',style:TextStyle(color:Colors.white,height:1.6))])),
  const SizedBox(height:20),const Text('المستويات الدراسية',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:navy)),...grades.map((g)=>tile(Icons.school_rounded,g,'الكيمياء • الفيزياء • الأحياء',()=>setState(()=>grade=g))),
  const SizedBox(height:12),const Text('المواد',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:navy)),...subjects.map((s)=>tile(subIcon(s),s,'الدروس والكتب والاختبارات',()=>setState(()=>subject=s))),tile(Icons.menu_book,'المكتبة العلمية','تصفّح المحتوى',()=>setState(()=>tab=1))
 ]);
 Widget library()=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('الدروس والمكتبة',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:12),
  DropdownButtonFormField<String>(value:grade,decoration:const InputDecoration(labelText:'المستوى الدراسي'),items:grades.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>grade=v??grade)),
  const SizedBox(height:8),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:subjects.map((s)=>Padding(padding:const EdgeInsets.only(left:8),child:ChoiceChip(label:Text(s),selected:subject==s,onSelected:(_)=>setState(()=>subject=s)))).toList())),
  const SizedBox(height:8),TextField(controller:search,onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'بحث في العناوين والنصوص')),
  const SizedBox(height:12),...entries.where((e)=>e.grade==grade&&e.subject==subject&&(e.title+' '+e.body).contains(query)).map((e)=>Card(child:ListTile(onTap:()=>showDialog<void>(context:context,builder:(d)=>AlertDialog(title:Text(e.title),content:SingleChildScrollView(child:Text(e.body.isEmpty?'لا يوجد وصف نصي.':e.body)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إغلاق'))])),leading:Icon(kindIcon(e.type),color:teal),title:Text(e.title),subtitle:Text(e.type+' • '+e.grade+' • '+e.subject),trailing:IconButton(tooltip:'تحميل النص',icon:const Icon(Icons.download_for_offline_outlined),onPressed:()=>download(e))))),
  if(entries.where((e)=>e.grade==grade&&e.subject==subject&&(e.title+' '+e.body).contains(query)).isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('لا يوجد محتوى مضاف لهذا المستوى والمادة حتى الآن.',textAlign:TextAlign.center))
 ]);
 Widget adminPage()=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('لوحة المعلم',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:8),
  if(!teacher)FilledButton.icon(onPressed:login,icon:const Icon(Icons.lock_open),label:const Text('دخول المعلم')),
  if(teacher)...[
   DropdownButtonFormField<String>(value:grade,decoration:const InputDecoration(labelText:'المستوى الدراسي'),items:grades.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>grade=v??grade)),
   const SizedBox(height:12),const Text('افتح المادة لإدارة محتواها',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),...subjects.map((s)=>tile(subIcon(s),s,'لوحة '+s+' — '+grade,()=>setState(()=>subject=s))),
   Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(grade+' / '+subject,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:navy)),
    action(Icons.people_alt_outlined,'الطلاب والأكواد','إضافة طالب وتوليد كود تسجيل',addStudent),
    action(Icons.menu_book_outlined,'الدروس','إضافة درس نصي',()=>addEntry('درس')),
    action(Icons.library_books_outlined,'الكتب والملازم','إضافة مرجع أو ملف',()=>addEntry('كتاب ومذكرة')),
    action(Icons.quiz_outlined,'الاختبارات','إضافة سجل اختبار',()=>addEntry('اختبار')),
    action(Icons.assessment_outlined,'النتائج','إدخال درجات الطلاب',()=>showDialog<void>(context:context,builder:(d)=>AlertDialog(title:Text('النتائج — '+subject),content:SizedBox(width:360,child:ListView(shrinkWrap:true,children:students.where((s)=>s.grade==grade).map((s)=>ListTile(title:Text(s.name),subtitle:Text('الكود: '+s.code),trailing:Text((marks[s.code]?[subject]??0).toString()),onTap:()=>editMark(s))).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إغلاق'))]))),
    action(Icons.emoji_events_outlined,'الطلاب الأوائل','إضافة اسم إلى لوحة الشرف',addHonor),
   ]))),
   const SizedBox(height:12),const Text('طلاب المستوى',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),...students.where((s)=>s.grade==grade).map((s)=>Card(child:ListTile(title:Text(s.name),subtitle:SelectableText('كود التسجيل: '+s.code),trailing:IconButton(icon:const Icon(Icons.edit_note),onPressed:()=>editMark(s))))),
  ]
 ]);
 Widget action(IconData i,String t,String sub,VoidCallback f)=>ListTile(onTap:f,contentPadding:EdgeInsets.zero,leading:Icon(i,color:teal),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_left));
 Widget honorPage()=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('لوحة الشرف',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:navy)),
  DropdownButtonFormField<String>(value:grade,decoration:const InputDecoration(labelText:'المستوى الدراسي'),items:grades.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>grade=v??grade)),
  ...subjects.map((s)=>ExpansionTile(leading:Icon(subIcon(s),color:teal),title:Text('أوائل '+s),children:honors.where((h)=>h.grade==grade&&h.subject==s).isEmpty?[const ListTile(title:Text('لم تتم إضافة أسماء بعد'))]:honors.where((h)=>h.grade==grade&&h.subject==s).map((h)=>ListTile(leading:const Icon(Icons.emoji_events,color:Color(0xFFC58A24)),title:Text(h.name),subtitle:Text(h.note))).toList())),
  if(teacher)FilledButton.icon(onPressed:addHonor,icon:const Icon(Icons.add),label:const Text('إضافة طالب متفوق'))
 ]);
}
