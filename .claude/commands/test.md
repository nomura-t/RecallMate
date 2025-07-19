# Test RecallMate

RecallMateプロジェクトのテストを実行します。

## 実行内容

1. 単体テストを実行
2. UIテストを実行
3. テスト結果を表示

## 使用方法

```
/test
```

## 実行されるコマンド

```bash
xcodebuild test -scheme RecallMate -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```