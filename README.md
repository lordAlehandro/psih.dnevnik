# Дневник КПТ · CBT Diary

**[Русский](#русский) · [English](#english)**

<p align="center">
  <img src="docs/screenshots/02-diary.jpg" width="200" alt="Дневник">
  <img src="docs/screenshots/03-new-entry.jpg" width="200" alt="Новая запись">
  <img src="docs/screenshots/06-stats-mood.jpg" width="200" alt="Статистика настроения">
</p>

---

## Русский

**Дневник КПТ** — мобильное приложение для Android, которое помогает отслеживать эмоции и настроение по методу когнитивно-поведенческой терапии (КПТ). Записывайте не только радостные моменты, но и прорабатывайте сложные, негативные эмоции, а встроенные психологические тесты помогут оценивать своё состояние в динамике.

### Возможности

- **Три дневника** — общий, позитивный и негативный; переключаются ползунком на главном экране.
- **Записи с эмоциями** — дата в календаре, одна или несколько эмоций, заметка и фото.
- **Настроение дня** — пятибалльная шкала от «очень плохо» до «отлично».
- **Психологические тесты** — опросники по темам: депрессия, тревога и паника, стресс и травма, биполярный спектр, СДВГ, сон и др. (BAI, LSAS, DAS, GDS-15, IES-R, ASRS, BSDS, PSQI…). История результатов сохраняется.
- **Статистика** — круговые диаграммы эмоций и график настроения за выбранный период.
- **PDF-отчёт** — выгрузка дневника, настроения и результатов тестов с выбором периода и разделов.
- **Ежедневные напоминания** — с настраиваемым временем и текстом.
- **PIN-код** — защита дневника от посторонних.
- **Оформление** — тёмная тема и 12 цветовых тем, приветственные картинки (пейзажи, коты).
- **5 языков** — русский, английский, немецкий, французский, португальский.

> ⚠️ Тесты предназначены для самонаблюдения и **не являются медицинским диагнозом**.

### Установка

1. Откройте раздел [**Releases**](../../releases) и скачайте файл `psih-dnevnik-v1.0.0.apk`.
2. Откройте его на телефоне. Если Android попросит — разрешите установку из неизвестных источников.

### Сборка из исходников

Нужен [Flutter](https://docs.flutter.dev/get-started/install) (канал stable, Dart ≥ 3.2.3) и Android SDK.

```bash
git clone https://github.com/lordAlehandro/psih.dnevnik.git
cd psih.dnevnik
flutter pub get
flutter run               # запуск на подключённом устройстве / эмуляторе
flutter build apk         # сборка APK → build/app/outputs/flutter-apk/
```

Для release-подписи создайте файл `android/key.properties` (он не хранится в репозитории):

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=путь/к/keystore.jks
```

### Скриншоты

| | | |
|:-:|:-:|:-:|
| <img src="docs/screenshots/01-welcome.jpg" width="220"><br>Приветствие | <img src="docs/screenshots/02-diary.jpg" width="220"><br>Дневник | <img src="docs/screenshots/03-new-entry.jpg" width="220"><br>Новая запись |
| <img src="docs/screenshots/04-tests.jpg" width="220"><br>Тесты | <img src="docs/screenshots/05-stats-emotions.jpg" width="220"><br>Статистика эмоций | <img src="docs/screenshots/06-stats-mood.jpg" width="220"><br>График настроения |
| <img src="docs/screenshots/07-settings.jpg" width="220"><br>Настройки | <img src="docs/screenshots/08-themes.jpg" width="220"><br>Цветовые темы | <img src="docs/screenshots/09-pin.jpg" width="220"><br>PIN-код |

### Технологии

Flutter / Dart · SQLite (`sqflite`) · `shared_preferences` · `flutter_secure_storage` · `fl_chart` · `table_calendar` · `pdf` + `printing` · `flutter_local_notifications` · `share_plus`

---

## English

**CBT Diary** is an Android app for tracking emotions and mood using the principles of Cognitive Behavioral Therapy (CBT). Record the good moments, work through difficult and negative emotions, and use built-in psychological questionnaires to see how your state changes over time.

### Features

- **Three diaries** — general, positive and negative; switch between them with the slider on the main screen.
- **Emotion entries** — pick a date in the calendar, one or more emotions, add a note and a photo.
- **Daily mood** — a five-point scale from "very bad" to "excellent".
- **Psychological tests** — questionnaires grouped by topic: depression, anxiety & panic, stress & trauma, bipolar spectrum, ADHD, sleep and more (BAI, LSAS, DAS, GDS-15, IES-R, ASRS, BSDS, PSQI…). Result history is saved.
- **Statistics** — emotion pie charts and a mood chart for a chosen period.
- **PDF report** — export the diary, mood and test results for a chosen period and sections.
- **Daily reminders** — with custom time and message.
- **PIN code** — keeps the diary private.
- **Appearance** — dark theme plus 12 color themes, welcome images (landscapes, cats).
- **5 languages** — Russian, English, German, French, Portuguese.

> ⚠️ The tests are meant for self-observation and **are not a medical diagnosis**.

### Installation

1. Go to [**Releases**](../../releases) and download `psih-dnevnik-v1.0.0.apk`.
2. Open it on your phone. If Android asks, allow installing apps from unknown sources.

### Building from source

Requires [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, Dart ≥ 3.2.3) and the Android SDK.

```bash
git clone https://github.com/lordAlehandro/psih.dnevnik.git
cd psih.dnevnik
flutter pub get
flutter run               # run on a connected device / emulator
flutter build apk         # build APK → build/app/outputs/flutter-apk/
```

For release signing, create `android/key.properties` (it is not stored in the repository):

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=path/to/keystore.jks
```

### Screenshots

The screenshots above (in Russian UI) show: welcome screen, diary, new entry, tests, emotion statistics, mood chart, settings, color themes and PIN setup.

### Tech stack

Flutter / Dart · SQLite (`sqflite`) · `shared_preferences` · `flutter_secure_storage` · `fl_chart` · `table_calendar` · `pdf` + `printing` · `flutter_local_notifications` · `share_plus`
