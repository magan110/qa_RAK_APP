import 'package:flutter/material.dart';

class AppTheme {
  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;

  // Font weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Font colors
  static const Color primaryText = Colors.black;
  static const Color secondaryText = Colors.grey;
  static const Color accentText = Colors.blue;
  static const Color successText = Colors.green;
  static const Color errorText = Colors.red;

  // Example TextStyles
  static const TextStyle headline = TextStyle(
    fontSize: fontSizeXLarge,
    fontWeight: fontWeightBold,
    color: primaryText,
  );

  static const TextStyle title = TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightBold,
    color: primaryText,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: primaryText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: secondaryText,
  );

  static const TextStyle success = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightBold,
    color: successText,
  );

  static const TextStyle error = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightBold,
    color: errorText,
  );
}
