import Foundation
import Combine

// MARK: - Dependency Injection Container
/// シンプルで効率的な依存性注入コンテナ
public class DIContainer {
    public static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let queue = DispatchQueue(label: "DIContainer", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Registration
    
    /// シングルトンサービスを登録
    public func register<T>(_ type: T.Type, instance: T) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.services[key] = instance
        }
    }
    
    /// ファクトリーベースのサービスを登録
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.factories[key] = factory
        }
    }
    
    /// プロトコルベースの登録
    public func register<T>(_ protocolType: T.Type, implementation: T) {
        register(protocolType, instance: implementation)
    }
    
    // MARK: - Resolution
    
    /// サービスを解決
    public func resolve<T>(_ type: T.Type) -> T? {
        return queue.sync {
            let key = String(describing: type)
            
            // 既存のインスタンスをチェック
            if let instance = services[key] as? T {
                return instance
            }
            
            // ファクトリーから作成
            if let factory = factories[key] {
                let instance = factory() as? T
                if let instance = instance {
                    services[key] = instance // キャッシュ
                }
                return instance
            }
            
            return nil
        }
    }
    
    /// 必須解決（クラッシュする可能性あり）
    public func resolveRequired<T>(_ type: T.Type, file: String = #file, line: Int = #line) -> T {
        guard let service = resolve(type) else {
            fatalError("Failed to resolve required service: \(type) at \(file):\(line)")
        }
        return service
    }
    
    // MARK: - Management
    
    /// 特定のサービスを削除
    public func unregister<T>(_ type: T.Type) {
        queue.async(flags: .barrier) {
            let key = String(describing: type)
            self.services.removeValue(forKey: key)
            self.factories.removeValue(forKey: key)
        }
    }
    
    /// すべてのサービスをクリア
    public func clear() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
            self.factories.removeAll()
        }
    }
}

// MARK: - Service Locator Pattern
/// サービスロケーターパターンの実装
@propertyWrapper
public struct Injected<T> {
    private let keyPath: KeyPath<DIContainer, T>?
    private let type: T.Type
    
    public init(_ type: T.Type) {
        self.type = type
        self.keyPath = nil
    }
    
    public var wrappedValue: T {
        return DIContainer.shared.resolveRequired(type)
    }
}

// MARK: - Optional Injection
@propertyWrapper
public struct OptionalInjected<T> {
    private let type: T.Type
    
    public init(_ type: T.Type) {
        self.type = type
    }
    
    public var wrappedValue: T? {
        return DIContainer.shared.resolve(type)
    }
}

// MARK: - Container Bootstrap
/// アプリケーション起動時の依存性設定
public struct AppDependencies {
    
    public static func bootstrap() {
        let container = DIContainer.shared
        
        // Core Services
        bootstrapCoreServices(container)
        
        // Repository Layer
        bootstrapRepositories(container)
        
        // Use Case Layer
        bootstrapUseCases(container)
        
        // Infrastructure
        bootstrapInfrastructure(container)
        
        print("✅ Dependency injection container initialized")
    }
    
    private static func bootstrapCoreServices(_ container: DIContainer) {
        // Authentication
        container.register((any AuthenticationServiceProtocol).self) {
            return MainActor.assumeIsolated {
                AuthenticationServiceAdapter()
            }
        }
        
        // Event Publisher
        container.register((any EventPublisherProtocol).self) {
            return EventPublisher()
        }
        
        // Configuration
        container.register((any ConfigurationServiceProtocol).self) {
            return UserDefaultsConfigurationService()
        }
        
        // Notification Service
        // TODO: NotificationManagerをNotificationServiceProtocolに準拠させる
        // container.register(NotificationServiceProtocol.self) {
        //     return NotificationManager.shared
        // }
    }
    
    private static func bootstrapRepositories(_ container: DIContainer) {
        // Memo Repository
        container.register((any MemoRepositoryProtocol).self) {
            return MainActor.assumeIsolated {
                CoreDataMemoRepository()
            }
        }
        
        // Sync Service
        container.register((any SyncServiceProtocol).self) {
            return MainActor.assumeIsolated {
                SupabaseSyncService()
            }
        }
    }
    
    private static func bootstrapUseCases(_ container: DIContainer) {
        // Learning Activity Service
        container.register((any LearningActivityServiceProtocol).self) {
            return MainActor.assumeIsolated {
                LearningActivityService() as any LearningActivityServiceProtocol
            }
        }
        
        // Analytics Service
        container.register((any AnalyticsServiceProtocol).self) {
            return FirebaseAnalyticsService()
        }
    }
    
    private static func bootstrapInfrastructure(_ container: DIContainer) {
        // Infrastructure services can be registered here
        // e.g., Network clients, File managers, etc.
    }
}

// MARK: - Event Publisher Implementation
public class EventPublisher: EventPublisherProtocol, ObservableObject {
    private var subscriptions: [String: [(Any) async -> Void]] = [:]
    private let queue = DispatchQueue(label: "EventPublisher", attributes: .concurrent)
    
    public init() {}
    
    public func publish<T: AppEvent>(_ event: T) async {
        let eventType = String(describing: T.self)
        
        let handlers = queue.sync {
            return subscriptions[eventType] ?? []
        }
        
        for handler in handlers {
            await handler(event)
        }
    }
    
    public func subscribe<T: AppEvent>(to eventType: T.Type, handler: @escaping (T) async -> Void) -> AnyCancellable {
        let eventTypeName = String(describing: eventType)
        let _ = UUID().uuidString
        
        queue.async(flags: .barrier) {
            if self.subscriptions[eventTypeName] == nil {
                self.subscriptions[eventTypeName] = []
            }
            
            let wrappedHandler: (Any) async -> Void = { event in
                if let typedEvent = event as? T {
                    await handler(typedEvent)
                }
            }
            
            self.subscriptions[eventTypeName]?.append(wrappedHandler)
        }
        
        return AnyCancellable {
            // Note: For simplicity, we're not implementing unsubscription here
            // In a production app, you'd want to track and remove specific handlers
        }
    }
}

// MARK: - Configuration Service Implementation
public class UserDefaultsConfigurationService: ConfigurationServiceProtocol {
    private let userDefaults = UserDefaults.standard
    
    public init() {}
    
    public func getValue<T>(for key: ConfigurationKey, type: T.Type) -> T? {
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    public func setValue<T>(_ value: T, for key: ConfigurationKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
    
    public func removeValue(for key: ConfigurationKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
    
    public func reset() {
        for key in ConfigurationKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }
}

// MARK: - Convenience Extensions
extension DIContainer {
    /// よく使用されるサービスのコンビニエンスプロパティ
    public var authService: (any AuthenticationServiceProtocol)? {
        return resolve((any AuthenticationServiceProtocol).self) as (any AuthenticationServiceProtocol)?
    }
    
    public var eventPublisher: (any EventPublisherProtocol)? {
        return resolve((any EventPublisherProtocol).self)
    }
    
    public var configService: (any ConfigurationServiceProtocol)? {
        return resolve((any ConfigurationServiceProtocol).self)
    }
    
    public var memoRepository: (any MemoRepositoryProtocol)? {
        return resolve((any MemoRepositoryProtocol).self) as (any MemoRepositoryProtocol)?
    }
}