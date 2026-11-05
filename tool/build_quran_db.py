#!/usr/bin/env python3
"""Build and validate the Quran-only SQLite asset."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import re
import shutil
import sqlite3
import tempfile
from pathlib import Path


QURAN_TABLES = (
    "surahs",
    "ayahs",
    "translations",
    "quran_wbw",
    "tafsir_saadi",
    "thematic_topics",
    "thematic_ayahs",
)

ARABIC_MARKS = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]")

SCHEMA_VERSION = 2
CONTENT_VERSION = "2"

WBW_FIXES = {
    (2, 181, 14): "يَعْلَمُونَ",
    (8, 6, 12): "يَنظُرُونَ",
    (13, 37, 20): "وَاقٍ",
}

SURAH_RUSSIAN_TRANSLITS = {
    1: "Аль-Фатиха Фатиха Открывающая",
    2: "Аль-Бакара Бакара Корова",
    3: "Аль Имран Али Имран Семейство Имрана",
    4: "Ан-Ниса Ниса Женщины",
    5: "Аль-Маида Маида Трапеза",
    6: "Аль-Ан'ам Аль-Анам Анам Скот",
    7: "Аль-А'раф Аль-Араф Араф Ограды Преграды",
    8: "Аль-Анфаль Анфаль Трофеи Добыча",
    9: "Ат-Тауба Ат-Тавба Тауба Тавба Покаяние",
    10: "Юнус Йунус",
    11: "Худ",
    12: "Юсуф Йусуф",
    13: "Ар-Ра'д Ар-Рад Рад Гром",
    14: "Ибрахим Ибрагим",
    15: "Аль-Хиджр Хиджр",
    16: "Ан-Нахль Нахль Пчелы Пчёлы",
    17: "Аль-Исра Исра Ночной перенос",
    18: "Аль-Кахф Кахф Пещера",
    19: "Марьям Мариам",
    20: "Та Ха Таха",
    21: "Аль-Анбия Анбия Пророки",
    22: "Аль-Хадж Хадж Паломничество",
    23: "Аль-Му'минун Аль-Муминун Муминун Верующие",
    24: "Ан-Нур Нур Свет",
    25: "Аль-Фуркан Фуркан Различение",
    26: "Аш-Шу'ара Аш-Шуара Шуара Поэты",
    27: "Ан-Намль Намль Муравьи",
    28: "Аль-Касас Касас Рассказ Повествование",
    29: "Аль-Анкабут Анкабут Паук",
    30: "Ар-Рум Рум Римляне Рим",
    31: "Лукман Локман",
    32: "Ас-Саджда Саджда Поклон Земной поклон",
    33: "Аль-Ахзаб Ахзаб Союзники Сонмы",
    34: "Саба Сава",
    35: "Фатыр Фатир Творец Ангелы",
    36: "Йа Син Ясин Йасин Я Син",
    37: "Ас-Саффат Саффат Выстроившиеся в ряды",
    38: "Сад Сод",
    39: "Аз-Зумар Зумар Толпы Сонмы",
    40: "Гафир Аль-Му'мин Аль-Мумин Прощающий Верующий",
    41: "Фуссилят Фуссилат Разъяснены",
    42: "Аш-Шура Шура Совет",
    43: "Аз-Зухруф Зухруф Украшения",
    44: "Ад-Духан Духан Дым",
    45: "Аль-Джасия Джасия Коленопреклоненные",
    46: "Аль-Ахкаф Ахкаф Барханы Пески",
    47: "Мухаммад Мухаммед",
    48: "Аль-Фатх Фатх Победа",
    49: "Аль-Худжурат Худжурат Комнаты Покои",
    50: "Каф",
    51: "Аз-Зарият Зарият Рассеивающие прах",
    52: "Ат-Тур Тур Гора",
    53: "Ан-Наджм Наджм Звезда",
    54: "Аль-Камар Камар Месяц Луна",
    55: "Ар-Рахман Рахман Милостивый",
    56: "Аль-Ваки'а Аль-Вакиа Вакиа Ваки'а Событие Падающее",
    57: "Аль-Хадид Хадид Железо",
    58: "Аль-Муджадиля Муджадиля Муджадила Препирающаяся",
    59: "Аль-Хашр Хашр Сбор Изгнание",
    60: "Аль-Мумтахана Мумтахана Испытуемая",
    61: "Ас-Сафф Сафф Ряды",
    62: "Аль-Джуму'а Аль-Джумуа Джума Пятница Собрание",
    63: "Аль-Мунафикун Мунафикун Лицемеры",
    64: "Ат-Тагабун Тагабун Взаимное обделение",
    65: "Ат-Таляк Ат-Талак Талак Развод",
    66: "Ат-Тахрим Тахрим Запрещение",
    67: "Аль-Мульк Мульк Табарак Власть Царство",
    68: "Аль-Калям Аль-Калам Калям Письменная трость Нун",
    69: "Аль-Хакка Хакка Неминуемое",
    70: "Аль-Ма'аридж Аль-Мааридж Мааридж Ступени",
    71: "Нух",
    72: "Аль-Джинн Джинн Джинны",
    73: "Аль-Муззаммиль Муззаммиль Закутавшийся",
    74: "Аль-Муддассир Муддассир Завернувшийся",
    75: "Аль-Кыяма Аль-Кияма Кыяма Кияма Воскресение",
    76: "Аль-Инсан Инсан Человек Ад-Дахр Дахр Время",
    77: "Аль-Мурсалят Мурсалят Посылаемые",
    78: "Ан-Наба Наба Весть Великая весть",
    79: "Ан-Нази'ат Ан-Назиат Назиат Исторгающие",
    80: "Абаса Нахмурился",
    81: "Ат-Таквир Таквир Скручивание",
    82: "Аль-Инфитар Инфитар Раскалывание",
    83: "Аль-Мутаффифин Мутаффифин Обвешивающие",
    84: "Аль-Иншикак Иншикак Разверзнется Раскалывание",
    85: "Аль-Бурудж Бурудж Созвездия Башни",
    86: "Ат-Тарик Тарик Ночной путник",
    87: "Аль-А'ля Аль-Аля Аля Всевышний",
    88: "Аль-Гашия Гашия Покрывающее",
    89: "Аль-Фаджр Фаджр Заря",
    90: "Аль-Баляд Аль-Балад Баляд Балад Город",
    91: "Аш-Шамс Шамс Солнце",
    92: "Аль-Лейль Лейль Ночь",
    93: "Ад-Духа Духа Утро",
    94: "Аш-Шарх Шарх Раскрытие Аль-Инширах Инширах",
    95: "Ат-Тин Тин Смоковница Инжир",
    96: "Аль-Аляк Аляк Сгусток",
    97: "Аль-Кадр Кадр Предопределение Могущество",
    98: "Аль-Баййина Аль-Байина Баййина Байина Ясное знамение",
    99: "Аз-Зальзаля Аз-Залзаля Зальзаля Залзала Сотрясение Землетрясение",
    100: "Аль-Адият Адият Скачущие",
    101: "Аль-Кари'а Аль-Кариа Кариа Великое бедствие Сокрушающая",
    102: "Ат-Такасур Такасур Охота к умножению Страсть к приумножению",
    103: "Аль-Аср Аср Время Предвечернее время Эпоха",
    104: "Аль-Хумаза Хумаза Хулитель Клеветник",
    105: "Аль-Филь Филь Слон",
    106: "Курайш Курейш",
    107: "Аль-Ма'ун Аль-Маун Маун Подаяние Мелкая помощь",
    108: "Аль-Каусар Каусар Изобилие",
    109: "Аль-Кафирун Кафирун Неверующие",
    110: "Ан-Наср Наср Помощь",
    111: "Аль-Масад Масад Пальмовые волокна Аль-Ляхаб Лахаб Таббат",
    112: "Аль-Ихляс Аль-Ихлас Ихляс Ихлас Очищение веры Искренность",
    113: "Аль-Фаляк Аль-Фалак Фаляк Фалак Рассвет",
    114: "Ан-Нас Нас Люди",
}

THEMATIC_TOPICS_DATA = [{'id': 'comfort_peace',
  'category': 'Духовное состояние',
  'title': 'Утешение и покой',
  'description': 'Аяты при грусти, тревоге, душевной тяжести и поиске покоя',
  'icon_name': 'spa_rounded',
  'sort_order': 1,
  'keywords': 'грусть печаль тоска тяжело на душе тревога депрессия боль успокоение мир покой '
              'надежда выход из трудности отчаяние утешение сердце облегчение плачу нет сил '
              'безысходность',
  'ayahs': [(94, 5, 'Поистине, за каждой тягостью наступает облегчение.'),
            (94, 6, 'За каждой тягостью наступает облегчение.'),
            (13, 28, 'Разве не поминанием Аллаха утешаются сердца?'),
            (2, 286, 'Аллах не возлагает на душу сверх ее возможностей.'),
            (65, 2, 'Тому, кто боится Аллаха, Он создает выход из любого положения.'),
            (3,
             139,
             'Не падайте духом и не печальтесь, ведь вы будете на высоте, если вы верующие.'),
            (93, 3, 'Не покинул тебя твой Господь и не возненавидел.'),
            (2, 216, 'Быть может, вам неприятно то, что является благом для вас.')]},
 {'id': 'forgiveness_repentance',
  'category': 'Поклонение и очищение',
  'title': 'Покаяние и прощение',
  'description': 'Как просить прощения, надежда на безграничную милость Аллаха',
  'icon_name': 'volunteer_activism_rounded',
  'sort_order': 2,
  'keywords': 'прощение покаяние тауба грех ошибки согрешил как покаяться если согрешил милость '
              'Аллаха надежда очищение простить искреннее покаяние стыдно',
  'ayahs': [(39, 53, 'Не теряйте надежды на милость Аллаха. Поистине, Аллах прощает все грехи.'),
            (3, 135, 'Тем, которые совершив грех, вспомнили Аллаха и попросили прощения.'),
            (4,
             110,
             'Кто совершит зло, а затем попросит у Аллаха прощения, найдет Аллаха Прощающим, '
             'Милосердным.'),
            (25, 70, 'Их злые деяния Аллах заменит добрыми, ведь Аллах — Прощающий, Милосердный.'),
            (11, 114, 'Воистину, добрые деяния удаляют дурные.')]},
 {'id': 'patience_trials',
  'category': 'Жизненные ситуации',
  'title': 'Испытания и терпение (Сабр)',
  'description': 'Стойкость в трудностях, награда за терпение и мудрость невзгод',
  'icon_name': 'balance_rounded',
  'sort_order': 3,
  'keywords': 'терпение сабр испытания трудности стойкость беда горе потеря преодоление награда за '
              'терпение',
  'ayahs': [(2,
             155,
             'Мы непременно испытаем вас страхом, голодом, потерей имущества, людей и плодов. '
             'Обрадуй же терпеливых!'),
            (2, 156, 'Которые говорят: «Поистине, мы принадлежим Аллаху и к Нему возвращаемся».'),
            (39, 10, 'Воистину, терпеливым их награда воздастся полностью без счета.'),
            (2, 45, 'Обратитесь за помощью к терпению и намазу.'),
            (3,
             200,
             'О те, которые уверовали! Будьте терпеливы, запасайтесь терпением и бойтесь '
             'Аллаха.')]},
 {'id': 'family_parents',
  'category': 'Отношения',
  'title': 'Родители и семья',
  'description': 'Почитание отца и матери, доброта к родным и воспитание детей',
  'icon_name': 'family_restroom_rounded',
  'sort_order': 4,
  'keywords': 'родители мать отец папа мама уважение к родителям старость родителей доброта к '
              'матери воспитание детей семья родные',
  'ayahs': [(17,
             23,
             'Не говори родителям даже «Уф!», не кричи на них, а говори с ними уважительно.'),
            (17,
             24,
             'Склони пред ними крыло смирения по милосердию и говори: «Господи! Помилуй их, ведь '
             'они воспитывали меня маленьким».'),
            (31,
             14,
             'Мы заповедали человеку делать добро родителям. Мать носила его с тягостью...'),
            (46, 15, 'Мать носила его с тягостью и родила с тягостью.'),
            (25, 74, 'Даруй нам отраду глаз в наших супругах и потомках.')]},
 {'id': 'marriage_spouse',
  'category': 'Отношения',
  'title': 'Брак, любовь и согласие',
  'description': 'Отношения мужа и жены, взаимное милосердие, никях и права',
  'icon_name': 'favorite_rounded',
  'sort_order': 5,
  'keywords': 'муж жена брак никях любовь в семье отношения согласие милосердие покой ссора права '
              'супругов развод махр',
  'ayahs': [(30,
             21,
             'Он создал для вас супруг из вас самих, чтобы вы находили в них покой, и установил '
             'между вами любовь и милосердие.'),
            (4, 19, 'Живите с ними достойно.'),
            (2, 187, 'Они — одеяние для вас, а вы — одеяние для них.'),
            (4, 34, 'Мужчины являются попечителями женщин...')]},
 {'id': 'gratitude_shukr',
  'category': 'Духовное состояние',
  'title': 'Благодарность (Шукр)',
  'description': 'Признание милостей Создателя и приумножение благ',
  'icon_name': 'auto_awesome_rounded',
  'sort_order': 6,
  'keywords': 'благодарность шукр милость Аллаха альхамдулиллях приумножение благ признание '
              'щедрость довольство',
  'ayahs': [(14, 7, 'Если вы будете благодарны, то Я одарю вас еще большим.'),
            (2,
             152,
             'Поминайте Меня, и Я буду помнить о вас. Благодарите Меня и не будьте неблагодарны.'),
            (55, 13, 'Какую же из милостей вашего Господа вы считаете ложью?'),
            (16, 18, 'Если вы станете считать милости Аллаха, то не сосчитаете их.'),
            (31, 12, 'Кто благодарен, тот благодарен во благо себе.')]},
 {'id': 'prayer_dhikr',
  'category': 'Поклонение и очищение',
  'title': 'Намаз, дуа и поминание',
  'description': 'Связь со Всевышним, ответ на мольбы и утренний/вечерний зикр',
  'icon_name': 'mosque_rounded',
  'sort_order': 7,
  'keywords': 'намаз молитва дуа зикр поминание Аллаха мольба ответ на дуа как просить обращение к '
              'Богу тахарат вуду омовение',
  'ayahs': [(2, 186, 'Я близок и отвечаю на зов молящегося, когда он взывает ко Мне.'),
            (40, 60, 'Взывайте ко Мне, и Я отвечу вам.'),
            (29, 45, 'Совершай намаз. Поистине, намаз оберегает от мерзости и предосудительного.'),
            (20, 14, 'Совершай намаз, чтобы помнить обо Мне.'),
            (5, 6, 'Когда вы встаете на намаз, то умойте ваши лица и ваши руки до локтей...')]},
 {'id': 'sustenance_rizq',
  'category': 'Жизненные ситуации',
  'title': 'Пропитание и достаток (Ризк)',
  'description': 'Удел от Аллаха, честный заработок и избавление от бедности',
  'icon_name': 'grain_rounded',
  'sort_order': 8,
  'keywords': 'нет денег ризк пропитание достаток заработок работа бедность удел богатство '
              'упование таваккуль',
  'ayahs': [(65,
             3,
             'И наделит его пропитанием оттуда, откуда он даже не предполагает. Тому, кто уповает '
             'на Аллаха, достаточно Его.'),
            (51,
             58,
             'Поистине, Аллах является Наделяющим уделом, Обладателем могущества, Крепким.'),
            (11, 6, 'Нет на земле ни одного живого существа, чье пропитание не было бы у Аллаха.'),
            (62,
             10,
             'Разойдитесь по земле, ищите милости Аллаха и поминайте Аллаха многократно.')]},
 {'id': 'debt_contracts',
  'category': 'Жизненные ситуации',
  'title': 'Долги, договоры и торговля',
  'description': 'Правила записи долга, честность в сделках и возврат доверенного',
  'icon_name': 'receipt_long_rounded',
  'sort_order': 9,
  'keywords': 'деньги в долг расписка договор кредит проценты риба ростовщичество торговля сделка '
              'отсрочка должнику честность',
  'ayahs': [(2,
             282,
             'Если вы заключаете договор о долге на определенный срок, то записывайте его...'),
            (2,
             280,
             'Если должник находится в трудном положении, то дайте ему отсрочку, пока его '
             'положение не улучшится.'),
            (2, 275, 'Аллах дозволил торговлю и запретил лихоимство (риба).'),
            (5, 1, 'О те, которые уверовали! Будьте верны договорам.'),
            (17, 34, 'Будьте верны обещаниям, ибо за обещания спросят.')]},
 {'id': 'charity_sadaqah',
  'category': 'Поклонение и очищение',
  'title': 'Милостыня и доброта (Садака)',
  'description': 'Помощь нуждающимся, сиротам, благотворительность и закят',
  'icon_name': 'handshake_rounded',
  'sort_order': 10,
  'keywords': 'милостыня садака закят помощь бедным сироты благотворительность щедрость добрые '
              'дела расходование',
  'ayahs': [(2,
             261,
             'Притчей о тех, кто расходует свое имущество на пути Аллаха, является притча о зерне, '
             'из которого выросло семь колосьев...'),
            (2,
             271,
             'Если вы раздаете милостыню открыто, то это прекрасно. Но если вы скрываете это и '
             'раздаете ее неимущим, то это еще лучше для вас.'),
            (3,
             92,
             'Вы не обретете благочестия, пока не будете расходовать из того, что вы любите.'),
            (93, 9, 'Посему не притесняй сироту и не прогоняй просящего.')]},
 {'id': 'health_healing',
  'category': 'Жизненные ситуации',
  'title': 'Здоровье, исцеление и упование',
  'description': 'Исцеление через Коран, молитва при болезни и таваккуль',
  'icon_name': 'healing_rounded',
  'sort_order': 11,
  'keywords': 'болезнь исцеление шифа здоровье дуа при болезни лекарство заболел выздоровление '
              'Айюб защита от сглаза',
  'ayahs': [(17,
             82,
             'Мы ниспосылаем в Коране то, что является исцелением и милостью для верующих.'),
            (26, 80, 'А когда я заболею, Он исцеляет меня.'),
            (21,
             83,
             'Айюб воззвал к своему Господу: «Меня коснулась беда, а ведь Ты — Милосерднейший из '
             'милосердных!»'),
            (10,
             57,
             'К вам явилось увещевание от вашего Господа, исцеление для того, что в груди.')]},
 {'id': 'prophets_stories',
  'category': 'Знания и мудрость',
  'title': 'Истории пророков',
  'description': 'Уроки стойкости, вера и примеры пророков от Адама до Мухаммада ﷺ',
  'icon_name': 'menu_book_rounded',
  'sort_order': 12,
  'keywords': 'истории пророков Муса Юсуф Ибрахим Нух Иса Мухаммад пример стойкость наставление '
              'притчи Корана',
  'ayahs': [(12, 111, 'В повествовании о них содержится назидание для обладающих разумом.'),
            (21, 107, 'Мы отправили тебя только как милость для миров.'),
            (33, 21, 'В Посланнике Аллаха был прекрасный пример для вас...'),
            (11,
             120,
             'Мы рассказываем тебе все это из повествований о посланниках, чтобы укрепить твое '
             'сердце.')]},
 {'id': 'paradise_hereafter',
  'category': 'Вера и вечность',
  'title': 'Рай, Ад и Судный день',
  'description': 'Описание вечной обители, воздаяние и величие Дня Воскресения',
  'icon_name': 'brightness_high_rounded',
  'sort_order': 13,
  'keywords': 'рай ад судный день вечность воскресение смерть ахират воздаяние вечная жизнь '
              'спасение сады рая',
  'ayahs': [(3,
             133,
             'Стремитесь к прощению вашего Господа и Раю, ширина которого равна небесам и земле, '
             'уготованному для богобоязненных.'),
            (56,
             10,
             'А опередившие будут опередившими в Раю. Это будут приближенные в Садах блаженства.'),
            (18,
             107,
             'Поистине, обителью тех, которые уверовали и совершали праведные деяния, будут сады '
             'Фирдавса.'),
            (3,
             185,
             'Каждая душа вкусит смерть, но сполна вы получите ваши награды только в День '
             'воскресения.'),
            (99, 7, 'Тот, кто сделал добро весом в мельчайшую частицу, увидит его.')]},
 {'id': 'knowledge_wisdom',
  'category': 'Знания и мудрость',
  'title': 'Знания, разум и размышление',
  'description': 'Ценность стремления к знаниям, мудрость и размышление над творением',
  'icon_name': 'psychology_rounded',
  'sort_order': 14,
  'keywords': 'знания мудрость учеба разум размышление знамения наука истина поиск знаний чтение '
              'икра',
  'ayahs': [(96, 1, 'Читай во имя твоего Господа, Который сотворил все сущее...'),
            (20, 114, 'Говори: «Господи! Приумножь мои знания».'),
            (39, 9, 'Скажи: «Неужели равны те, которые знают, и те, которые не знают?»'),
            (3,
             190,
             'Поистине, в сотворении небес и земли, и в смене ночи и дня — знамения для обладающих '
             'разумом.')]},
 {'id': 'fear_taqwa',
  'category': 'Поклонение и очищение',
  'title': 'Искренность и богобоязненность (Таква)',
  'description': 'Чистота намерений (Ихлас), внутренний самоконтроль и страх перед грехом',
  'icon_name': 'shield_rounded',
  'sort_order': 15,
  'keywords': 'богобоязненность таква искренность ихлас чистота сердца намерение ния защиты от '
              'греха самоконтроль совесть',
  'ayahs': [(49, 13, 'Самый почитаемый перед Аллахом среди вас — наиболее богобоязненный.'),
            (65, 4, 'Тому, кто боится Аллаха, Он облегчает дело.'),
            (2, 197, 'Запасайтесь припасами, но лучший припас — это богобоязненность.'),
            (98, 5, 'А ведь им было велено лишь поклоняться Аллаху, служа Ему искренне...')]}]

def normalize_arabic_single(value: str, dagger_to_alif: bool) -> str:
    if dagger_to_alif:
        value = value.replace("\u0670", "ا")
    else:
        value = value.replace("\u0670", "")
    value = ARABIC_MARKS.sub("", value)
    value = value.translate(
        str.maketrans(
            {
                "أ": "ا",
                "إ": "ا",
                "آ": "ا",
                "ٱ": "ا",
                "ى": "ي",
                "ؤ": "و",
                "ئ": "ي",
                "ـ": "",
            }
        )
    )
    return " ".join(value.split())


def normalize_arabic(value: str) -> str:
    v1 = normalize_arabic_single(value, dagger_to_alif=True)
    v2 = normalize_arabic_single(value, dagger_to_alif=False)
    tokens = v1.split()
    for t in v2.split():
        if t not in tokens:
            tokens.append(t)
    return " ".join(tokens)


def normalize_russian(text: str) -> str:
    return text.lower().replace("ё", "е")


def normalize_translation_key(value: str) -> str:
    return "abu_adel" if value in {"abuadel", "abu_adel"} else value


def translation_rows(source: sqlite3.Connection):
    for row in source.execute(
        """
        SELECT id, ayah_id, translator_key, text
        FROM translations
        WHERE translator_key IN ('kuliev', 'abuadel', 'abu_adel')
        ORDER BY id
        """
    ):
        yield (
            row["id"],
            row["ayah_id"],
            normalize_translation_key(row["translator_key"]),
            row["text"],
        )


def copy_quran_tables(source: sqlite3.Connection, target: sqlite3.Connection) -> None:
    source.row_factory = sqlite3.Row
    target.executescript(
        """
        PRAGMA foreign_keys = ON;
        CREATE TABLE surahs (
          id INTEGER PRIMARY KEY,
          name_arabic TEXT NOT NULL,
          name_translit TEXT NOT NULL,
          name_russian TEXT NOT NULL,
          revelation_place TEXT NOT NULL,
          ayah_count INTEGER NOT NULL,
          revelation_order INTEGER NOT NULL,
          bismillah_pre INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE ayahs (
          id INTEGER PRIMARY KEY,
          surah_id INTEGER NOT NULL REFERENCES surahs(id),
          number_in_surah INTEGER NOT NULL,
          text_uthmani TEXT NOT NULL,
          text_normalized TEXT NOT NULL,
          juz INTEGER NOT NULL,
          hizb INTEGER NOT NULL,
          page INTEGER NOT NULL,
          sajda INTEGER NOT NULL DEFAULT 0,
          UNIQUE (surah_id, number_in_surah)
        );
        CREATE TABLE translations (
          id INTEGER PRIMARY KEY,
          ayah_id INTEGER NOT NULL REFERENCES ayahs(id),
          translator_key TEXT NOT NULL CHECK (translator_key IN ('kuliev', 'abu_adel')),
          text TEXT NOT NULL,
          UNIQUE (ayah_id, translator_key)
        );
        CREATE TABLE quran_wbw (
          sura INTEGER NOT NULL,
          ayah INTEGER NOT NULL,
          word_order INTEGER NOT NULL,
          text_arabic TEXT NOT NULL,
          text_russian TEXT NOT NULL,
          root_arabic TEXT,
          lemma TEXT,
          pos TEXT,
          PRIMARY KEY (sura, ayah, word_order)
        );
        CREATE TABLE tafsir_saadi (
          sura INTEGER NOT NULL,
          aya INTEGER NOT NULL,
          text TEXT NOT NULL,
          PRIMARY KEY (sura, aya)
        );
        CREATE TABLE thematic_topics (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          sort_order INTEGER NOT NULL
        );
        CREATE TABLE thematic_ayahs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          topic_id TEXT NOT NULL REFERENCES thematic_topics(id),
          surah_id INTEGER NOT NULL REFERENCES surahs(id),
          ayah_number INTEGER NOT NULL,
          note TEXT,
          sort_order INTEGER NOT NULL
        );
        CREATE TABLE content_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
        """
    )

    target.executemany(
        """
        INSERT INTO surahs (
          id, name_arabic, name_translit, name_russian, revelation_place,
          ayah_count, revelation_order, bismillah_pre
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            (
                row["id"],
                row["name_arabic"],
                row["name_translit"],
                row["name_russian"],
                row["revelation_place"],
                row["ayah_count"],
                row["revelation_order"],
                row["bismillah_pre"],
            )
            for row in source.execute("SELECT * FROM surahs ORDER BY id")
        ),
    )

    target.executemany(
        """
        INSERT INTO ayahs (
          id, surah_id, number_in_surah, text_uthmani, text_normalized,
          juz, hizb, page, sajda
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            (
                row["id"],
                row["surah_id"],
                row["number_in_surah"],
                row["text_uthmani"],
                normalize_arabic(row["text_uthmani"]),
                row["juz"],
                row["hizb"],
                row["page"],
                row["sajda"],
            )
            for row in source.execute("SELECT * FROM ayahs ORDER BY id")
        ),
    )

    target.executemany(
        """
        INSERT INTO translations (id, ayah_id, translator_key, text)
        VALUES (?, ?, ?, ?)
        """,
        translation_rows(source),
    )

    target.executemany(
        """
        INSERT INTO quran_wbw (
          sura, ayah, word_order, text_arabic, text_russian,
          root_arabic, lemma, pos
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            (
                row["sura"],
                row["ayah"],
                row["word_order"],
                WBW_FIXES.get(
                    (row["sura"], row["ayah"], row["word_order"]),
                    row["text_arabic"],
                ),
                row["text_russian"],
                row["root_arabic"],
                row["lemma"],
                row["pos"],
            )
            for row in source.execute("SELECT * FROM quran_wbw ORDER BY sura, ayah, word_order")
        ),
    )

    target.executemany(
        "INSERT INTO tafsir_saadi (sura, aya, text) VALUES (?, ?, ?)",
        (tuple(row) for row in source.execute("SELECT sura, aya, text FROM tafsir_saadi ORDER BY sura, aya")),
    )

    for topic in THEMATIC_TOPICS_DATA:
        target.execute(
            """
            INSERT INTO thematic_topics (id, category, title, description, icon_name, sort_order)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                topic["id"],
                topic["category"],
                topic["title"],
                topic["description"],
                topic["icon_name"],
                topic["sort_order"],
            ),
        )
        for order, ayah_info in enumerate(topic["ayahs"], 1):
            surah_id, ayah_num, note = ayah_info
            target.execute(
                """
                INSERT INTO thematic_ayahs (topic_id, surah_id, ayah_number, note, sort_order)
                VALUES (?, ?, ?, ?, ?)
                """,
                (topic["id"], surah_id, ayah_num, note, order),
            )


def build_search(target: sqlite3.Connection) -> None:
    target.executescript(
        """
        CREATE INDEX idx_ayahs_page ON ayahs(page);
        CREATE INDEX idx_ayahs_juz ON ayahs(juz);
        CREATE INDEX idx_ayahs_hizb ON ayahs(hizb);
        CREATE INDEX idx_translations_lookup ON translations(translator_key, ayah_id);
        CREATE INDEX idx_wbw_lookup ON quran_wbw(sura, ayah, word_order);
        CREATE INDEX idx_thematic_ayahs_lookup ON thematic_ayahs(topic_id, sort_order);
        CREATE VIRTUAL TABLE quran_search_fts USING fts4(
          kind,
          source_key,
          surah_id,
          ayah_number,
          text,
          normalized,
          tokenize=unicode61,
          notindexed=kind,
          notindexed=source_key,
          notindexed=surah_id,
          notindexed=ayah_number
        );
        """
    )

    target.execute(
        """
        INSERT INTO quran_search_fts(kind, source_key, surah_id, ayah_number, text, normalized)
        SELECT 'ayah', 'uthmani', surah_id, number_in_surah, text_uthmani, text_normalized
        FROM ayahs ORDER BY id
        """
    )
    target.execute(
        """
        INSERT INTO quran_search_fts(kind, source_key, surah_id, ayah_number, text, normalized)
        SELECT 'translation', translator_key, a.surah_id, a.number_in_surah, t.text, lower(replace(t.text, 'ё', 'е'))
        FROM translations AS t
        JOIN ayahs AS a ON a.id = t.ayah_id
        ORDER BY t.id
        """
    )

    surah_fts_rows = []
    for row in target.execute(
        "SELECT id, name_russian, name_translit, name_arabic FROM surahs ORDER BY id"
    ).fetchall():
        surah_id = row[0]
        name_rus = row[1]
        name_trans = row[2]
        name_arab = row[3]
        translit_rus = SURAH_RUSSIAN_TRANSLITS.get(surah_id, "")
        display_text = f"{name_rus} {name_trans} {name_arab}"
        norm_text = f"{normalize_russian(name_rus)} {normalize_russian(translit_rus)} {name_trans.lower()} {normalize_arabic(name_arab)}"
        surah_fts_rows.append((surah_id, display_text, norm_text))

    target.executemany(
        """
        INSERT INTO quran_search_fts(
          kind, source_key, surah_id, ayah_number, text, normalized
        ) VALUES ('surah', 'name', ?, 1, ?, ?)
        """,
        surah_fts_rows,
    )

    # Thematic and semantic index
    thematic_fts_rows = []
    for topic in THEMATIC_TOPICS_DATA:
        topic_id = topic["id"]
        title = topic["title"]
        desc = topic["description"]
        cat = topic["category"]
        keywords = topic["keywords"]
        first_ayah = topic["ayahs"][0]
        display_text = f"{title} • {desc}"
        norm_text = f"{normalize_russian(title)} {normalize_russian(desc)} {normalize_russian(cat)} {normalize_russian(keywords)}"
        thematic_fts_rows.append((topic_id, first_ayah[0], first_ayah[1], display_text, norm_text))

        for ayah_info in topic["ayahs"]:
            s_id, a_num, note = ayah_info
            note_display = f"{title}: {note}"
            note_norm = f"{normalize_russian(title)} {normalize_russian(keywords)} {normalize_russian(note)}"
            thematic_fts_rows.append((topic_id, s_id, a_num, note_display, note_norm))

    target.executemany(
        """
        INSERT INTO quran_search_fts (kind, source_key, surah_id, ayah_number, text, normalized)
        VALUES ('thematic', ?, ?, ?, ?, ?)
        """,
        thematic_fts_rows,
    )

    # Search alias for Ayat al-Kursi (2:255)
    target.execute(
        """
        INSERT INTO quran_search_fts(kind, source_key, surah_id, ayah_number, text, normalized)
        VALUES ('ayah', 'alias', 2, 255, 'Аят аль-Курси (Аятуль Курси)', 'аят аль-курси аятуль курси престол курси')
        """
    )


def validate(target: sqlite3.Connection) -> None:
    expected_counts = {
        "surahs": 114,
        "ayahs": 6236,
        "translations": 12472,
        "quran_wbw": 77432,
        "tafsir_saadi": 6236,
        "thematic_topics": 15,
        "thematic_ayahs": 71,
        "quran_search_fts": 18909,
    }
    for table, expected in expected_counts.items():
        actual = target.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        if actual != expected:
            raise RuntimeError(f"{table}: expected {expected} rows, found {actual}")

    for translator in ("kuliev", "abu_adel"):
        actual = target.execute(
            "SELECT COUNT(*) FROM translations WHERE translator_key = ?", (translator,)
        ).fetchone()[0]
        if actual != 6236:
            raise RuntimeError(f"{translator}: expected 6236 translations, found {actual}")

    metadata = dict(target.execute("SELECT key, value FROM content_metadata"))
    expected_metadata = {
        "schema_version": str(SCHEMA_VERSION),
        "content_version": CONTENT_VERSION,
        "content_scope": "quran_only",
        "ayah_count": "6236",
    }
    if metadata != expected_metadata:
        raise RuntimeError(
            f"content_metadata: expected {expected_metadata}, found {metadata}"
        )
    user_version = target.execute("PRAGMA user_version").fetchone()[0]
    if user_version != SCHEMA_VERSION:
        raise RuntimeError(
            f"user_version: expected {SCHEMA_VERSION}, found {user_version}"
        )

    empty_arabic = target.execute(
        "SELECT COUNT(*) FROM quran_wbw WHERE trim(text_arabic) = ''"
    ).fetchone()[0]
    if empty_arabic:
        raise RuntimeError(f"Word-by-word data contains {empty_arabic} empty Arabic tokens")

    if target.execute("PRAGMA foreign_key_check").fetchall():
        raise RuntimeError("Foreign-key validation failed")
    if target.execute("PRAGMA quick_check").fetchone()[0] != "ok":
        raise RuntimeError("SQLite quick_check failed")
    target.execute("INSERT INTO quran_search_fts(quran_search_fts) VALUES('integrity-check')")


def build(source_gzip: Path, output_gzip: Path) -> None:
    output_gzip.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="quran-pure-") as temp_dir:
        temp = Path(temp_dir)
        source_db = temp / "source.db"
        target_db = temp / "quran_pure.db"
        with gzip.open(source_gzip, "rb") as source, source_db.open("wb") as target:
            shutil.copyfileobj(source, target)

        source = sqlite3.connect(source_db)
        target = sqlite3.connect(target_db)
        try:
            with target:
                copy_quran_tables(source, target)
                build_search(target)
                target.executemany(
                    "INSERT INTO content_metadata(key, value) VALUES (?, ?)",
                    (
                        ("schema_version", str(SCHEMA_VERSION)),
                        ("content_version", CONTENT_VERSION),
                        ("content_scope", "quran_only"),
                        ("ayah_count", "6236"),
                    ),
                )
                target.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
                validate(target)
            target.execute("VACUUM")
            target.execute("PRAGMA optimize")
        finally:
            source.close()
            target.close()

        temporary_output = output_gzip.with_suffix(output_gzip.suffix + ".tmp")
        with target_db.open("rb") as source_file, temporary_output.open("wb") as raw_output:
            with gzip.GzipFile(
                filename="quran_pure.db",
                mode="wb",
                compresslevel=9,
                fileobj=raw_output,
                mtime=0,
            ) as output_file:
                shutil.copyfileobj(source_file, output_file)
        temporary_output.replace(output_gzip)

    digest = hashlib.sha256(output_gzip.read_bytes()).hexdigest()
    print(f"Built {output_gzip} ({output_gzip.stat().st_size} bytes)")
    print(f"SHA-256 {digest}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    arguments = parser.parse_args()
    build(arguments.source, arguments.output)


if __name__ == "__main__":
    main()
