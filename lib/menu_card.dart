import 'package:flutter/material.dart';
import 'app_colors.dart';

// ホーム画面の各機能への入り口として使う、色付きの角丸カード。
class MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final SectionPalette palette;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: palette.icon.withOpacity(0.15),
                child: Icon(icon, color: palette.icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.text.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.text.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
