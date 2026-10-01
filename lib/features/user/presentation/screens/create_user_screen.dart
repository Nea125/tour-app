
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/user_provider.dart';
import '../../../../core/constants/app_spacing.dart';

enum UserRole {
  manager,
  guide,
  customer;

  String get label {
    switch (this) {
      case UserRole.manager:
        return 'Manager';
      case UserRole.guide:
        return 'Guide';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String get value {
    switch (this) {
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.guide:
        return 'GUIDE';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }
}

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime _dateOfBirth = DateTime(DateTime.now().year - 25);

  Gender _gender = Gender.other;

  // Default role
  UserRole _role = UserRole.customer;

  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final error = await ref
        .read(userListControllerProvider.notifier)
        .createUser(
          userName: _userNameController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _gender,
          dateOfBirth: _dateOfBirth,

          // Selected role
          role: _role.value,
        );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (v) =>
                        Validators.required(v, label: 'First name'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (v) =>
                        Validators.required(v, label: 'Last name'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s16),

            CustomTextField(
              controller: _userNameController,
              label: 'Username',
              validator: (v) =>
                  Validators.required(v, label: 'Username'),
            ),

            const SizedBox(height: AppSpacing.s16),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
              validator: Validators.password,
            ),

            const SizedBox(height: AppSpacing.s16),

            CustomTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),

            const SizedBox(height: AppSpacing.s16),

            CustomTextField(
              controller: _phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),

            const SizedBox(height: AppSpacing.s16),

            // =========================
            // ROLE
            // =========================
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              items: UserRole.values.map((role) {
                return DropdownMenuItem<UserRole>(
                  value: role,
                  child: Text(role.label),
                );
              }).toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _role = value);
                      }
                    },
            ),

            const SizedBox(height: AppSpacing.s16),

            // =========================
            // GENDER
            // =========================
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender.label),
                );
              }).toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _gender = value);
                      }
                    },
            ),

            const SizedBox(height: AppSpacing.s16),

            // =========================
            // DATE OF BIRTH
            // =========================
            InkWell(
              onTap: _submitting ? null : _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${_dateOfBirth.year}-'
                  '${_dateOfBirth.month.toString().padLeft(2, '0')}-'
                  '${_dateOfBirth.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s24),

            // =========================
            // CREATE USER
            // =========================
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: AppSpacing.s20,
                      width: AppSpacing.s20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }
}