import 'package:flutter/material.dart';

class LanguagesPage extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const LanguagesPage({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  String _selectedLanguage = 'fr';

  final Map<String, String> _languages = {
    'fr': 'Français',
    'en': 'English',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage =
        Localizations.localeOf(context).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Langues'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Sélectionnez la langue de l’application :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              items: _languages.entries
                  .map(
                    (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLanguage = val;
                  });

                  widget.onLanguageChanged(val);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
