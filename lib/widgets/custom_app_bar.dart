import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final bool showMenu;
  final VoidCallback? onMenuPressed;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final double? titleSpacing;
  final TextStyle? titleStyle;
  final double? toolbarHeight;
  final Color? foregroundColor;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.showMenu = true,
    this.onMenuPressed,
    this.flexibleSpace,
    this.bottom,
    this.systemOverlayStyle,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.titleSpacing,
    this.titleStyle,
    this.toolbarHeight,
    this.foregroundColor,
    this.shadowColor,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    // Memoize the title style
    final defaultTitleStyle = journalTextTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: foregroundColor ?? colorScheme.onSurface,
      fontSize: 20,
      letterSpacing: 0.15,
    );

    return AppBar(
      leading: showMenu
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: foregroundColor ?? colorScheme.onSurface,
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
          : leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: titleStyle ?? defaultTitleStyle,
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.background,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      systemOverlayStyle: systemOverlayStyle,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) +
            (bottom?.preferredSize.height ?? 0.0),
      );
}
