# RecallMate クリーンアーキテクチャ移行計画

## 概要
現在のRecallMateアプリをクリーンアーキテクチャに段階的に移行するための詳細な計画です。

## 現在の課題

### 1. 循環参照
- AuthenticationStateManager → FriendshipManager → StudyGroupManager
- 複数のサービスが PersistenceController.shared に依存
- SupabaseManager.shared への密結合

### 2. 型の重複
- UserProfile, EnhancedProfile, Profile の重複
- 複数のエラーハンドリング実装
- 類似の日付フォーマット処理

### 3. シングルトンパターンの乱用
- `.shared` インスタンスが大量に存在
- テストが困難
- 依存関係が不明確

## 移行戦略

### フェーズ1: 基盤整備 (完了)
- [x] 統一モデルの作成 (UnifiedModels.swift)
- [x] サービスプロトコルの定義 (ServiceProtocols.swift)
- [x] 依存性注入コンテナの実装 (DIContainer.swift)
- [x] イベントシステムの構築
- [x] 統一エラーハンドリング

### フェーズ2: サービス層のリファクタリング (進行中)
- [x] FriendshipServiceの分離 (ModularFriendshipService.swift)
- [ ] AuthenticationServiceのプロトコル準拠
- [ ] LearningActivityServiceの実装
- [ ] NotificationServiceの実装

### フェーズ3: リポジトリパターンの導入
- [ ] CoreDataRepositoryの実装
- [ ] SupabaseRepositoryの実装
- [ ] SyncServiceの実装
- [ ] オフライン対応の強化

### フェーズ4: ビューモデルのリファクタリング
- [ ] ViewModelのプロトコル準拠
- [ ] 依存性注入の適用
- [ ] テスタブルな構造への変更

## 詳細な実装計画

### 1. 既存サービスの段階的移行

#### AuthenticationManager → AuthenticationService
```swift
// 現在
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    // 実装
}

// 移行後
class AuthenticationService: AuthenticationServiceProtocol {
    @Injected(ConfigurationServiceProtocol.self)
    private var configService: ConfigurationServiceProtocol
    
    // プロトコル準拠の実装
}
```

#### ReviewManager → LearningActivityService
```swift
// 現在
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    // 実装
}

// 移行後
class LearningActivityService: LearningActivityServiceProtocol {
    @Injected(MemoRepositoryProtocol.self)
    private var memoRepository: MemoRepositoryProtocol
    
    // プロトコル準拠の実装
}
```

### 2. データアクセス層の整理

#### CoreDataRepository の実装
```swift
class CoreDataMemoRepository: MemoRepositoryProtocol {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    func create(_ memo: Memo) async -> Result<Memo, UnifiedError> {
        // CoreData実装
    }
    
    // その他のCRUD操作
}
```

#### SupabaseRepository の実装
```swift
class SupabaseMemoRepository: MemoRepositoryProtocol {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func create(_ memo: Memo) async -> Result<Memo, UnifiedError> {
        // Supabase実装
    }
    
    // その他のCRUD操作
}
```

### 3. 同期戦略の実装

#### SyncService の実装
```swift
class SyncService: SyncServiceProtocol {
    @Injected(MemoRepositoryProtocol.self)
    private var localRepository: MemoRepositoryProtocol
    
    private let remoteRepository: SupabaseMemoRepository
    
    func sync() async -> Result<Void, UnifiedError> {
        // 双方向同期ロジック
    }
}
```

### 4. ビューレイヤーの更新

#### 依存性注入の適用
```swift
struct ContentView: View {
    @Injected(AuthenticationServiceProtocol.self)
    private var authService: AuthenticationServiceProtocol
    
    @Injected(LearningActivityServiceProtocol.self)
    private var learningService: LearningActivityServiceProtocol
    
    var body: some View {
        // UI実装
    }
}
```

## 移行チェックリスト

### フェーズ2: サービス層リファクタリング
- [ ] AuthenticationManager のプロトコル準拠
- [ ] ReviewManager → LearningActivityService
- [ ] TagService のリファクタリング
- [ ] StreakTracker のリファクタリング
- [ ] NotificationManager のプロトコル準拠

### フェーズ3: リポジトリパターン
- [ ] CoreDataMemoRepository の実装
- [ ] SupabaseMemoRepository の実装
- [ ] SyncService の実装
- [ ] オフライン機能の強化
- [ ] データ整合性の保証

### フェーズ4: ビューモデル更新
- [ ] ContentViewModel のリファクタリング
- [ ] ReviewFlowViewModel のリファクタリング
- [ ] 各Feature ViewModelの更新
- [ ] 依存性注入の適用

### フェーズ5: テストの追加
- [ ] ユニットテストの作成
- [ ] モックサービスの実装
- [ ] 統合テストの作成
- [ ] UIテストの更新

## パフォーマンス考慮事項

### 1. 遅延初期化
```swift
@OptionalInjected(HeavyServiceProtocol.self)
private var heavyService: HeavyServiceProtocol?

private func useHeavyService() {
    if heavyService == nil {
        // 必要な時に初期化
    }
}
```

### 2. メモリ効率
- 不要なサービスのアンロード
- 適切なキャッシュ戦略
- weak参照の使用

### 3. 同期性能
- バックグラウンド同期
- 差分同期の実装
- 競合解決戦略

## リスク管理

### 1. 移行リスク
- **段階的移行**: 一度にすべてを変更せず、段階的に移行
- **後方互換性**: 既存の機能を破壊しない
- **ロールバック計画**: 問題が発生した場合の復旧計画

### 2. データ整合性
- **マイグレーション**: データモデルの変更時の適切な移行
- **バックアップ**: 重要なデータの定期バックアップ
- **検証**: データ整合性の定期チェック

### 3. ユーザー影響
- **透明性**: ユーザーには変更を意識させない
- **パフォーマンス**: 移行によるパフォーマンス低下を防ぐ
- **安定性**: 新しいバグの導入を防ぐ

## 成功指標

### 1. 技術指標
- 循環参照の解消（0件）
- 単体テストカバレッジ（80%以上）
- ビルド時間の改善（10%以上短縮）

### 2. 保守性指標
- 新機能追加時間の短縮（30%以上）
- バグ修正時間の短縮（20%以上）
- コードレビュー時間の短縮（25%以上）

### 3. 安定性指標
- クラッシュ率の維持（現在レベル以下）
- パフォーマンス指標の維持
- ユーザー満足度の維持

## タイムライン

### 第1週: フェーズ2開始
- AuthenticationServiceのプロトコル準拠
- LearningActivityServiceの基本実装

### 第2週: フェーズ2完了
- 残りのサービスのリファクタリング
- 基本的なテストの追加

### 第3週: フェーズ3開始
- リポジトリパターンの実装
- SyncServiceの基本機能

### 第4週: フェーズ3完了
- オフライン機能の強化
- データ同期の最適化

### 第5-6週: フェーズ4
- ビューモデルの更新
- UIテストの更新

### 第7週: 最終検証
- 全体的なテスト
- パフォーマンス検証
- ドキュメント更新

## 結論

この移行計画により、RecallMateアプリはより保守性が高く、テストしやすく、拡張可能なアーキテクチャに変革されます。段階的なアプローチにより、リスクを最小限に抑えながら、モダンなiOS開発のベストプラクティスに準拠したアプリケーションを実現できます。