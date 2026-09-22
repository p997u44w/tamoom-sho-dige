import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import 'class_picker_screen.dart';
import 'feature_screens.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل معلم',
      subtitle: 'کلاس‌های شما، از پایه پایین به بالا',
      items: [
        DashboardItem(
          title: 'کلاس‌های من',
          icon: Icons.class_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherClassesScreen())),
        ),
        DashboardItem(
          title: 'تکلیف/ویدیو جدید',
          icon: Icons.assignment_add,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssignmentScreen())),
        ),
        DashboardItem(
          title: 'کلاس آنلاین',
          icon: Icons.videocam_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassPickerScreen(role: 'teacher'))),
        ),
        DashboardItem(
          title: 'پیام‌ها',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
        ),
      ],
    );
  }
}
