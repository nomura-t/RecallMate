import Foundation

/**
 # RecallMate クリーンアーキテクチャガイド
 
 このファイルは、RecallMateアプリのクリーンアーキテクチャ実装のガイドとなる構造を示しています。
 
 ## アーキテクチャ層
 
 ### 1. Domain Layer (Core/Models/Domain/)
 - **UnifiedModels.swift**: 統一されたドメインモデル
 - **ServiceProtocols.swift**: ビジネスロジックのプロトコル
 - **AppError.swift**: 統一されたエラーハンドリング
 
 ### 2. Use Case Layer (Core/UseCases/)
 - **AuthenticationUseCase**: 認証関連のビジネスロジック
 - **LearningActivityUseCase**: 学習活動の管理
 - **FriendshipUseCase**: 友達関係の管理
 
 ### 3. Interface Adapters (Core/Services/)
 - **Repositories**: データアクセスの抽象化
 - **Services**: 外部システムとの連携
 - **Managers**: 従来のマネージャークラス（段階的に移行）
 
 ### 4. Infrastructure Layer (Core/Infrastructure/)
 - **CoreData**: ローカルデータストレージ
 - **Supabase**: リモートデータストレージ
 - **Network**: ネットワーク通信
 
 ### 5. Presentation Layer (Features/)
 - **Views**: SwiftUIビュー
 - **ViewModels**: プレゼンテーションロジック
 - **Coordinators**: ナビゲーションロジック
 
 ## 依存性の方向
 
 ```
 Presentation → Use Cases → Domain ← Interface Adapters ← Infrastructure
 ```
 
 - **Domain Layer**: 他の層に依存しない
 - **Use Case Layer**: Domainのみに依存
 - **Interface Adapters**: DomainとUse Caseに依存
 - **Infrastructure**: Interface Adaptersに依存
 - **Presentation**: Use CaseとDomainに依存
 
 ## 依存性注入パターン
 
 ### DIContainer の使用
 ```swift
 @Injected(AuthenticationServiceProtocol.self)
 private var authService: AuthenticationServiceProtocol
 ```
 
 ### プロトコル指向設計
 ```swift
 protocol AuthenticationServiceProtocol {
     func signIn(email: String, password: String) async -> Result<User, AuthError>
 }
 ```
 
 ## イベントドリブンアーキテクチャ
 
 ### イベントの発行
 ```swift
 await eventPublisher.publish(UserAuthenticatedEvent(user: user))
 ```
 
 ### イベントの購読
 ```swift
 eventPublisher.subscribe(to: UserAuthenticatedEvent.self) { event in
     // Handle user authentication
 }
 ```
 
 ## エラーハンドリング戦略
 
 ### 統一されたエラーモデル
 ```swift
 enum UnifiedError: Error {
     case authentication(AuthenticationError)
     case network(NetworkError)
     case data(DataError)
 }
 ```
 
 ### Result型の活用
 ```swift
 func performOperation() async -> Result<Data, UnifiedError> {
     // Implementation
 }
 ```
 
 ## テスト戦略
 
 ### プロトコルベースのモッキング
 ```swift
 class MockAuthService: AuthenticationServiceProtocol {
     // Mock implementation
 }
 ```
 
 ### 依存性注入によるテスト
 ```swift
 func testAuthentication() {
     DIContainer.shared.register(AuthenticationServiceProtocol.self, instance: MockAuthService())
     // Test implementation
 }
 ```
 
 ## 移行戦略
 
 ### 段階的なリファクタリング
 1. **フェーズ1**: 新しいプロトコルとDIコンテナの導入
 2. **フェーズ2**: 既存のマネージャークラスのプロトコル準拠
 3. **フェーズ3**: 循環参照の解消とモジュール分離
 4. **フェーズ4**: 完全なクリーンアーキテクチャへの移行
 
 ### 新機能での適用
 - 新しい機能は最初からクリーンアーキテクチャで実装
 - 既存機能は段階的にリファクタリング
 
 ## パフォーマンス考慮事項
 
 ### 遅延初期化
 ```swift
 @OptionalInjected(HeavyServiceProtocol.self)
 private var heavyService: HeavyServiceProtocol?
 ```
 
 ### メモリ管理
 - weak参照を適切に使用
 - 不要なオブザーバーの解除
 - DIコンテナからの適切なクリーンアップ
 
 ## セキュリティ考慮事項
 
 ### 認証状態の管理
 - セキュアなトークンストレージ
 - 適切なセッション管理
 - 権限ベースのアクセス制御
 
 ### データの保護
 - 機密データの暗号化
 - セキュアな通信（HTTPS/TLS）
 - 入力値の検証とサニタイズ
 */

// MARK: - Architecture Enforcement

/// アーキテクチャ規則を強制するためのマーカープロトコル
public protocol DomainModel {}
public protocol UseCase {}
public protocol Repository {}
public protocol Service {}
public protocol ViewModel {}

/// レイヤー間の依存性を制御するための型安全性
public struct ArchitectureBoundary {
    // Domain Layer は他の層に依存してはいけない
    public struct Domain {
        private init() {} // インスタンス化を防ぐ
    }
    
    // Use Case Layer は Domain にのみ依存できる
    public struct UseCase {
        private init() {}
    }
    
    // Infrastructure Layer は Interface Adapters に依存できる
    public struct Infrastructure {
        private init() {}
    }
    
    // Presentation Layer は Use Case と Domain に依存できる
    public struct Presentation {
        private init() {}
    }
}

// MARK: - Code Quality Guidelines

/**
 ## コード品質ガイドライン
 
 ### 1. SOLID原則の適用
 - **S**ingle Responsibility: 各クラスは一つの責任のみ
 - **O**pen/Closed: 拡張に対して開いて、変更に対して閉じる
 - **L**iskov Substitution: サブタイプは基底タイプと置換可能
 - **I**nterface Segregation: クライアントが不要なメソッドに依存しない
 - **D**ependency Inversion: 抽象に依存し、具象に依存しない
 
 ### 2. 命名規則
 - **Protocol**: `~Protocol` または `~able` サフィックス
 - **Service**: `~Service` サフィックス
 - **Repository**: `~Repository` サフィックス
 - **UseCase**: `~UseCase` サフィックス
 - **ViewModel**: `~ViewModel` サフィックス
 
 ### 3. ファイル構成
 ```
 Core/
 ├── Models/
 │   ├── Domain/          # ドメインモデル
 │   └── CoreData/        # CoreDataモデル
 ├── Protocols/           # サービスプロトコル
 ├── UseCases/           # ビジネスロジック
 ├── Services/           # サービス実装
 ├── Repositories/       # データアクセス
 └── Infrastructure/     # 外部システム連携
 ```
 
 ### 4. テストケース
 - 各Use Caseに対するユニットテスト
 - プロトコルベースのモッキング
 - 統合テストでの実際のフロー検証
 
 ### 5. ドキュメント
 - 各プロトコルの責任と契約の明確化
 - アーキテクチャ決定記録（ADR）の維持
 - コード例とベストプラクティスの共有
 */