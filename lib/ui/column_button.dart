import 'package:flutter/material.dart';

class ColumnButton extends StatelessWidget {
  final String text;
  final bool selected;
  final double fontSize;
  final Color selectedBgColor;
  final Color selectedFontColor;

  ColumnButton({Key key,
    this.text,
    this.selected,
    this.fontSize = 18,
    this.selectedBgColor,
    this.selectedFontColor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: selected
            ? selectedBgColor ?? Colors.grey[400]
            : Colors.transparent,
//        border: selected ? Border.all(color: Colors.grey, style: BorderStyle.solid) : null
      ),
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected
                ? selectedFontColor ?? Colors.grey[700]
                : Colors.grey[700],
            fontSize: fontSize
          )
        )
      )
    );
  }
}
