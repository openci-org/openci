FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 基本パッケージとツールのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    zip \
    ca-certificates \
    openjdk-17-jdk-headless \
    wget \
    build-essential \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js (V20) のインストール
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Firebase CLI のグローバルインストール
RUN npm install -g firebase-tools@latest \
    && firebase --version \
    && npm cache clean --force

# 4. Flutter SDK (3.41.7) のインストール
RUN git clone --depth 1 --branch 3.41.7 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter doctor

# 5. Android SDK のインストール
ENV ANDROID_HOME=/usr/local/lib/android/sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && rm /tmp/cmdline-tools.zip \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Android SDK ライセンスへの同意
RUN yes | sdkmanager --licenses --sdk_root=${ANDROID_HOME}

# 最小限必要な Android プラットフォームとビルドツールの追加
RUN sdkmanager --sdk_root=${ANDROID_HOME} "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 6. act のインストール
RUN cd /tmp \
    && curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash \
    && mv bin/act /usr/local/bin/act \
    && rm -rf bin

# デフォルトの起動コマンド
CMD ["tail", "-f", "/dev/null"]
