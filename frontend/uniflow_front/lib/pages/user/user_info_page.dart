import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student_info.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _gradeController;
  late final TextEditingController _majorController;

  String? _selectedCollege;
  String? _selectedAcademy;
  String? _selectedGradeYear;

  @override
  void initState() {
    super.initState();
    final studentInfo = context.read<UserProvider>().studentInfo;
    _gradeController =
        TextEditingController(text: studentInfo?.grade?.toString() ?? '');
    _majorController = TextEditingController(text: studentInfo?.major ?? '');
    _selectedCollege = studentInfo?.college;
    _selectedAcademy = studentInfo?.academy;
    _selectedGradeYear = studentInfo?.gradeYear;
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final grade = int.tryParse(_gradeController.text.trim());
    if (grade == null) {
      return;
    }

    final info = StudentInfo(
      grade: grade,
      college: _selectedCollege,
      academy: _selectedAcademy,
      major: _majorController.text.trim(),
      gradeYear: _selectedGradeYear,
    );
    await context.read<UserProvider>().saveStudentInfo(info);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('个人信息已保存并立即生效'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '入学年份',
                  hintText: '例如 2023',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return '请输入入学年份';
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                    return '入学年份必须是 4 位数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollege,
                decoration: const InputDecoration(labelText: '所属学院'),
                items: AppConstants.collegeOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请选择所属学院';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedAcademy,
                decoration: const InputDecoration(labelText: '所属书院'),
                items: AppConstants.academyOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAcademy = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请选择所属书院';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _majorController,
                decoration: const InputDecoration(
                  labelText: '所学专业',
                  hintText: '例如 人工智能',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return '请输入专业名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedGradeYear,
                decoration: const InputDecoration(labelText: '年级阶段'),
                items: AppConstants.gradeYears
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGradeYear = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请选择年级阶段';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.large),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存信息'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
