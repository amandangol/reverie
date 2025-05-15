import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final bool showMenu;
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.showMenu = true,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return AppBar(
      leading: showMenu
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  if (onMenuPressed != null) {
                    onMenuPressed!();
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
            )
          : null,
      title: Text(
        title,
        style: journalTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.background,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
