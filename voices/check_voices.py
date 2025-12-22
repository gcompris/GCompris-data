#!/usr/bin/python
#
# GCompris - check_voices.py
#
# Copyright (C) 2015 Bruno Coudoin <bruno.coudoin@gcompris.net>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#
# The output is in markdown. A web page can be generated with:
# ./check_voices.py ../gcompris-kde
#
# (Requires python-markdown to be installed)
#
import os
import sys
import re
import copy
import json
import codecs
from io import StringIO
from datetime import date
import glob

import markdown
import polib
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlComponent, QQmlEngine

if len(sys.argv) < 2:
    print("Usage: check_voices.py path_to_gcompris [-v] [-nn]")
    print("  -v:  verbose, show also files that are fine")
    print("  -nn: not needed, show extra file in the voice directory")
    sys.exit(1)

verbose = '-v' in sys.argv
notneeded = '-nn' in sys.argv
gcompris_qt = sys.argv[1]

# Force output as UTF-8
ref_stdout = sys.stdout
sys.stdout = codecs.getwriter('utf-8')(sys.stdout)

# A global hash to hold a description on a key file like the UTF-8 char of
# the file.
descriptions = {}

def get_html_header():
    return """<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <meta charset="utf-8"/>
  <title>GCompris Voice Recording Status</title>
</head>
<body>
"""

def get_html_footer():
    today = date.today()
    return """
<hr>
<p>Page generated the {:s}</p>
</body>
""".format(today.isoformat())

def get_html_progress_bar(ratio):
    return '<td width=200 height=30pt>' + \
        '<div style="border: 2px solid silver;background-color:#c00"><div style="background-color:#0c0;height:15px;width:{:d}%"></div></div>'.format(int(float(ratio) * 100))

# '<hr style="color:#0c0;background-color:#0c0;height:15px; border:none;margin:0;" align="left" width={:d}% /></td>'.format(int(float(ratio) * 100))

def title1(title):
    print(title)
    print('=' * len(title))
    print('')

def title2(title):
    print(title)
    print('-' * len(title))
    print('')

def title3(title):
    print('### ' + title)
    print('')

def get_intro_from_code():
    '''Return a set for activities as found in GCompris ActivityInfo.qml'''

    activity_info = set()

    activity_dir = gcompris_qt + "/src/activities"
    for activity in os.listdir(activity_dir):
        # Skip unrelevant activities
        if activity == 'template' or \
           activity == 'menu' or \
           not os.path.isdir(activity_dir + "/" + activity):
            continue
        activity_info.add(activity + '.ogg')
    return activity_info

def init_intro_description_from_code(locale, gcompris_po):
    '''Init the intro description as found in GCompris ActivityInfo.qml'''
    '''in the global descriptions hash'''

    voices_po = None
    try:
        voices_po = polib.pofile(gcompris_qt + '/po/'+locale+'/gcompris_voices.po', encoding='utf-8')
    except OSError:
        print("**ERROR: Failed to load po file %s**" % ('/po/'+locale+'/gcompris_voices.po'))
        print('')

    activity_dir = gcompris_qt + "/src/activities"
    for activity in os.listdir(activity_dir):
        # Skip unrelevant activities
        if activity == 'template' or \
           activity == 'menu' or \
           not os.path.isdir(activity_dir + "/" + activity):
            continue

        descriptions[activity + '.ogg'] = ''
        try:
            with open(activity_dir + "/" + activity + "/ActivityInfo.qml") as f:
                content = f.readlines()

                for line in content:
                    m = re.match('.*title:.*\"(.*)\"', line)
                    if m:
                        title = m.group(1)
                        if gcompris_po:
                            title_po = gcompris_po.find(title)
                            title = title_po.msgstr if title_po else title
                        descriptions[activity + '.ogg'] += ' title: ' + title

                    m = re.match('.*description:.*\"(.*)\"', line)
                    if m:
                        description = m.group(1)
                        if gcompris_po:
                            description_po = gcompris_po.find(description)
                            description = description_po.msgstr if description_po else description
                        descriptions[activity + '.ogg'] += ' description: ' + title

                    m = re.match('.*intro:.*\"(.*)\"', line)
                    if m:
                        voiceText = m.group(1)
                        if voices_po:
                            voice_text_po = voices_po.find(voiceText)
                            voiceText = voice_text_po.msgstr if voice_text_po and voice_text_po.msgstr != "" else voiceText
                        descriptions[activity + '.ogg'] += ' voice: ' + voiceText

            if not activity + '.ogg' in descriptions:
                print("**ERROR: Missing intro tag in %s**" % (activity + "/ActivityInfo.qml"))
        except IOError:
            pass

    print('')


def init_country_names_from_code(component, locale, gcompris_po):
    '''Init the country description as found in GCompris geography/resource/board/board*.qml'''
    '''in the global descriptions hash'''

    for qml in glob.glob(gcompris_qt + '/src/activities/geography/resource/board/*.qml'):
        component.loadUrl(QUrl(qml))
        board = component.create()
        levels = board.property('levels')
        for level in levels.toVariant():
            if 'soundFile' in level and 'toolTipText' in level:
                sound = level['soundFile'].split('/')[-1].replace('$CA', 'ogg')
                tooltip = level['toolTipText']
                if gcompris_po:
                    tooltip_po = gcompris_po.find(tooltip)
                    tooltip = tooltip_po.msgstr if tooltip_po else tooltip
                descriptions[sound] = tooltip


def get_locales_from_config(source: str):
    '''Return a set for locales as found in GCompris src/core/LanguageList.qml'''

    locales = set()

    try:
        with open(source, encoding='utf-8') as f:
            content = f.readlines()
            for line in content:
                # Ignore commented lines
                if line.find("//{") != -1:
                    continue
                m = re.match('.*\"locale\":.*\"(.*)\"', line)
                if m:
                    locale = m.group(1).split('.')[0]
                    if locale not in ('system', 'en_US'):
                        locales.add(locale)
    except IOError as e:
        print(f"ERROR: Failed to parse {source}: {e.strerror}")

    return locales


def get_locales_from_po_files():
    '''Return a set for locales for which we have a po file '''

    locales = set()

    locales_dir = gcompris_qt + "/poqm"
    for locale in os.listdir(locales_dir):
        locales.add(locale)

    return locales

def get_translation_status_from_po_files(gcompris_po_file: str):
    '''Return the translation status from the po file '''
    '''For each locale as key we provide a list: '''
    ''' [ translated_entries, untranslated_entries, fuzzy_entries, percent ]'''

    # en locale has no translation file but mark it 100% done
    locales = {'en': [0, 0, 0, 1]}

    descriptions['en'] = 'US English'

    locales_dir = gcompris_qt + "/poqm"
    for locale in os.listdir(locales_dir):
        po_file = locales_dir + '/' + locale + '/' + gcompris_po_file
        if not os.path.exists(po_file):
            continue
        po = polib.pofile(po_file, encoding='utf-8')
        # Calc a global translation percent
        untranslated = len(po.untranslated_entries())
        translated = len(po.translated_entries())
        fuzzy = len(po.fuzzy_entries())
        percent = 1 - (float((untranslated + fuzzy)) / (translated + untranslated + fuzzy))
        locales[locale] = [translated, untranslated, fuzzy, percent]

        # Save the translation team in the global descriptions
        if 'Language-Team' in po.metadata:
            team = po.metadata['Language-Team']
            team = re.sub(r' <.*>', '', team)
            descriptions[locale] = team
        else:
            descriptions[locale] = ''

    return locales

def get_words_from_code():
    '''Return a set for words as found in GCompris lang/resource/content-<locale>.json'''
    try:
        with open(gcompris_qt + '/src/activities/lang/resource/content-' + locale + '.json', encoding='utf-8') as data_file:
            data = json.load(data_file)
    except IOError:
        print('')
        print("**ERROR: missing resource file %s**" % ('/src/activities/lang/resource/content-' + locale + '.json'))
        print('[Instructions to create this file](%s)' % ('https://gcompris.net/wiki/Voice_translation_Qt#Lang_word_list'))
        print('')
        return set()

    # Consolidate letters
    words = set()
    for word in data.keys():
        # Skip alphabet letter, they are already handled by the alphabet set
        if word[0] == 'U' or word[0] == '1':
            continue
        words.add(word)
        descriptions[word] = '[{:s}](https://gcompris.net/incoming/lang/words.html#{:s})'.format(data[word], word.replace('.ogg', ''))

    return words


def check_file_existence(filename, instructions):
    if not os.path.isfile(gcompris_qt + filename):
        print('')
        print("**ERROR: missing resource file %s**" % filename)
        print('[Instructions to create this file](%s)' % instructions)

    # We don't really have voices needs here, just check the file exists
    return set()


def get_grammar_analysis_from_code():
    '''Return nothing but tells if the required GCompris grammar_analysis/resource/grammar_analysis-<locale>.json is there'''
    return check_file_existence('/src/activities/grammar_analysis/resource/grammar_analysis-' + locale + '.json', 'https://gcompris.net/wiki/How_to_translate#Dataset_to_translate')


def get_grammar_classes_from_code():
    '''Return nothing but tells if the required GCompris grammar_classes/resource/grammar_classes-<locale>.json is there'''
    return check_file_existence('/src/activities/grammar_classes/resource/grammar_classes-' + locale + '.json', 'https://gcompris.net/wiki/How_to_translate#Dataset_to_translate')


def get_wordsgame_from_code():
    '''Return nothing but tells if the required GCompris wordsgame/resource/default-<locale>.json is there'''
    return check_file_existence('/src/activities/wordsgame/resource/default-' + locale + '.json', 'https://gcompris.net/wiki/Word_Lists_Qt#Wordsgame_.28Typing_words.29')


def get_click_on_letter_from_code():
    '''Return nothing but tells if the required GCompris click_on_letter/resource/levels-<locale>.json is there'''
    return check_file_existence('/src/activities/click_on_letter/resource/levels-' + locale + '.json', 'https://gcompris.net/wiki/How_to_translate#Dataset_to_translate')


def get_geography_on_letter_from_code(component):
    '''Return all the countries in geography/resource/board/board-x.json'''
    words = set()

    for qml in glob.glob(gcompris_qt + '/src/activities/geography/resource/board/*.qml'):
        component.loadUrl(QUrl(qml))
        board = component.create()
        levels = board.property('levels')
        for level in levels.toVariant():
            if 'soundFile' in level and ('type' not in level or level['type'] != "SHAPE_BACKGROUND"):
                sound = level['soundFile'].split('/')[-1].replace('$CA', 'ogg')
                words.add(sound)
    return words

def get_files(locale, voiceset):
    to_remove = set(['README'])
    try:
        return set(os.listdir(locale + '/' + voiceset)) - to_remove
    except:
        return set()

def get_locales_from_file():
    locales = set()
    for file in os.listdir('.'):
        if os.path.isdir(file) \
           and not os.path.islink(file) \
           and file[0] != '.':
            locales.add(file)

    return locales

def get_gletter_alphabet():
    try:
        with open(gcompris_qt + '/src/activities/gletters/resource/default-' + locale + '.json', encoding='utf-8') as data_file:
            data = json.load(data_file)
    except IOError:
        print('')
        print("**ERROR: Missing resource file %s**" % ('/src/activities/gletters/resource/default-' + locale + '.json'))
        print('[Instructions to create this file](%s)' % ('https://gcompris.net/wiki/Word_Lists_Qt#Simple_Letters_.28Typing_letters.29_level_design'))
        print('')
        return set()

    # Consolidate letters
    letters = set()
    for level in data['levels']:
        for w in level['words']:
            multiletters = ""
            for one_char in w.lower():
                multiletters += 'U{:04X}'.format(ord(one_char))
            letters.add(multiletters + '.ogg')
            descriptions[multiletters + '.ogg'] = w.lower()

    # Add numbers needed for words
    for i in range(10, 21):
        letters.add(str(i) + '.ogg')

    return letters

def diff_set(title, code, files):
    '''Returns a stat from 0 to 1 for this report set'''

    if not code and not files:
        return 0

    title2(title)

    if verbose and code & files:
        title3("These files are correct")
        print('| File | Description |')
        print('|------|-------------|')
        sorted_list = list(code & files)
        sorted_list.sort()
        for f in sorted_list:
            if f in descriptions:
                print('| %s | %s |' % (f, descriptions[f]))
            else:
                print('|%s |  |' % (f))
        print('')

    if code - files:
        title3("These files are missing")
        print('| File | Description |')
        print('|------|-------------|')
        sorted_list = list(code - files)
        sorted_list.sort()
        for f in sorted_list:
            if f in descriptions:
                print('| %s | %s |' % (f, descriptions[f]))
            else:
                print('|%s |  |' % (f))
        print('')

    if notneeded and files - code:
        title3("These files are not needed")
        print('| File | Description |')
        print('|------|-------------|')
        sorted_list = list(files - code)
        sorted_list.sort()
        for f in sorted_list:
            if f in descriptions:
                print('|%s | %s|' % (f, descriptions[f]))
            else:
                print('|%s |  |' % (f))
        print('')

    return 1 - float(len(code - files)) / len(code | files)

def diff_locale_set(title, code, files):

    if not code and not files:
        return

    title2(title)
    if verbose:
        title3("We have voices for these locales:")
        missing = []
        for locale in code:
            if os.path.isdir(locale):
                print('* ' + locale)
            else:
                # Shorten the locale and test again
                shorten = locale.split('_')
                if os.path.isdir(shorten[0]):
                    print('* ' + locale)
                else:
                    missing.append(locale)
    print('')
    print("We miss voices for these locales:")
    for f in missing:
        print('* ' + f)
    print('')

def check_locale_config(title, stats, locale_config):
    '''Display and return locales that are translated above a fixed threshold'''
    title2(title)
    LIMIT = 0.8
    sorted_config = list(locale_config)
    sorted_config.sort()
    good_locale = []
    for locale in sorted_config:
        if locale in stats:
            if stats[locale][3] < LIMIT:
                print('* {:s} ({:s})'.format((descriptions[locale] if locale in descriptions else ''), locale))
            else:
                good_locale.append(descriptions[locale] if locale in descriptions else '')
        else:
            # Shorten the locale and test again
            shorten = locale.split('_')[0]
            if shorten in stats:
                if stats[shorten][3] < LIMIT:
                    print('* {:s} ({:s})'.format((descriptions[shorten] if shorten in descriptions else ''), shorten))
                else:
                    good_locale.append(descriptions[shorten] if shorten in descriptions else '')
            else:
                print("* %s no translation at all" % (locale))

    print('')
    good_locale.sort()
    print('There are %d locales above %d%% translation: %s' % (len(good_locale), LIMIT * 100,
                                                               ', '.join(good_locale)))

    return good_locale

#
# main
# ===

reports = {}
sys.stdout = reports['stats'] = StringIO()

string_stats = get_translation_status_from_po_files('gcompris_qt.po')
check_locale_config("Locales to remove from LanguageList.qml (translation level < 80%)",
                    string_stats, get_locales_from_config(gcompris_qt + "/src/core/LanguageList.qml"))

print('\n')

check_locale_config("Locales to remove from ServerLanguageList.qml (translation level < 80%)",
                    get_translation_status_from_po_files('gcompris_teachers.po'), get_locales_from_config(gcompris_qt + "/src/server/components/ServerLanguageList.qml"))

print('\n[Guide to contribute recording files](%s)' % ('https://gcompris.net/wiki/Voice_translation_Qt'))

# Calc the big list of locales we have to check
all_locales = get_locales_from_po_files() | get_locales_from_file()
all_locales = list(all_locales)
all_locales.sort()

stats = {}
global_descriptions = copy.deepcopy(descriptions)

app = QCoreApplication(sys.argv)
engine = QQmlEngine()
component = QQmlComponent(engine)

for locale in all_locales:
    sys.stdout = reports[locale] = StringIO()

    descriptions = copy.deepcopy(global_descriptions)
    gcompris_po = None
    try:
        gcompris_po = polib.pofile(gcompris_qt + '/poqm/'+locale+'/gcompris_qt.po', encoding='utf-8')
    except OSError:
        if gcompris_po is None:
            print("**ERROR: Failed to load po file %s**" % ('/poqm/'+locale+'gcompris_qt.po'))
            print('')

    init_intro_description_from_code(locale, gcompris_po)
    init_country_names_from_code(component, locale, gcompris_po)

    title1('{:s} ({:s})'.format((descriptions[locale] if locale in descriptions else ''), locale))

    lstats = {'locale': locale}
    lstats['intro'] = diff_set("Intro ({:s}/intro/)".format(locale), get_intro_from_code(), get_files(locale, 'intro'))
    lstats['letter'] = diff_set("Letters ({:s}/alphabet/)".format(locale), get_gletter_alphabet(), get_files(locale, 'alphabet'))

    descriptions['click_on_letter.ogg'] = "Must contains the voice: 'Click on the letter:'"
    lstats['misc'] = diff_set("Misc ({:s}/misc/)".format(locale), get_files('en', 'misc'), get_files(locale, 'misc'))

    lstats['color'] = diff_set("Colors ({:s}/colors/)".format(locale), get_files('en', 'colors'), get_files(locale, 'colors'))
    lstats['geography'] = diff_set("Geography ({:s}/geography/)".format(locale), get_geography_on_letter_from_code(component), get_files(locale, 'geography'))
    lstats['words'] = diff_set("Words ({:s}/words/)".format(locale), get_words_from_code(), get_files(locale, 'words'))
    lstats['wordsgame'] = diff_set("Wordsgame", get_wordsgame_from_code(), set())
    lstats['grammar_analysis'] = diff_set("Grammar Analysis", get_grammar_analysis_from_code(), set())
    lstats['grammar_classes'] = diff_set("Grammar Classes", get_grammar_classes_from_code(), set())
    lstats['click_on_letter'] = diff_set("Click on letter", get_click_on_letter_from_code(), set())
    stats[locale] = lstats

sys.stdout = reports['summary'] = StringIO()
sorted_keys = sorted(stats)

title1("GCompris Voice Recording Status Summary")
print('| Locale | Strings | Misc | Letters | Colors | Geography | Words | Intro|')
print('|--------|---------|------|---------|--------|-----------|-------|------|')
for locale in sorted_keys:
    stat = stats[locale]
    print('| [{:s} ({:s})](voice_status_{:s}.html) | {:.2f} | {:.2f} | {:.2f} | {:.2f} | {:.2f} | {:.2f} | {:.2f} |'
          .format((descriptions[locale] if locale in descriptions else ''), stat['locale'], locale,
                  string_stats[locale][3] if locale in string_stats else 0,
                  stat['misc'], stat['letter'], stat['color'], stat['geography'],
                  stat['words'], stat['intro']))

#
# Now we have all the reports
#

extensions = ['markdown.extensions.tables']

sys.stdout = ref_stdout

with codecs.open("index.html", "w",
                 encoding="utf-8",
                 errors="xmlcharrefreplace"
                 ) as f:
    f.write(get_html_header())

    summary = markdown.markdown(reports['summary'].getvalue(), extensions=extensions)
    summary2 = ""
    for line in summary.split('\n'):
        m = re.match(r'<td>(\d\.\d\d)</td>', line)
        if m:
            rate = m.group(1)
            summary2 += get_html_progress_bar(rate)
        else:
            summary2 += line

        summary2 += '\n'

    f.write(summary2 + '\n')

    f.write(markdown.markdown(reports['stats'].getvalue(), extensions=extensions))
    f.write(get_html_footer())

for locale in sorted_keys:
    with codecs.open("voice_status_{:s}.html".format(locale), "w",
                     encoding="utf-8",
                     errors="xmlcharrefreplace"
                     ) as f:
        f.write(get_html_header())
        f.write(markdown.markdown(reports[locale].getvalue(), extensions=extensions))
        f.write(get_html_footer())
