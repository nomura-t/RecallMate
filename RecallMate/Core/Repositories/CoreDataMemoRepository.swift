import Foundation
import CoreData

// MARK: - CoreData Memo Repository
/// CoreDataを使用したMemoリポジトリの実装
@MainActor
public class CoreDataMemoRepository: MemoRepositoryProtocol {
    
    public let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - DataRepositoryProtocol
    
    public func create(_ entity: Memo) async -> Result<Memo, UnifiedError> {
        do {
            context.insert(entity)
            try context.save()
            return .success(entity)
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func read(id: UUID?) async -> Result<Memo?, UnifiedError> {
        guard let uuid = id else {
            return .failure(.data(.notFound))
        }
        
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            let memos = try context.fetch(request)
            return .success(memos.first)
        } catch {
            return .failure(.data(.notFound))
        }
    }
    
    public func update(_ entity: Memo) async -> Result<Memo, UnifiedError> {
        do {
            try context.save()
            return .success(entity)
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func delete(id: UUID?) async -> Result<Void, UnifiedError> {
        guard let uuid = id else {
            return .failure(.data(.notFound))
        }
        
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            let memos = try context.fetch(request)
            guard let memo = memos.first else {
                return .failure(.data(.notFound))
            }
            
            context.delete(memo)
            try context.save()
            return .success(())
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func list() async -> Result<[Memo], UnifiedError> {
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "trashDate == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Memo.createdAt, ascending: false)]
        
        do {
            let memos = try context.fetch(request)
            return .success(memos)
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    // MARK: - MemoRepositoryProtocol
    
    public func searchMemos(query: String) async -> Result<[Memo], UnifiedError> {
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(
            format: "(title CONTAINS[cd] %@ OR content CONTAINS[cd] %@) AND trashDate == nil", 
            query, query
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Memo.createdAt, ascending: false)]
        
        do {
            let memos = try context.fetch(request)
            return .success(memos)
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func getMemosDueForReview() async -> Result<[Memo], UnifiedError> {
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(
            format: "nextReviewDate <= %@ AND trashDate == nil", 
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)]
        
        do {
            let memos = try context.fetch(request)
            return .success(memos)
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func updateReviewDate(memoId: String, nextReviewDate: Date) async -> Result<Void, UnifiedError> {
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", memoId)
        request.fetchLimit = 1
        
        do {
            if let memo = try context.fetch(request).first {
                memo.nextReviewDate = nextReviewDate
                memo.lastReviewedDate = Date()
                try context.save()
                return .success(())
            } else {
                return .failure(.data(.notFound))
            }
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func updateRecallScore(memoId: String, score: Int) async -> Result<Void, UnifiedError> {
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", memoId)
        request.fetchLimit = 1
        
        do {
            if let memo = try context.fetch(request).first {
                memo.recallScore = Int16(score)
                try context.save()
                return .success(())
            } else {
                return .failure(.data(.notFound))
            }
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
}

// MARK: - Type Alias for ID
extension CoreDataMemoRepository {
    public typealias ID = UUID?
    public typealias Entity = Memo
}