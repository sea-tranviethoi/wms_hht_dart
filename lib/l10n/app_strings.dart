import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/language_provider.dart';
import 'strings_en.dart';
import 'strings_ja.dart';

class AppStrings {
  static dynamic of(BuildContext context) {
    final locale = context.watch<LanguageProvider>().locale;
    return locale.languageCode == 'ja' ? const StringsJa() : const StringsEn();
  }

  static dynamic ofWithoutWatch(BuildContext context) {
    final locale = context.read<LanguageProvider>().locale;
    return locale.languageCode == 'ja' ? const StringsJa() : const StringsEn();
  }
}

