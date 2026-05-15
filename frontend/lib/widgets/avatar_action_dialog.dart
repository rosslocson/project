import 'package:flutter/material.dart';

const _kBlue = Color(0xFF00022E);
// Extracted colors from the provided dark mode image
const _kDarkBg = Color(0xFF0B0D17); 
const _kDarkPurple = Color(0xFF6E62E5); 

class AvatarActionDialog extends StatelessWidget {
  const AvatarActionDialog({
    super.key,
    this.currentAvatarUrl,
  });

  final String? currentAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = currentAvatarUrl;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // --- Dynamic Theme Colors ---
    final Color bgColor = isDark ? _kDarkBg : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    final Color primaryBtnColor = isDark ? _kDarkPurple : _kBlue;
    const Color primaryBtnTextColor = Colors.white;
    
    final Color outlineBtnBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color outlineBtnTextColor = isDark ? Colors.white : Colors.black87;
    
    final Color avatarBorderColor = isDark ? const Color(0xFF1F2235) : Colors.grey.shade200;
    final Color avatarPlaceholderBg = isDark ? Colors.white.withOpacity(0.05) : _kBlue.withOpacity(0.1);
    final Color avatarIconColor = isDark ? Colors.white54 : _kBlue;
    final Color shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.25);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 380,
          maxHeight: 450,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current avatar preview - MUCH BIGGER
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarBorderColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: avatarPlaceholderBg,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: primaryBtnColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: avatarPlaceholderBg,
                              child: Icon(
                                Icons.person,
                                size: 70,
                                color: avatarIconColor,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: avatarPlaceholderBg,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: avatarIconColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Title - NO camera icon
              Text(
                'Update Avatar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Choose an action to update your profile photo.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtnColor,
                    foregroundColor: primaryBtnTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Upload from device',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryBtnTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop('remove'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    side: BorderSide(color: outlineBtnBorderColor, width: 1.5),
                    foregroundColor: outlineBtnTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Remove avatar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: outlineBtnTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}