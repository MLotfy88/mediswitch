# استخدام صورة DevContainer كقاعدة
FROM mcr.microsoft.com/devcontainers/universal:2

# تشغيل الأوامر كـ root لتجنب مشاكل الصلاحيات
USER root

# تحديث النظام وتثبيت الحزم المطلوبة
RUN apt-get update && apt-get install -y \
    unzip curl git wget openjdk-23-jdk \
        && rm -rf /var/lib/apt/lists/*

        # إعداد Java (JDK 23.0.2)
        ENV JAVA_HOME="/usr/lib/jvm/java-23-openjdk-amd64"
        ENV PATH="$JAVA_HOME/bin:$PATH"

        # تنزيل Flutter بالإصدار المحدد
        RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter && \
            cd /usr/local/flutter && \
                git checkout 3.29.2 && \
                    chmod -R 777 /usr/local/flutter

                    # ضبط بيئة Flutter
                    ENV PATH="/usr/local/flutter/bin:$PATH"
                    ENV FLUTTER_HOME="/usr/local/flutter"

                    # تنزيل Android SDK بأرقام الإصدارات المطلوبة
                    RUN mkdir -p /usr/local/android-sdk/cmdline-tools && \
                        cd /usr/local/android-sdk && \
                            wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
                                unzip cmdline-tools.zip -d cmdline-tools && \
                                    mv cmdline-tools/cmdline-tools /usr/local/android-sdk/cmdline-tools/latest && \
                                        rm cmdline-tools.zip

                                        # ضبط بيئة Android SDK
                                        ENV ANDROID_HOME="/usr/local/android-sdk"
                                        ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

                                        # تثبيت مكونات Android SDK المطلوبة
                                        RUN yes | sdkmanager --licenses && \
                                            sdkmanager "platform-tools" \
                                                           "platforms;android-28" \
                                                                          "platforms;android-29" \
                                                                                         "platforms;android-33" \
                                                                                                        "platforms;android-34" \
                                                                                                                       "platforms;android-35" \
                                                                                                                                      "build-tools;30.0.3" \
                                                                                                                                                     "build-tools;34.0.0" \
                                                                                                                                                                    "build-tools;36.0.0" \
                                                                                                                                                                                   "ndk;27.0.12077973"
                                                                                                                                                                                   
                                                                                                                                                                                   # ضبط بيئة NDK
                                                                                                                                                                                   ENV NDK_HOME="$ANDROID_HOME/ndk/27.0.12077973"
                                                                                                                                                                                   ENV PATH="$NDK_HOME:$PATH"
                                                                                                                                                                                   
                                                                                                                                                                                   # تثبيت Gradle بالإصدار المطلوب
                                                                                                                                                                                   RUN wget https://services.gradle.org/distributions/gradle-7.6.3-bin.zip -O gradle.zip && \
                                                                                                                                                                                       unzip gradle.zip -d /usr/local/ && \
                                                                                                                                                                                           mv /usr/local/gradle-* /usr/local/gradle && \
                                                                                                                                                                                               rm gradle.zip
                                                                                                                                                                                               
                                                                                                                                                                                               # ضبط بيئة Gradle
                                                                                                                                                                                               ENV GRADLE_HOME="/usr/local/gradle"
                                                                                                                                                                                               ENV PATH="$GRADLE_HOME/bin:$PATH"
                                                                                                                                                                                               
                                                                                                                                                                                               # تحديث Flutter وتحميل الأدوات
                                                                                                                                                                                               RUN flutter precache && flutter config --no-analytics && flutter doctor
                                                                                                                                                                                               
                                                                                                                                                                                               # إعادة المستخدم إلى `codespace` لتجنب مشاكل الصلاحيات
                                                                                                                                                                                               USER codespace
