# MediSwitch - Unified TODO List

This is a unified TODO list for the MediSwitch project, combining tasks from previous TODO files. The goal is to create a comprehensive and well-organized list to guide the remaining development efforts.

## I. Project Setup and Infrastructure

*   [x] **Gradle Upgrade:** Upgraded Gradle from version 7.6.3 to 8.9.
*   [x] **Flutter Dependencies Update:** Updated Flutter dependencies to the latest compatible versions.
*   [x] **Gradle Plugin Version Update:** Updated com.android.application Gradle plugin version to 8.1.0 in android/settings.gradle.kts
*   [x] **Gradle Version Update:** Updated Gradle version to 8.9 in android/gradle/wrapper/gradle-wrapper.properties
*   [x] **File Picker Version Update:** Updated file_picker version to 9.2.1 in pubspec.yaml
*   [x] **Updated compileSdk:** Updated compileSdk to 30 in android/app/build.gradle.kts
*   [x] **Updated sourceCompatibility and targetCompatibility:** Updated sourceCompatibility and targetCompatibility to JavaVersion.VERSION_17 in android/app/build.gradle.kts
*   [x] **Updated jvmTarget:** Updated jvmTarget to JavaVersion.VERSION_17.toString() in android/app/build.gradle.kts
*   [x] **Updated sourceCompatibility and targetCompatibility in android/app/build.gradle**
*   [x] **Added ext.kotlin_version and ext.flutterRoot in android/app/build.gradle**
*   [x] **Updated ndk.dir in android/gradle.properties**
*   [x] **Generated debug keystore**
*   [x] **Created DrugInteraction model in lib/models/drug_interaction.dart**
*   [x] **Created WeightDoseCalculator model in lib/models/weight_dose_calculator.dart**
*   [x] **Updated JDK version in Dockerfile to 17.0.10**
*   [x] Added sqflite_sqlcipher dependency to pubspec.yaml
*   [x] Implemented SQLCipher initialization in lib/services/database_update.dart
*   [ ] Create additional tables for categories, active ingredients, and manufacturers
*   [ ] **Build Time Optimization:** Improve build times and reduce the final application size.
*   [x] **Enable Mobile Connection via Wi-Fi Debugging:** Add instructions to enable mobile connection via Wi-Fi debugging for `flutter run`. Use `adb` or any other suitable tool that is efficient and lightweight.

## II. Core Functionality

### A. Database Encryption (SQLCipher)

*   [x] **SQLCipher Library Integration:** Added the SQLCipher library to the project.
*   [x] **Secure Key Generation and Storage (Partial):** Implemented a mechanism for generating and storing the encryption key securely.
*   [ ] **SQLCipher Initialization Fix (database\_service.dart):** Address the SQLCipher initialization issue in `database_service.dart` (nested parentheses error).
    *   [ ] Correct the method for opening the encrypted database using the secure key.
    *   [ ] Ensure proper invocation of `initializeSqlCipherLibs()`.
    *   [ ] Implement robust error handling for database opening failures.
*   [ ] **Enhanced Key Storage with `flutter_secure_storage`:**
    *   [ ] Implement an additional layer of encryption for the key itself.
    *   [ ] Bind the key to the device's unique identifier to prevent database transfer between devices.
    *   [ ] Implement a key recovery mechanism in case of loss.
*   [ ] **Performance Testing:** Conduct performance tests to measure the impact of encryption on query speeds.
*   [ ] **Database Integrity Check:** Implement a mechanism to verify the integrity of the database upon opening.
*   [ ] **Password/Key Change Option (Optional):** Add an option in the settings for advanced users to change the password/key.

### B. Data Import from Excel/CSV

*   [x] **Basic CSV Import:** Implemented a basic data import system from CSV files.
*   [ ] **`excel_import_service.dart` Enhancement:**
    *   [ ] Fix errors in processing cell values of type `CellValue`.
    *   [ ] Add support for various Excel formats (.xlsx, .xls).
    *   [ ] Implement automatic column recognition, even if the order differs in the file.
    *   [ ] Add support for Arabic encoding (UTF-8) to ensure correct import of Arabic text.
    *   [ ] Implement a mechanism for handling empty cells or invalid values.
*   [ ] **User Interface for Data Import:**
    *   [ ] Add a screen to select Excel/CSV files from the device.
    *   [ ] Display a preview of the data before importing.
    *   [ ] Show the progress of the import process.
    *   [ ] Display a report of the import results (number of records added/updated/rejected).
*   [ ] **Remote Data Update Mechanism:**
    *   [ ] Create a simple cloud service to host update files.
    *   [ ] Implement a mechanism to check for new updates.
    *   [ ] Download and apply updates automatically or upon user request.
    *   [ ] Add scheduling for checking updates (daily/weekly/monthly).
*   [ ] **Security Enhancements for Updates:**
    *   [ ] Verify the file signature to ensure its source.
    *   [ ] Encrypt update files during transfer.
    *   [ ] Create a backup before applying the update.

### C. Backup and Restore System

*   [x] **Basic Backup Mechanism:** Implemented a basic backup creation mechanism.
*   [ ] **`backup_service.dart` Enhancement:**
    *   [ ] Fix errors in `backup_restore_screen.dart` related to the backup service.
    *   [ ] Encrypt backups using the user's password.
    *   [ ] Compress backups to reduce their size.
    *   [ ] Add metadata to the backup (version, creation date, number of records).
    *   [ ] Implement a mechanism to verify the integrity of the backup before restoring.
*   [ ] **User Interface for Backup and Restore:**
    *   [ ] Add a screen to manage backups.
    *   [ ] Display a list of available backups with their details.
    *   [ ] Allow sharing backups via email or cloud storage.
    *   [ ] Allow scheduling automatic backups (daily/weekly).
*   [ ] **Cloud Storage Support for Backups:**
    *   [ ] Add support for Google Drive and Dropbox services.
    *   [ ] Synchronize backups automatically with cloud services.
    *   [ ] Restore data from cloud backups.

## III. Frontend Development

### A. Core UI Development

*   [x] **Basic App Structure:** Created the basic structure of the application.
*   [x] **Screen Navigation:** Implemented a system for navigating between screens.
*   [x] **Language Support (Arabic & English):** Implemented support for both Arabic and English languages.
*   [x] **Dark Mode:** Implemented dark mode.
*   [ ] **App Logo Design:** Design and implement the application logo (blue pill with a golden switch icon).
*   [x] **Implemented Material 3 Theme:** Updated the application to use Material 3 theme in lib/main.dart
*   [ ] **UX/UI Enhancement:** Improve the user experience (UX) and user interface (UI) design with calm colors (medical blue + gray).
*   [ ] **Arabic Font Implementation:** Implement clear Arabic fonts (Noto Sans Arabic) with RTL support.
*   [x] Implemented Settings Screen with Theme and Language Selection
*   [x] **Implemented Smooth Transitions:** Added animations using flutter_animate in lib/screens/example_screen.dart
*   [ ] **Smooth Transitions:** Add smooth transitions (animations) between screens.
*   [x] **Bottom Navigation Tabs:** Implemented basic bottom navigation tabs (Home, Components).
*   [ ] **Responsive Design:** Implement a responsive design for all screen sizes (from iPhone SE to Samsung S24 Ultra).

### B. Smart Drug Search Screen

*   [x] **Basic Search Interface:** Implemented the basic search interface.
*   [x] **Autosuggest System (Partial):** Developed an autosuggest system while typing in both languages (partially implemented).
*   [ ] **Illustrative Drug Images:** Add display of illustrative images of drugs in the search results.
*   [x] **Result Filtering (Partial):** Implemented filters for filtering results (by price, side effects, drug interactions) (partially implemented).
*   [ ] **"Egyptian/International" or "Prescription/Non-Prescription" Filtering:** Add an option to filter results by "Egyptian/International" or "Prescription/Non-Prescription".
*   [ ] **Enhanced Search Result Display:** Improve the display of search results with additional information (availability, price, manufacturer).
*   [ ] **Automatic Spelling Correction:** Implement an automatic spelling correction system in the search.
*   [ ] **Therapeutic Category Filtering:** Add filtering of results by therapeutic category (automatically classified from CSV).
*   [ ] **Lazy Loading:** Implement lazy loading to display drugs upon scrolling.
*   [ ] **Cached Network Images:** Store drug images temporarily using CachedNetworkImage.

### C. Equivalent Dosage Comparison Screen

*   [x] **Dosage Comparison Interface:** Designed and implemented the dosage comparison interface.
*   [x] **Dosage Conversion System:** Created a system for converting dosages between similar drugs.
*   [x] **Unit Support:** Implemented support for different units (mg/mcg) and automatic conversion between them.
*   [x] **Effectiveness and Toxicity Charts:** Developed charts illustrating the percentages of effectiveness and toxicity.
*   [x] **Shareable Comparison Results:** Added the ability to share comparison results.
*   [ ] **Redesign and Reimplementation of Equivalent Dosage Comparison Screen:** (due to current errors):
    *   [ ] Fix the issue of displaying the comparison chart.
    *   [ ] Fix the issue of displaying the comparison table.
    *   [ ] Improve the comparison interface to be more attractive and easy to use.
*   [ ] Add a feature to suggest alternatives with an accurate similarity percentage.

### D. Drug Dosage Calculator Screen (by Weight)

*   [x] **Dosage Calculator Interface:** Designed and implemented the dosage calculator interface.
*   [x] **Patient Weight Input:** Created a form to enter the patient's weight (in kg or lbs) with age specification.
*   [x] **Custom Dosage Calculation:** Implemented a system for calculating custom dosages based on weight and age.
*   [ ] **Redesign and Reimplementation of Drug Dosage Calculator Screen:** (due to current errors):
    *   [ ] Fix the issue of the undefined `getMedicationById` method.
    *   [ ] Improve the user interface and user experience.
*   [ ] Add immediate alerts (audio + red text) when exceeding safe dosage limits.
*   [ ] Develop a feature to save calculations and share them with the patient or medical team.

### E. General UI Improvements

*   [ ] Improve the experience of navigating between screens.
*   [ ] Add animations to improve the user experience.
*   [ ] Implement an in-app notification system.
*   [x] Improve RTL text direction support for the Arabic language.
*   [ ] **Arabic Font Implementation:** Implement clear Arabic fonts (Noto Sans Arabic) with RTL support.
*   [ ] Add an interactive guide (short videos) to explain how to use the application.
*   [ ] Implement an in-app notification system.
*   [ ] Improve application performance on low-spec devices.
*   [ ] Prevent screenshots of dosage pages (especially Android).

### F. Advertising and Subscription System

*   [ ] Implement the advertising system in the free version:
    *   [ ] Non-intrusive banner ads at the bottom of the screen.
    *   [ ] Interstitial ads every 10 uses.
*   [ ] Develop a paid subscription system (Premium):
    *   [ ] Remove ads for subscribers.
    *   [ ] Search history saving feature for subscribers.
    *   [ ] Price change alerts for subscribers.
*   [ ] Implement the electronic payment system (price $1.99/month).
*   [ ] Link the application to a Google AdMob account to manage ads.

## IV. Backend Development

### A. Database Development

*   [x] **Basic Database Structure:** Created the basic database structure.
*   [x] **Data Import from CSV:** Implemented a system for importing data from CSV files.
*   [x] **Medication Model Expansion:** Expanded the medication model to include information (interactions, side effects, images) in lib/models/medication.dart, created DoseEquivalent model in lib/models/dose_equivalent.dart, and created DrugInteraction model in lib/models/drug_interaction.dart
*   [ ] Create additional tables for categories, active ingredients, and manufacturers.
*   [ ] **Reimplement Data Encryption using SQLCipher (AES-256).**
*   [ ] Improve query performance and add additional indexes.
*   [ ] Add a data synchronization system with a cloud service.
*   [ ] Organize drugs automatically into categories (analgesics, antibiotics, etc.).
*   [ ] Implement a system to display the update date and price next to each drug.

### B. Data Update System from Excel/CSV

*   [ ] **Redesign and Implement a Data Import System from Excel files:**
    *   [ ] Implement a mechanism to clear all old data and replace it with new data.
    *   [ ] Process errors automatically (such as missing columns).
    *   [ ] Convert data from Excel to SQLite.
*   [ ] Implement a data update system without the need to republish the application.
*   [ ] Add a system to verify the validity of the imported data.
*   [ ] Develop a mechanism to maintain a history of updates.

### C. Search and Comparison Services

*   [x] **Basic Search Service:** Implemented the basic search service.
*   [ ] **Reimplement the `getMedicationById` service.**
*   [ ] Develop a smart search algorithm (by trade name or active ingredient).
*   [ ] Create a smart search suggestion system.
*   [x] **Equivalent Dosage Comparison Service:** Implemented the equivalent dosage comparison service.
*   [x] **Dosage Calculation Algorithm:** Developed a dosage calculation algorithm based on weight and age.
*   [ ] Create a drug interaction analysis system.
*   [ ] Develop an automatic spelling correction system.
*   [ ] Improve search speed (load data in <2 seconds even on a 2G connection).

### D. Management System Development (Admin Dashboard - Web)

*   [ ] Design and implement a control panel for administrators (web):
    *   [ ] Interface for uploading Excel files and updating the database.
    *   [ ] Display application statistics (number of active users, popular searches).
    *   [ ] Manage ads and subscriptions.
*   [ ] Link the control panel to the application via Firebase (free plan).
*   [ ] Implement a user and permissions management system.
*   [ ] Add an analytics system to track application usage and improve the user experience.

### E. Security and Performance Improvements

*   [ ] **Reimplement the data encryption system stored locally using SQLCipher.**
*   [ ] Improve database performance for complex queries.
*   [ ] **Redesign and implement the backup and restore system.**
*   [ ] Add event logging to track errors and improve performance.
*   [ ] Implement a mechanism for automatic application updates.
*   [ ] Prevent screenshots of sensitive information.
*   [ ] Improve application performance to work without a permanent internet connection.

## V. New Ideas for Application Development

### A. Smart Alert System for Price Changes

*   [ ] Implement a mechanism to track drug price changes:
    *   [ ] Compare new prices with old prices when updating data.
    *   [ ] Store the date of the price change and the percentage of change.
    *   [ ] Display a graph of price changes over time.
*   [ ] Add an alert system for users:
    *   [ ] Alert the user when the price of a drug in the favorites list changes.
    *   [ ] Ability to set a maximum price to receive an alert when the price drops below it.
    *   [ ] Alerts for cheaper alternative drugs when the price of a certain drug increases.

### B. Improving Search Performance Using Advanced Indexing Techniques

*   [ ] Implement advanced text indexing:
    *   [ ] Use Full-Text Search techniques to improve search speed.
    *   [ ] Support searching with multiple keywords.
    *   [ ] Support searching with exact phrases and fuzzy searching.
*   [ ] Improve the smart search algorithm:
    *   [ ] Support automatic spelling correction.
    *   [ ] Support searching with synonyms and different medical terms.
    *   [ ] Sort results by importance and relevance.

### C. Adding Analytical Features for Doctors and Pharmacists

*   [ ] Implement an advanced drug interaction analysis system:
    *   [ ] Analyze interactions between more than two drugs at the same time.
    *   [ ] Classify interactions by severity and impact.
    *   [ ] Provide recommendations to avoid dangerous interactions.
*   [ ] Add a tool to analyze medical prescriptions:
    *   [ ] Ability to enter a list of patient medications.
    *   [ ] Analyze interactions and interferences between drugs.
    *   [ ] Suggest safer or more effective alternatives.

## VI. Action Plan for Fixing Bugs and Redesigning Tools

### Phase 1: Fixing Critical Bugs

1.  Fix SQLCipher initialization issue in `database_service.dart`.
2.  Fix errors in `dose_comparison_screen.dart`.
3.  Add the `getMedicationById` method to `DatabaseService`.
4.  Fix errors in `backup_restore_screen.dart`.

### Phase 2: Redesigning Core Tools

1.  Redesign and implement the data encryption system using SQLCipher.
2.  Redesign and implement the backup and restore system.
3.  Redesign and implement the data import system from Excel/CSV files.

### Phase 3: Improving User Interfaces

1.  Redesign and implement the equivalent dosage comparison screen.
2.  Redesign and implement the drug dosage calculator screen.
3.  Improve the search interface and display of results.

### Phase 4: Adding New Features

1.  Implement the price change alert system.
2.  Improve search performance using advanced indexing techniques.
3.  Add analytical features for doctors and pharmacists.

## VII. Important Notes

*   Each tool must be tested separately before being integrated into the application.
*   Unit tests must be created for each new function.
*   The application must be compatible with the target operating systems (Android 8.0+ and iOS 13+).
*   Data security and user privacy standards must be adhered to.
*   Periodic performance tests must be performed to ensure the application's responsiveness.

</file_content>

IMPORTANT: For any future changes to this file, use the final_file_content shown above as your reference. This content reflects the current state of the file, including any auto-formatting (e.g., if you used single quotes but the formatter converted them to double quotes). Always base your SEARCH/REPLACE operations on this final version to ensure accuracy.

<environment_details>
# VSCode Visible Files
TODO_UNIFIED.md

# VSCode Open Tabs
android/gradle.properties
android/settings.gradle.kts
android/gradle/wrapper/gradle-wrapper.properties
pubspec.yaml
android/app/build.gradle.kts
android/app/build.gradle
lib/main.dart
Dockerfile
TODO_UNIFIED.md

# Current Time
3/26/2025, 2:00:44 AM (UTC, UTC+0:00)

# Current Mode
ACT MODE
</environment_details>
