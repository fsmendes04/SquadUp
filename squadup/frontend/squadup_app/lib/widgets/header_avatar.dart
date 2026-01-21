import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'avatar_group.dart';
import '../config/responsive_utils.dart';

class HeaderAvatar extends StatelessWidget {
  final Color darkBlue;
  final String title;
  final String groupId;
  final String? avatarUrl;
  final VoidCallback? onBack;
  final double avatarRadius;

  const HeaderAvatar({
    super.key,
    required this.darkBlue,
    required this.title,
    required this.groupId,
    this.avatarUrl,
    this.onBack,
    this.avatarRadius = 31,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: r.symmetricPadding(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: kToolbarHeight + 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: darkBlue, size: 32),
                    onPressed: onBack ?? () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Center(
                    child: AvatarGroupWidget(
                      groupId: groupId,
                      avatarUrl: avatarUrl,
                      radius: avatarRadius,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
