import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
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
    _gradeController = TextEditingController(text: studentInfo?.grade?.toString() ?? '');
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

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.infoSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalInfo)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.entryYear,
                  hintText: l10n.entryYearHint,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return l10n.entryYearRequired;
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                    return l10n.entryYearInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollege,
                decoration: InputDecoration(labelText: l10n.college),
                items: AppConstants.collegeOptions.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.collegeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedAcademy,
                decoration: InputDecoration(labelText: l10n.academy),
                items: AppConstants.academyOptions.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAcademy = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.academyRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _majorController,
                decoration: InputDecoration(
                  labelText: l10n.major,
                  hintText: l10n.majorHint,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return l10n.majorRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedGradeYear,
                decoration: InputDecoration(labelText: l10n.gradeYear),
                items: AppConstants.gradeYears.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGradeYear = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.gradeYearRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.large),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.saveInfo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

