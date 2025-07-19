import Foundation

// MARK: - Async Task Manager

@MainActor
class AsyncTaskManager: ObservableObject {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Task Management
    
    func startTask(id: String, operation: @escaping () async -> Void) {
        // Cancel existing task with same ID
        cancelTask(id: id)
        
        // Start new task
        let task = Task {
            await operation()
        }
        
        activeTasks[id] = task
    }
    
    func cancelTask(id: String) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }
    
    func cancelAllTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    // MARK: - Batch Operations
    
    func executeBatch<T>(_ operations: [() async throws -> T]) async -> [Result<T, Error>] {
        await withTaskGroup(of: Result<T, Error>.self) { group in
            for operation in operations {
                group.addTask {
                    do {
                        let result = try await operation()
                        return .success(result)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var results: [Result<T, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    // MARK: - Debounced Operations
    
    func debounce(id: String, delay: TimeInterval, operation: @escaping () async -> Void) {
        cancelTask(id: id)
        
        let task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if !Task.isCancelled {
                await operation()
            }
        }
        
        activeTasks[id] = task
    }
    
    // MARK: - Retry Logic
    
    func retry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000 * Double(attempt)))
                }
            }
        }
        
        throw lastError ?? AppError.unknown("不明なエラーが発生しました")
    }
}

// MARK: - Extensions

extension AsyncTaskManager {
    static let shared = AsyncTaskManager()
}

