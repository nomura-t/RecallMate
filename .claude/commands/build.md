# Build RecallMate

RecallMateプロジェクトをビルドします。

## 実行内容

1. Xcodeプロジェクトをクリーンビルド
2. iPhone 16 Pro シミュレーターを対象にビルド
3. エラーがある場合は詳細を表示

## 使用方法

```
/build
```

## 実行されるコマンド

```bash
xcodebuild clean build -scheme RecallMate -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```