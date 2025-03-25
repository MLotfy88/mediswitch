FROM gitpod/workspace-base

USER root

# تثبيت الحزم الأساسية
RUN apt-get update && apt-get install -y \
    unzip curl git wget \
    && rm -rf /var/lib/apt/lists/*

# تثبيت JDK 23
RUN mkdir -p /usr/local/jdk && \
    wget https://download.oracle.com/java/23/archive/jdk-23.0.1_linux-x64_bin.tar.gz -O jdk.tar.gz && \
    tar -xzf jdk.tar.gz -C /usr/local/jdk --strip-components=1 && \
    rm jdk.tar.gz

ENV JAVA_HOME="/usr/local/jdk"
ENV PATH="$JAVA_HOME/bin:$PATH"

# تثبيت Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter && \
    cd /usr/local/flutter && \
    git checkout 3.29.2 && \
    chmod -R 777 /usr/local/flutter

ENV PATH="/usr/local/flutter/bin:$PATH"
ENV FLUTTER_HOME="/usr/local/flutter"

# تثبيت Android SDK
RUN mkdir -p /usr/local/android-sdk/cmdline-tools && \
    cd /usr/local/android-sdk && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d cmdline-tools && \
    mv cmdline-tools/cmdline-tools /usr/local/android-sdk/cmdline-tools/latest && \
    rm cmdline-tools.zip

ENV ANDROID_HOME="/usr/local/android-sdk"
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# قبول التراخيص وتثبيت المكونات
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

# تثبيت Gradle
RUN wget https://services.gradle.org/distributions/gradle-7.6.3-all.zip -O gradle.zip && \
    unzip gradle.zip -d /usr/local/ && \
    mv /usr/local/gradle-* /usr/local/gradle && \
    rm gradle.zip

ENV GRADLE_HOME="/usr/local/gradle"
ENV PATH="$GRADLE_HOME/bin:$PATH"

# تثبيت Dart SDK
RUN wget https://storage.googleapis.com/dart-archive/channels/stable/release/3.7.2/sdk/dartsdk-linux-x64-release.zip -O dart.zip && \
    unzip dart.zip -d /usr/local/ && \
    rm dart.zip

ENV DART_SDK="/usr/local/dart-sdk"
ENV PATH="$DART_SDK/bin:$PATH"

# تهيئة نهائية
RUN mkdir -p /usr/local/flutter/bin/cache/artifacts/gradle_wrapper && \
    chmod -R 777 /usr/local/flutter/bin/cache

RUN flutter precache --verbose && \
    flutter config --no-analytics && \
    flutter doctor

USER gitpod
