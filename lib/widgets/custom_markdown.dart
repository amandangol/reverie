import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;
  final Color? textColor;
  final Color? headingColor;
  final double? fontSize;
  final double? headingFontSize;
  final double? lineSpacing;
  final double? paragraphSpacing;

  const CustomMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
    this.textColor,
    this.headingColor,
    this.fontSize,
    this.headingFontSize,
    this.lineSpacing,
    this.paragraphSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ?? Colors.white;
    final defaultHeadingColor = headingColor ?? Colors.amberAccent;
    final defaultFontSize = fontSize ?? 14.0;
    final defaultHeadingFontSize = headingFontSize ?? 18.0;
    final defaultLineSpacing = lineSpacing ?? 1.5;
    final defaultParagraphSpacing = paragraphSpacing ?? 16.0;

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: defaultTextColor,
          fontSize: defaultFontSize,
          height: defaultLineSpacing,
        ),
        h1: TextStyle(
          color: defaultHeadingColor,
          fontSize: defaultHeadingFontSize * 1.5,
          fontWeight: FontWeight.bold,
          height: defaultLineSpacing,
        ),
        h2: TextStyle(
          color: defaultHeadingColor,
          fontSize: defaultHeadingFontSize * 1.3,
          fontWeight: FontWeight.bold,
          height: defaultLineSpacing,
        ),
        h3: TextStyle(
          color: defaultHeadingColor,
          fontSize: defaultHeadingFontSize,
          fontWeight: FontWeight.bold,
          height: defaultLineSpacing,
        ),
        strong: TextStyle(
          color: defaultTextColor,
          fontWeight: FontWeight.bold,
          fontSize: defaultFontSize,
        ),
        em: TextStyle(
          color: defaultTextColor.withOpacity(0.7),
          fontStyle: FontStyle.italic,
          fontSize: defaultFontSize,
        ),
        listBullet: TextStyle(
          color: defaultTextColor,
          fontSize: defaultFontSize,
        ),
        blockquote: TextStyle(
          color: defaultTextColor.withOpacity(0.7),
          fontStyle: FontStyle.italic,
          fontSize: defaultFontSize,
        ),
        code: TextStyle(
          color: defaultHeadingColor,
          backgroundColor: Colors.white10,
          fontSize: defaultFontSize,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(4),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: defaultHeadingColor.withOpacity(0.5),
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16),
        blockSpacing: defaultParagraphSpacing,
      ),
    );
  }
}
