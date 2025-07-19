# Social Feature Development

RecallMateのソーシャル機能開発に関連するタスクを実行します。

## 実行内容

ソーシャル機能の開発において以下のタスクを支援します：

1. **新しいソーシャル機能のViewを作成**
2. **Supabaseスキーマの更新**
3. **NotificationManagerの拡張**
4. **FriendshipManagerの拡張**

## 使用方法

```
/social [feature_type] [feature_name]
```

### 例

```
/social view GroupChatView
/social manager StudyGroupManager
/social schema group_messages
```

## 対応機能

- `view`: 新しいソーシャル機能のView作成
- `manager`: 新しいマネージャークラス作成
- `schema`: Supabaseスキーマ更新
- `notification`: 通知機能の拡張