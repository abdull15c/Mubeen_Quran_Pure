import 'package:flutter/material.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 12),
          const Icon(Icons.menu_book_rounded, size: 54),
          const SizedBox(height: 16),
          const Text(
            'Mubeen Quran Pure',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(l.aboutAppDescription, textAlign: TextAlign.center),
          const SizedBox(height: 36),
          Text(
            l.aboutDataSources,
            style: TextStyle(
              color: context.quranColors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          _SourceCard(
            title: l.sourceUthmaniTitle,
            description: l.sourceUthmaniDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceKulievTitle,
            description: l.sourceKulievDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceAbuAdelTitle,
            description: l.sourceAbuAdelDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceTafsirTitle,
            description: l.sourceTafsirDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(title: l.sourceFontTitle, description: l.sourceFontDesc),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceFontKfgqpcTitle,
            description: l.sourceFontKfgqpcDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceFontSerifTitle,
            description: l.sourceFontSerifDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceMorphologyTitle,
            description: l.sourceMorphologyDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceAudioTitle,
            description: l.sourceAudioDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceOnlineApiTitle,
            description: l.sourceOnlineApiDesc,
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: l.sourceSpeechTitle,
            description: l.sourceSpeechDesc,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'Mubeen Quran Pure',
                applicationVersion: '1.1.0',
              );
            },
            icon: const Icon(Icons.description_outlined, size: 20),
            label: Text(l.viewLicenses),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
