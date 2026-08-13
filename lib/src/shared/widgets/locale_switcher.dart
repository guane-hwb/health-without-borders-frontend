// lib/src/shared/widgets/locale_switcher.dart

import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../design/tokens/app_colors.dart';

class LocaleSwitcher extends StatelessWidget {
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context).locale;
    final isEs = locale == 'es';

    return Semantics(
      label: isEs ? 'Cambiar idioma' : 'Change language',
      hint: isEs ? 'Seleccionar español o inglés' : 'Select Spanish or English',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['es', 'en'].map((lang) {
            final selected = locale == lang;
            final langName = lang == 'es' ? 'Español' : 'English';
            return Semantics(
              button: true,
              selected: selected,
              label: langName,
              child: InkWell(
                onTap: () => AppLocale.of(context).setLocale(lang),
                borderRadius: BorderRadius.circular(6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 25,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.primary : AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
