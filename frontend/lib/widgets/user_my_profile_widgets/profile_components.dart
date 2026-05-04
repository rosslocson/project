// lib/widgets/user_profile/profile_components.dart

import 'package:flutter/material.dart';

class ProfileSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const ProfileSectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), letterSpacing: 0.3),
        ),
      ],
    );
  }
}

class CleanInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isMultiline;

  const CleanInfoCard({super.key, required this.label, required this.value, this.icon, this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: isEmpty ? Colors.grey.shade400 : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: isMultiline ? 1.5 : 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class SkillPanelClean extends StatelessWidget {
  final String label;
  final String raw;
  final Color accentColor;
  final Color bgColor;

  const SkillPanelClean({super.key, required this.label, required this.raw, required this.accentColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          CleanSkillChips(raw: raw, accentColor: accentColor, bgColor: bgColor),
        ],
      ),
    );
  }
}

class CleanSkillChips extends StatelessWidget {
  final String raw;
  final Color accentColor;
  final Color bgColor;

  const CleanSkillChips({super.key, required this.raw, required this.accentColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    if (raw == '—' || raw.trim().isEmpty) {
      return Text('—', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w400));
    }

    final skills = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: accentColor)),
      )).toList(),
    );
  }
}

class QuickInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const QuickInfoTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blueAccent.shade100, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.60), letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileRetryBanner extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;

  const ProfileRetryBanner({super.key, required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, color: Colors.orange.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(color: Colors.orange.shade900, fontSize: 12))),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }
}