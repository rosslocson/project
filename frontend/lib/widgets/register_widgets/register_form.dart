import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../app_theme.dart';
import 'password_strength_indicator.dart';
import 'register_error_banner.dart';

const kCosmicBlue = Color(0xFF00022E);
const kAccentPurple = Color(0xFF7367F0);

class RegisterForm {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController ojtHoursCtrl;

  final bool obscurePass;
  final bool obscureConfirm;
  final List<String> departments;
  final bool loadingDepts;
  final bool deptsFetched;
  final String? selectedDept;
  final String defaultPosition;

  final String passStrength;
  final Color passColor;
  final double passValue;
  final String? confirmError;

  final AuthProvider auth;

  final VoidCallback onToggleObscurePass;
  final VoidCallback onToggleObscureConfirm;
  final Function(String) onPassChanged;
  final Function(String) onConfirmChanged;
  final Function(String?) onDeptChanged;
  final VoidCallback onRegister;

  RegisterForm({
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.departments,
    required this.loadingDepts,
    required this.deptsFetched,
    required this.selectedDept,
    required this.defaultPosition,
    required this.ojtHoursCtrl,
    required this.passStrength,
    required this.passColor,
    required this.passValue,
    required this.confirmError,
    required this.auth,
    required this.onToggleObscurePass,
    required this.onToggleObscureConfirm,
    required this.onPassChanged,
    required this.onConfirmChanged,
    required this.onDeptChanged,
    required this.onRegister,
  });

  Widget _shimmerDropdown(InputDecoration dec, bool isDark) {
    return DropdownButtonFormField<String>(
<<<<<<< HEAD
      isExpanded: true, // <-- Fix applied here
=======
      isExpanded: true,
>>>>>>> lightmode
      decoration: dec.copyWith(
        filled: true,
        fillColor: isDark ? const Color(0xFF14141D) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
      ),
      hint: Text(
        'Loading...',
        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
        overflow: TextOverflow.ellipsis,
      ),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade300),
      items: const [],
      onChanged: null,
    );
  }

  Widget buildForm({required bool isMobile, required BuildContext context}) {
    final dec = pillInputDecoration();
    final isDark = Theme.of(context).brightness == Brightness.dark;
<<<<<<< HEAD
    const kAccentPurple = Color(0xFF7367F0);

    // Reusable styles
=======

>>>>>>> lightmode
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF00022E),
    );

    final inputTextStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white : Colors.black,
    );

<<<<<<< HEAD
    // Reusable borders
=======
>>>>>>> lightmode
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade300,
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
<<<<<<< HEAD
      borderSide: const BorderSide(
        color: Color(0xFF6366F1), // The purple color when clicked
=======
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF6366F1) : kCosmicBlue,
>>>>>>> lightmode
        width: 2,
      ),
    );

    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
<<<<<<< HEAD
          horizontal: isMobile ? 24 : 64,
          vertical: isMobile ? 24 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : kCosmicBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40), 

              if (auth.error != null) ...[
                RegisterErrorBanner(
                  error: auth.error!,
                  onClear: () => context.read<AuthProvider>().clearError(),
                ),
                const SizedBox(height: 12),
              ],

              // ── First Name / Last Name ──────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('First Name', style: labelStyle),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: firstCtrl,
                        style: inputTextStyle,
                        cursorColor: kAccentPurple,
                        decoration: dec.copyWith(
                          hintText: 'First Name',
                          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                          fillColor: isDark ? const Color(0xFF14141D) : null,
                          enabledBorder: defaultBorder,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
=======
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Stack(
          children: [
            Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CREATE ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : kCosmicBlue,
                      letterSpacing: 1.2,
                    ),
>>>>>>> lightmode
                  ),
                  const SizedBox(height: 40),

                  if (auth.error != null) ...[
                    RegisterErrorBanner(
                      error: auth.error!,
                      onClear: () => context.read<AuthProvider>().clearError(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
<<<<<<< HEAD
                      Text('Last Name', style: labelStyle),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: lastCtrl,
                        style: inputTextStyle,
                        cursorColor: kAccentPurple,
                        decoration: dec.copyWith(
                          hintText: 'Last Name',
                          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                          fillColor: isDark ? const Color(0xFF14141D) : null,
                          enabledBorder: defaultBorder,
                          focusedBorder: focusedBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Email ───────────────────────────────────────────────────
              Text('Email Address', style: labelStyle),
              const SizedBox(height: 4),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Enter Email Address',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  final emailRegex =
                      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Enter a valid email (e.g., name@example.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Department / Required OJT Hours ─────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Department', style: labelStyle),
                          const SizedBox(height: 4),
                          loadingDepts
                              ? _shimmerDropdown(dec, isDark)
                              : DropdownButtonFormField<String>(
                                  isExpanded: true, // <-- Fix applied here
                                  initialValue: selectedDept,
                                  dropdownColor: isDark ? const Color(0xFF14141D) : null,
                                  decoration: dec.copyWith(
                                    fillColor: isDark ? const Color(0xFF14141D) : null,
                                    enabledBorder: defaultBorder,
                                    focusedBorder: focusedBorder,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  hint: Text(
                                    !deptsFetched
                                        ? 'Select Department'
                                        : departments.isEmpty
                                            ? 'None available'
                                            : 'Select Department',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: Colors.grey.shade500),
                                  items: departments
                                      .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              overflow: TextOverflow.ellipsis,
                                              style: inputTextStyle)))
                                      .toList(),
                                  onChanged: onDeptChanged,
=======
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('First Name', style: labelStyle),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: firstCtrl,
                              style: inputTextStyle,
                              cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                              decoration: dec.copyWith(
                                hintText: 'First Name',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
>>>>>>> lightmode
                                ),
                                fillColor: isDark ? const Color(0xFF14141D) : null,
                                enabledBorder: defaultBorder,
                                focusedBorder: focusedBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Last Name', style: labelStyle),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: lastCtrl,
                              style: inputTextStyle,
                              cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                              decoration: dec.copyWith(
                                hintText: 'Last Name',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                fillColor: isDark ? const Color(0xFF14141D) : null,
                                enabledBorder: defaultBorder,
                                focusedBorder: focusedBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text('Email Address', style: labelStyle),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: inputTextStyle,
                    cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                    decoration: dec.copyWith(
                      hintText: 'Enter Email Address',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      fillColor: isDark ? const Color(0xFF14141D) : null,
                      enabledBorder: defaultBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v)) {
                        return 'Enter a valid email (e.g., name@example.com)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Department', style: labelStyle),
                              const SizedBox(height: 4),
                              loadingDepts
                                  ? _shimmerDropdown(dec, isDark)
                                  : DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: selectedDept,
                                      dropdownColor: isDark ? const Color(0xFF14141D) : null,
                                      decoration: dec.copyWith(
                                        fillColor: isDark ? const Color(0xFF14141D) : null,
                                        enabledBorder: defaultBorder,
                                        focusedBorder: focusedBorder,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      ),
                                      hint: Text(
                                        !deptsFetched
                                            ? 'Select Department'
                                            : departments.isEmpty
                                                ? 'None available'
                                                : 'Select Department',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
                                      items: departments
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: inputTextStyle),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: onDeptChanged,
                                    ),
                              if (departments.isEmpty && !loadingDepts && deptsFetched)
                                const Padding(
                                  padding: EdgeInsets.only(left: 22, top: 4),
                                  child: Text(
                                    'No department listed. Please contact the administrator.',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      color: Color.fromARGB(255, 245, 37, 0),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Required OJT Hours', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: ojtHoursCtrl,
                                keyboardType: TextInputType.number,
                                style: inputTextStyle,
                                cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: dec.copyWith(
                                  hintText: 'e.g. 400',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  fillColor: isDark ? const Color(0xFF14141D) : null,
                                  enabledBorder: defaultBorder,
                                  focusedBorder: focusedBorder,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your required OJT hours';
                                  }
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) {
                                    return 'Enter a valid number greater than 0';
                                  }
                                  if (n > 2000) {
                                    return 'Value seems too high — please check';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text('Password', style: labelStyle),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    onChanged: onPassChanged,
                    style: inputTextStyle,
                    cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                    decoration: dec.copyWith(
                      hintText: 'Create a password',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      fillColor: isDark ? const Color(0xFF14141D) : null,
                      enabledBorder: defaultBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Icon(
                            obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          onPressed: onToggleObscurePass,
                        ),
                      ),
                    ),
<<<<<<< HEAD
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Required OJT Hours', style: labelStyle),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: ojtHoursCtrl,
                            keyboardType: TextInputType.number,
                            style: inputTextStyle,
                            cursorColor: kAccentPurple,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: dec.copyWith(
                              hintText: 'e.g. 400',
                              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                              fillColor: isDark ? const Color(0xFF14141D) : null,
                              enabledBorder: defaultBorder,
                              focusedBorder: focusedBorder,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your required OJT hours';
                              }
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) {
                                return 'Enter a valid number greater than 0';
                              }
                              if (n > 2000) {
                                return 'Value seems too high — please check';
                              }
                              return null;
                            },
=======
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Need one uppercase letter';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                      if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Need one special character';
                      }
                      return null;
                    },
                  ),

                  if (passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    PasswordStrengthIndicator(
                      passValue: passValue,
                      passColor: passColor,
                      passStrength: passStrength,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Text('Confirm Password', style: labelStyle),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    onChanged: onConfirmChanged,
                    style: inputTextStyle,
                    cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                    decoration: dec.copyWith(
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      fillColor: isDark ? const Color(0xFF14141D) : null,
                      enabledBorder: defaultBorder,
                      focusedBorder: focusedBorder,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 22,
>>>>>>> lightmode
                          ),
                          onPressed: onToggleObscureConfirm,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  if (confirmError != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        confirmError!,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                  ],
<<<<<<< HEAD
                ),
              ),
              const SizedBox(height: 12),

              // ── Password ────────────────────────────────────────────────
              Text('Password', style: labelStyle),
              const SizedBox(height: 4),
              TextFormField(
                controller: passCtrl,
                obscureText: obscurePass,
                onChanged: onPassChanged,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Create a password',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                          obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 22),
                      onPressed: onToggleObscurePass,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Min 8 characters';
                  if (!v.contains(RegExp(r'[A-Z]'))) {
                    return 'Need one uppercase letter';
                  }
                  if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                  if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Need one special character';
                  }
                  return null;
                },
              ),
              if (passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                PasswordStrengthIndicator(
                    passValue: passValue,
                    passColor: passColor,
                    passStrength: passStrength),
              ],
              const SizedBox(height: 12),

              // ── Confirm Password ────────────────────────────────────────
              Text('Confirm Password', style: labelStyle),
              const SizedBox(height: 4),
              TextFormField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                onChanged: onConfirmChanged,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Confirm password',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 22),
                      onPressed: onToggleObscureConfirm,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              if (confirmError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(confirmError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
              const SizedBox(height: 24),

              // ── Submit ──────────────────────────────────────────────────
              isDark
                  ? SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              kAccentPurple.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    )
                  : BlueButton(
                      label: 'CREATE ACCOUNT',
                      onPressed: auth.isLoading ? null : onRegister,
                      loading: auth.isLoading,
                    ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? kAccentPurple : kCosmicBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
=======

                  const SizedBox(height: 24),

                  // Force identical sizing constraint for both Dark Mode and Light Mode buttons
                  SizedBox(
                    height: 50,
                    child: isDark
                        ? ElevatedButton(
                            onPressed: auth.isLoading ? null : onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: kAccentPurple.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          )
                        : BlueButton(
                            label: 'CREATE ACCOUNT',
                            onPressed: auth.isLoading ? null : onRegister,
                            loading: auth.isLoading,
                          ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: isDark ? kAccentPurple : kCosmicBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
>>>>>>> lightmode
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}