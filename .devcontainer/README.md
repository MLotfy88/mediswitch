# بيئة تطوير Flutter & Android

هذه البيئة مخصصة لتطوير تطبيقات Flutter وAndroid باستخدام DevContainer. تم إعدادها بالإصدارات والأدوات التالية:

## الإصدارات المضمنة

- **Flutter**: 3.29.2
- **Dart SDK**: 3.7.2
- **JDK**: 23.0.2
- **Gradle**: 7.6.3
- **Android SDK**:
  - Min SDK: 28
  - Target SDK: 35
  - Build Tools: 30.0.3, 34.0.0, 36.0.0
  - Platforms: Android 28, 29, 33, 34, 35
  - NDK: 27.0.12077973

## متغيرات البيئة

تم إعداد متغيرات البيئة التالية:

- `JAVA_HOME`: مسار JDK
- `ANDROID_HOME`: مسار Android SDK
- `NDK_HOME`: مسار Android NDK
- `FLUTTER_HOME`: مسار Flutter SDK
- `DART_SDK`: مسار Dart SDK
- `GRADLE_HOME`: مسار Gradle

## إضافات VS Code

تم تضمين الإضافات التالية:

- Flutter & Dart
- Java Development Tools
- Gradle Support
- Docker
- Material Icon Theme
- Error Lens
- Code Spell Checker

## كيفية الاستخدام

1. تأكد من تثبيت Docker و VS Code مع إضافة Remote - Containers
2. افتح المشروع في VS Code
3. اضغط F1 واختر "Remote-Containers: Reopen in Container"
4. انتظر حتى يتم بناء الحاوية وتثبيت جميع الأدوات
5. ابدأ التطوير!

## المنافذ المفتوحة

- 8080: تطبيق الويب
- 8000: خادم API
- 3000: خادم التطوير

## ملاحظات

- يتم تنفيذ `flutter pub get` تلقائيًا عند إنشاء الحاوية
- تم تكوين VS Code لتنسيق الكود تلقائيًا عند الحفظ