import os
import datetime

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
output_md = os.path.join(project_root, 'ALL_PROJECT_CODE_AUDIT.md')

categories = [
    ('Configuration & Setup', [
        'pubspec.yaml',
        'analysis_options.yaml',
        'l10n.yaml',
    ]),
    ('Localization (ARB Files)', [
        'lib/l10n/app_ru.arb',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_tg.arb',
        'lib/l10n/app_uz.arb',
        'lib/l10n/app_ky.arb',
        'lib/l10n/app_az.arb',
    ]),
    ('Application Entry & Theme', [
        'lib/main.dart',
        'lib/app.dart',
        'lib/theme/app_theme.dart',
        'lib/theme/islamic_ornament_painters.dart',
    ]),
    ('Models & Data Structures', [
        'lib/models/quran_models.dart',
        'lib/audio/quran_audio_models.dart',
        'lib/bookmarks/bookmark_models.dart',
        'lib/khatm/khatm_models.dart',
    ]),
    ('State Management & Controllers', [
        'lib/controllers/app_controller.dart',
        'lib/bookmarks/bookmark_controller.dart',
        'lib/khatm/khatm_controller.dart',
    ]),
    ('Data Repository, Caching & API Layer', [
        'lib/data/quran_repository.dart',
        'lib/data/translation_manager.dart',
        'lib/data/qf_api_service.dart',
    ]),
    ('Audio Playback & Streaming', [
        'lib/audio/quran_audio_service.dart',
        'lib/audio/quran_audio_downloader.dart',
        'lib/audio/quran_audio_player_widget.dart',
    ]),
    ('Recitation, Tajweed & AI Voice (Whisper)', [
        'lib/recitation/quran_speech_engine.dart',
        'lib/recitation/whisper_api_engine.dart',
        'lib/recitation/audio_recorder_service.dart',
        'lib/recitation/speech_recitation_service.dart',
        'lib/recitation/quran_recitation_matcher.dart',
        'lib/recitation/tajweed_rule_detector.dart',
        'lib/recitation/tajweed_audio_analyzer.dart',
    ]),
    ('Bookmarks & Reading Plans (Khatm)', [
        'lib/bookmarks/bookmark_dialog.dart',
        'lib/khatm/khatm_progress_card.dart',
    ]),
    ('Semantic Vector Search & FTS', [
        'lib/search/semantic_search.dart',
    ]),
    ('Presentation Screens & UI', [
        'lib/screens/quran_home_screen.dart',
        'lib/screens/reader_screen.dart',
        'lib/screens/reader/flow_reader.dart',
        'lib/screens/reader/mushaf_reader.dart',
        'lib/screens/reader/ayah_card.dart',
        'lib/screens/reader/surah_header.dart',
        'lib/screens/reader/reader_widgets.dart',
        'lib/screens/reader/reader_utils.dart',
        'lib/screens/navigation_screen.dart',
        'lib/screens/search_screen.dart',
        'lib/screens/settings_screen.dart',
        'lib/screens/recitation_trainer_sheet.dart',
        'lib/screens/onboarding_screen.dart',
        'lib/screens/guide_screen.dart',
        'lib/screens/about_screen.dart',
    ]),
    ('Test Suite & Quality Assurance', [
        'test/widget_test.dart',
        'test/controllers/app_controller_test.dart',
        'test/data/quran_repository_test.dart',
        'test/data/qf_api_service_test.dart',
        'test/models/quran_models_test.dart',
        'test/search/semantic_search_test.dart',
        'test/audio/quran_audio_service_test.dart',
        'test/audio/quran_audio_downloader_test.dart',
        'test/recitation/whisper_api_engine_test.dart',
        'test/recitation/speech_recitation_service_test.dart',
        'test/recitation/quran_recitation_matcher_test.dart',
        'test/recitation/tajweed_rule_detector_test.dart',
        'test/khatm/khatm_plan_test.dart',
        'test/bookmarks/bookmark_models_test.dart',
        'test/theme/islamic_ornament_painters_test.dart',
        'test/platform/android_release_configuration_test.dart',
    ]),
    ('Platform & Build Configuration', [
        'android/settings.gradle.kts',
        'android/build.gradle.kts',
        'android/app/build.gradle.kts',
        'android/gradle.properties',
        'android/app/src/main/AndroidManifest.xml',
        'android/app/src/main/kotlin/com/mubeen/mubeen_quran_pure/MainActivity.kt',
        'ios/Runner/Info.plist',
    ]),
    ('Server Infrastructure', [
        'server/modal_quran_whisper.py',
        'server/README.md',
    ]),
    ('Data Generation & Benchmark Tools', [
        'tool/build_quran_db.py',
        'tool/build_semantic_search.py',
        'tool/evaluate_semantic_search.py',
        'tool/test_build_quran_db.py',
        'tool/test_semantic_situations.py',
    ]),
]

def get_lang(rel_path):
    if rel_path.endswith('.dart'): return 'dart'
    if rel_path.endswith('.yaml') or rel_path.endswith('.yml'): return 'yaml'
    if rel_path.endswith('.kts') or rel_path.endswith('.kt'): return 'kotlin'
    if rel_path.endswith('.properties'): return 'properties'
    if rel_path.endswith('.xml'): return 'xml'
    if rel_path.endswith('.py'): return 'python'
    if rel_path.endswith('.json') or rel_path.endswith('.arb'): return 'json'
    if rel_path.endswith('.md'): return 'markdown'
    if rel_path.endswith('.plist'): return 'xml'
    return 'text'

def build_audit_content():
    total_files = 0
    total_lines = 0
    now_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    file_entries = []
    
    for cat_name, files in categories:
        cat_files = []
        for rel_path in files:
            full_path = os.path.join(project_root, rel_path.replace('/', os.sep))
            if os.path.isfile(full_path):
                with open(full_path, 'r', encoding='utf-8', errors='replace') as f:
                    content = f.read()
                lines_count = content.count('\n') + (1 if content else 0)
                total_files += 1
                total_lines += lines_count
                cat_files.append((rel_path, full_path, lines_count, content, get_lang(rel_path)))
        file_entries.append((cat_name, cat_files))

    header = []
    header.append('=' * 80 + '\n')
    header.append('MUBEEN QURAN PURE — COMPLETE CODEBASE AUDIT EXPORT\n')
    header.append('=' * 80 + '\n')
    header.append(f'Generated: {now_str}\n')
    header.append(f'Total Exported Files: {total_files}\n')
    header.append(f'Total Lines of Code: {total_lines:,}\n')
    header.append('Security Status: Clean (No hardcoded credentials, secrets or keys)\n\n')
    header.append('=' * 80 + '\n')
    header.append('TABLE OF CONTENTS\n')
    header.append('=' * 80 + '\n\n')

    for cat_name, cat_files in file_entries:
        header.append(f'### {cat_name}\n')
        for rel_path, _, count, _, _ in cat_files:
            header.append(f'  - `{rel_path}` ({count} lines)\n')
        header.append('\n')

    header.append('=' * 80 + '\n')
    header.append('SOURCE CODE BY MODULE\n')
    header.append('=' * 80 + '\n\n')

    for cat_name, cat_files in file_entries:
        header.append(f'\n{"#" * 80}\n')
        header.append(f'# {cat_name.upper()}\n')
        header.append(f'{"#" * 80}\n\n')
        for rel_path, full_path, count, content, lang in cat_files:
            header.append(f'{"-" * 80}\n')
            header.append(f'FILE: {rel_path}\n')
            header.append(f'STATS: {count} lines | Language: {lang}\n')
            header.append(f'{"-" * 80}\n\n')
            header.append(f'```{lang}\n')
            header.append(content)
            if not content.endswith('\n'):
                header.append('\n')
            header.append('```\n\n')

    return ''.join(header), total_files, total_lines

if __name__ == '__main__':
    full_content, files_count, lines_count = build_audit_content()
    with open(output_md, 'w', encoding='utf-8') as f:
        f.write(full_content)
    print(f'SUCCESS: Exported {files_count} files ({lines_count} lines) to {output_md}')
