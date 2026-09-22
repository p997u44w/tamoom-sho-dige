import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PeopleDirectoryScreen extends StatefulWidget {
  const PeopleDirectoryScreen({super.key});
  @override
  State<PeopleDirectoryScreen> createState() => _PeopleDirectoryScreenState();
}

class _PeopleDirectoryScreenState extends State<PeopleDirectoryScreen> {
  List schools = [];
  List adminSchools = [];
  int? selectedSchoolId;
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    final user = await ApiService.currentUser;
    final isAdmin = user?['role'] == 'admin';
    if (isAdmin && schools.isEmpty) {
      final sr = await ApiService.get('admin/list-schools');
      if (sr['success'] == true) {
        adminSchools = sr['data'] ?? [];
        selectedSchoolId ??= adminSchools.isNotEmpty ? int.tryParse('${adminSchools.first['id']}') : null;
      }
    }
    final path = isAdmin && selectedSchoolId != null
        ? 'hub/school-people?school_id=$selectedSchoolId'
        : 'school/people';
    final r = await ApiService.get(path);
    if (mounted) {
      if (r['success'] == true) {
        setState(() { loading = false; schools = r['data']?['schools'] ?? []; });
      } else {
        setState(() { loading = false; error = r['message'] ?? 'خطا در دریافت اطلاعات'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userFuture = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('افراد و سوابق مدرسه')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userFuture,
        builder: (context, snap) {
          final isAdmin = snap.data?['role'] == 'admin';
          return loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: error != null
                      ? ListView(children: [const SizedBox(height: 120), Center(child: Text('خطا: ')), Center(child: Text(error!))])
                      : ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            if (isAdmin && adminSchools.isNotEmpty)
                              DropdownButtonFormField<int>(
                                value: selectedSchoolId,
                                decoration: const InputDecoration(labelText: 'انتخاب مدرسه'),
                                items: adminSchools.map<DropdownMenuItem<int>>((x) => DropdownMenuItem(value: int.tryParse('${x['id']}'), child: Text(x['name'] ?? ''))).toList(),
                                onChanged: (v) { selectedSchoolId = v; load(); },
                              ),
                            const SizedBox(height: 12),
                            ..._buildDirectory(),
                          ],
                        ),
                );
        },
      ),
    );
  }

  List<Widget> _buildDirectory() {
    // After school/people, schools is normalized to entries containing school/teachers/students.
    if (schools.isEmpty || schools.first is! Map || schools.first['school'] == null) {
      return [const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('اطلاعاتی برای نمایش وجود ندارد'))];
    }
    final result = <Widget>[];
    for (final block in schools) {
      final school = block['school'] ?? {};
      final teachers = block['teachers'] ?? [];
      final students = block['students'] ?? [];
      result.add(Card(child: ListTile(
        leading: const Icon(Icons.school_rounded),
        title: Text(school['name'] ?? 'مدرسه'),
        subtitle: Text('معلم: ${teachers.length}  •  دانش‌آموز: ${students.length}'),
      )));
      result.add(const SizedBox(height: 8));
      result.add(const Text('معلم‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      for (final t in teachers) {
        final classes = (t['classes'] as List? ?? []).map((c) => c['name']).whereType<String>().join('، ');
        result.add(Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(t['full_name'] ?? ''),
          subtitle: Text('کد ملی: ${t['national_code'] ?? '-'}\nتلفن: ${t['phone'] ?? '-'}\nکلاس‌ها: ${classes.isEmpty ? '-' : classes}'),
          isThreeLine: true,
        )));
      }
      result.add(const SizedBox(height: 8));
      result.add(const Text('دانش‌آموزان و سوابق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      for (final s in students) {
        result.add(Card(child: ExpansionTile(
          leading: const CircleAvatar(child: Icon(Icons.school)),
          title: Text(s['full_name'] ?? ''),
          subtitle: Text('کلاس: ${s['class_name'] ?? '-'}  •  کد ملی: ${s['national_code'] ?? '-'}'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('تلفن: ${s['phone'] ?? '-'}'),
                Text('میانگین تکالیف: ${s['assignments_average'] ?? '-'}'),
                Text('امتیاز: ${s['points_total'] ?? 0}'),
                const SizedBox(height: 8),
                const Text('تاریخچه تکالیف', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(s['assignment_history'] as List? ?? []).map((a) => ListTile(
                  dense: true,
                  title: Text(a['title'] ?? ''),
                  subtitle: Text('ثبت: ${a['submitted_at'] ?? 'ارسال نشده'} • نمره: ${a['score'] ?? '-'} / ${a['max_score'] ?? '-'}${a['is_late'] == 1 ? ' • دیرکرد' : ''}'),
                )),
                const Divider(),
                const Text('تاریخچه امتحان‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(s['exam_history'] as List? ?? []).map((e) => ListTile(dense: true, title: Text(e['title'] ?? ''), subtitle: Text('نمره: ${e['score'] ?? '-'} • ${e['submitted_at'] ?? 'شرکت نکرده'}'))),
              ]),
            )
          ],
        )));
      }
    }
    return result;
  }
}
