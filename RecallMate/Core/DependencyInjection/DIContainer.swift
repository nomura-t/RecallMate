import Foundation

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
        _ = container
        print("✅ Dependency injection container initialized")
    }
}