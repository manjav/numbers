import 'package:flutter/material.dart';
import 'package:numbers/utils/utils.dart';

enum TColors { black, white, whiteFlat, yellow, blue, orange, green }

extension TColorsExt on TColors {
  List<Color> get value {
    switch (this) {
      case TColors.black:
        return [
          const Color(0xFF2c3134),
          const Color(0xBB000000),
          const Color(0xFF1F2326),
          const Color(0xFF23272A),
        ];
      case TColors.white:
        return [
          const Color(0xFFFDFDFD),
          const Color(0xFFDDDDDD),
          const Color(0xFFCCCCCC),
          const Color(0xFFFFFFFF)
        ];
      case TColors.whiteFlat:
        return [const Color(0xFFFDFDFD), const Color(0xFFFDFDFD), const Color(0xFFCCCCCC)];
      case TColors.yellow:
        return [const Color(0xFFFFC000), const Color(0xFFFE8C0F), const Color(0xFFEB6D0A)];
      case TColors.blue:
        return [const Color(0xFF00B0F0), const Color(0xFF0070C0), const Color(0xFF00619F)];
      case TColors.orange:
        return [const Color(0xFFEC8838), const Color(0xFFFA3838), const Color(0xFFD92A26)];
      case TColors.green:
        return [const Color(0xFF81D33c), const Color(0xFF00A550), const Color(0xFF0A903D)];
    }
  }
}

class Themes {
  static style(Color color, double fontSize,
      {String? font, List<Shadow>? shadows}) {
    return TextStyle(
        color: color,
        fontSize: fontSize,
        decoration: TextDecoration.none,
        fontFamily: font ?? "quicksand",
        shadows: shadows ??
            [
              BoxShadow(
                  color: Colors.black.withAlpha(150),
                  blurRadius: 3,
                  offset: const Offset(0.5, 2))
            ]);
  }

  static ThemeData get darkData {
    var textTheme = TextTheme(
        caption: TextStyle(color: TColors.white.value[2], fontSize: 16.d),
        button: style(TColors.black.value[0], 24.d, shadows: []),
        bodyText1: style(TColors.black.value[0], 22.d, shadows: []),
        bodyText2: style(TColors.black.value[0], 20.d, shadows: []),
        subtitle1: style(TColors.black.value[0], 16.d, shadows: []),
        subtitle2: style(TColors.black.value[0], 14.d, shadows: []),
        headline1: style(TColors.white.value[3], 56.d),
        headline2: style(TColors.white.value[3], 36.d),
        headline3: style(TColors.white.value[3], 30.d),
        headline4: style(TColors.white.value[3], 24.d),
        headline5: style(TColors.white.value[3], 20.d),
        headline6: style(TColors.white.value[3], 16.d),
        overline: style(TColors.white.value[3], 32.d, font: "icons"));

    // var iconTheme = IconThemeData(color: primaries[50]);
    return ThemeData(
      textTheme: textTheme,
      progressIndicatorTheme: ProgressIndicatorThemeData(
          linearTrackColor: TColors.white.value[0],
          color: TColors.orange.value[0]),
      // primarySwatch: darkMaterial,
      // iconTheme: iconTheme,
      // appBarTheme: AppBarTheme(
      //     backgroundColor: primaries[700],
      //     textTheme: textTheme,
      //     iconTheme: iconTheme),
      // floatingActionButtonTheme: FloatingActionButtonThemeData(
      //     backgroundColor: primaries[500], foregroundColor: primaries[100]),
      // sliderTheme: SliderThemeData(
      //     thumbColor: primaries[300],
      //     activeTrackColor: primaries[700],
      //     inactiveTrackColor: primaries[700],
      //     overlayColor: primaries[700]),
      // textButtonTheme: TextButtonThemeData(
      //     style: ButtonStyle(
      //         foregroundColor:
      //             MaterialStateProperty.resolveWith(getTextButtonColor),
      //         textStyle: MaterialStateProperty.all<TextStyle>(TextStyle(
      //             fontFamily: "quicksand",
      //             fontSize: 18,
      //             fontWeight: FontWeight.bold)))),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: TColors.blue.value[0],
          selectionHandleColor: TColors.blue.value[0],
          selectionColor: TColors.blue.value[2]),
      snackBarTheme: SnackBarThemeData(
          contentTextStyle: textTheme.headline5,
          // actionTextColor: primaries[500],
          backgroundColor: TColors.blue.value[2]),
      inputDecorationTheme: InputDecorationTheme(hintStyle: textTheme.caption),
      fontFamily: "quicksand",
      dialogBackgroundColor: TColors.black.value[1],
      // accentColor: primaries[0],
      // buttonColor: primaries[600],
      // scaffoldBackgroundColor: primaries[900],
      backgroundColor: TColors.black.value[2],
      dialogTheme: DialogTheme(backgroundColor: TColors.black.value[1]),
      cardColor: TColors.white.value[0],
      // primaryColor: primaries[700],
      // focusColor: primaries[750],
      // canvasColor: TColors.orange.value[2],
      colorScheme: const ColorScheme.dark(
          // primary: primaries[700],
          // onPrimary: Colors.white,
          // primaryVariant: Colors.teal[50],
          // background: primaries[900],
          // onBackground: primaries[800],
          // surface: Colors.red,
          // secondary: Colors.teal[50],
          // onSecondary: Colors.red,
          // secondaryVariant: Colors.red,
          ),
    );
  }

  // static MaterialColor get material =>
  //     MaterialColor(primaries[500]!.value, primaries);
  // static MaterialColor get darkMaterial =>
  //     MaterialColor(primaries[900]!.value, primaries);
}
