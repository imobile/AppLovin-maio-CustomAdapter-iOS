#!/bin/bash

# 変数の設定
FRAMEWORK_NAME="AppLovinMaioMediationAdapter"
WORKSPACE="AppLovinMaioMediationAdapter.xcworkspace"
SCHEME="AppLovinMaioMediationAdapter"
OUTPUT_DIR="./build"

# ビルドディレクトリを作成
mkdir -p $OUTPUT_DIR

# iOS Deviceビルド
xcodebuild archive \
  -workspace $WORKSPACE \
  -scheme $SCHEME \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$OUTPUT_DIR/ios.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# iOS Simulatorビルド
xcodebuild archive \
  -workspace $WORKSPACE \
  -scheme $SCHEME \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$OUTPUT_DIR/iossimulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# XCFrameworkの作成
xcodebuild -create-xcframework \
  -framework "$OUTPUT_DIR/ios.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "$OUTPUT_DIR/iossimulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -output "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "XCFramework successfully created at $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
