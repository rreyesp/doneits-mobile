#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Verificar que javac funciona
echo "Usando javac: $(which javac)"
javac -version

# Forzar Gradle a usar este Java
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"

# Limpiar y construir
flutter clean
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build
rm -rf .dart_tool

flutter pub get
flutter build apk --flavor unsigned
