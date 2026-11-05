import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final QuranThemeColors colors = context.quranColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Руководство и подсказки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: <Widget>[
          // Header intro
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: colors.deepGreen,
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.gold.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: colors.gold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mubeen Quran Pure',
                        style: TextStyle(
                          color: const Color(0xFFF4EAD5),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Краткий гид по всем возможностям и жестам для комфортного чтения.',
                        style: TextStyle(
                          color: const Color(
                            0xFFF4EAD5,
                          ).withValues(alpha: 0.82),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Ayah Card Actions
          _GuideSection(
            title: '1. Работа с аятом и изучение',
            icon: Icons.touch_app_rounded,
            colors: colors,
            items: const <_GuideItem>[
              _GuideItem(
                icon: Icons.notes_rounded,
                title: 'Тафсир ас-Саади',
                description:
                    'Нажмите иконку блокнота возле аята, чтобы открыть авторитетное толкование смыслов шейха ас-Саади на русском языке.',
              ),
              _GuideItem(
                icon: Icons.translate_rounded,
                title: 'Пословный разбор',
                description:
                    'Нажмите иконку перевода для грамматического разбора каждого слова: дословный перевод, арабский корень, лемма и часть речи.',
              ),
              _GuideItem(
                icon: Icons.copy_rounded,
                title: 'Копирование аята',
                description:
                    'Нажмите иконку копирования, чтобы скопировать арабский текст и русский перевод с точной ссылкой на суру и аят.',
              ),
              _GuideItem(
                icon: Icons.bookmark_border_rounded,
                title: 'Закладки',
                description:
                    'Нажмите на закладку, чтобы сохранить аят. Все сохранённые аяты доступны во вкладке «Навигация» ➔ «Закладки».',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 2: Auto Scroll
          _GuideSection(
            title: '2. Чтение без рук (Автопрокрутка)',
            icon: Icons.speed_rounded,
            colors: colors,
            items: const <_GuideItem>[
              _GuideItem(
                icon: Icons.play_arrow_rounded,
                title: 'Запуск автопрокрутки',
                description:
                    'В режиме свитка нажмите круглую кнопку ▷ в правом нижнем углу экрана — текст начнёт плавно прокручиваться сам.',
              ),
              _GuideItem(
                icon: Icons.pause_rounded,
                title: 'Мгновенная пауза',
                description:
                    'Одно касание в любое место экрана или на саму кнопку моментально ставит автопрокрутку на паузу.',
              ),
              _GuideItem(
                icon: Icons.tune_rounded,
                title: 'Регулировка скорости',
                description:
                    'Используйте кнопки «–» и «+» на панели автопрокрутки или слайдер в «Настройках» (от 1 до 12 строк в минуту).',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 3: Two Reading Modes
          _GuideSection(
            title: '3. Два режима чтения',
            icon: Icons.view_carousel_rounded,
            colors: colors,
            items: const <_GuideItem>[
              _GuideItem(
                icon: Icons.view_agenda_rounded,
                title: 'Построчный свиток (Flow)',
                description:
                    'Непрерывный поток аятов суры с отображением перевода, автопрокруткой, пословным разбором и возможностью выделить текст.',
              ),
              _GuideItem(
                icon: Icons.auto_stories_rounded,
                title: 'Классический Мусхаф (604 страницы)',
                description:
                    'Постраничная вёрстка Мединского мусхафа с пагинацией и арабской нумерацией аятов. Идеально для заучивания (хифз).',
              ),
              _GuideItem(
                icon: Icons.swap_horiz_rounded,
                title: 'Переключение режимов',
                description:
                    'Переключайтесь между свитком и страницами в один клик через кнопку в правом верхнем углу экрана чтения.',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 4: Smart Search
          _GuideSection(
            title: '4. Умный поиск по всей Книге',
            icon: Icons.manage_search_rounded,
            colors: colors,
            items: const <_GuideItem>[
              _GuideItem(
                icon: Icons.search_rounded,
                title: 'Арабский поиск без огласовок',
                description:
                    'Ищите по арабскому тексту в любом виде — с огласовками (харакятами) или обычным вводом с клавиатуры (например: «الله», «اهدنا الصراط»).',
              ),
              _GuideItem(
                icon: Icons.menu_book_outlined,
                title: 'Поиск по сурам и переводам',
                description:
                    'Вводите название суры (например: «Бакара», «Ясин», «Пещера») или ключевые слова перевода («терпение», «намаз», «милость»).',
              ),
              _GuideItem(
                icon: Icons.link_rounded,
                title: 'Быстрый переход по номерам',
                description:
                    'Вводите ссылки вида «2:255», «18.10», «36:1» или «сура 67 аят 1» для мгновенного открытия нужного аята.',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 5: Themes & Settings
          _GuideSection(
            title: '5. Темы и забота о зрении',
            icon: Icons.palette_outlined,
            colors: colors,
            items: const <_GuideItem>[
              _GuideItem(
                icon: Icons.color_lens_outlined,
                title: '4 благородные темы',
                description:
                    '«Пергамент» (классическая тёплая бумага), «Изумруд» (глубокий зелёный), «OLED» (чистый чёрный для экономии заряда) и «Светлая».',
              ),
              _GuideItem(
                icon: Icons.nightlight_round,
                title: 'Защита глаз (Ночной фильтр)',
                description:
                    'Включает мягкий янтарный оттенок на всём экране для комфортного чтения в темноте без синего спектра.',
              ),
              _GuideItem(
                icon: Icons.format_size_rounded,
                title: 'Размеры текста',
                description:
                    'В «Настройках» можно отдельно настроить размер арабского шрифта (24–56 px) и русского перевода (13–28 px).',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.icon,
    required this.colors,
    required this.items,
  });

  final String title;
  final IconData icon;
  final QuranThemeColors colors;
  final List<_GuideItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.ornament.withValues(alpha: 0.15),
        border: Border.all(
          color: colors.ornament.withValues(alpha: 0.7),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Icon(icon, color: colors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
            itemBuilder: (BuildContext context, int index) {
              final _GuideItem item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.gold.withValues(alpha: 0.12),
                      ),
                      child: Icon(item.icon, size: 17, color: colors.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: colors.ink.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuideItem {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
