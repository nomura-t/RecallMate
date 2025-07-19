import Foundation
import Combine
import Supabase

// MARK: - Friendship Service Protocol
/// 友達関係管理サービスのプロトコル
@MainActor
public protocol FriendshipServiceProtocol: ObservableObject {
    var friends: [UnifiedUserProfile] { get }
    var pendingRequests: [FriendRequest] { get }
    var sentRequests: [FriendRequest] { get }
    var isLoading: Bool { get }
    
    func loadFriends() async -> Result<[UnifiedUserProfile], UnifiedError>
    func sendFriendRequest(to userId: String) async -> Result<Void, UnifiedError>
    func acceptFriendRequest(_ request: FriendRequest) async -> Result<Void, UnifiedError>
    func rejectFriendRequest(_ request: FriendRequest) async -> Result<Void, UnifiedError>
    func removeFriend(_ friend: UnifiedUserProfile) async -> Result<Void, UnifiedError>
    func searchUsers(query: String) async -> Result<[UnifiedUserProfile], UnifiedError>
}

// MARK: - Profile Service Protocol
/// プロフィール管理サービスのプロトコル
@MainActor
public protocol ProfileServiceProtocol: ObservableObject {
    var currentUserProfile: UnifiedUserProfile? { get }
    
    func updateProfile(
        fullName: String?,
        nickname: String?,
        bio: String?,
        avatarIconId: String?
    ) async -> Result<Bool, UnifiedError>
    
    func loadCurrentUserProfile() async -> Result<UnifiedUserProfile?, UnifiedError>
    func refreshAllData() async -> Result<Void, UnifiedError>
}

// MARK: - Friend Request Model
public struct FriendRequest: Codable, Identifiable, Equatable {
    public let id: String
    public let senderId: String
    public let receiverId: String
    public let status: FriendRequestStatus
    public let createdAt: Date
    public let updatedAt: Date
    public let senderProfile: UnifiedUserProfile?
    public let receiverProfile: UnifiedUserProfile?
    
    public init(
        id: String,
        senderId: String,
        receiverId: String,
        status: FriendRequestStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        senderProfile: UnifiedUserProfile? = nil,
        receiverProfile: UnifiedUserProfile? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.senderProfile = senderProfile
        self.receiverProfile = receiverProfile
    }
}

public enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
}

// MARK: - Modular Friendship Service Implementation
@MainActor
public class ModularFriendshipService: ObservableObject, FriendshipServiceProtocol {
    
    @Published public var friends: [UnifiedUserProfile] = []
    @Published public var pendingRequests: [FriendRequest] = []
    @Published public var sentRequests: [FriendRequest] = []
    @Published public var isLoading = false
    
    private var authService: (any AuthenticationServiceProtocol)? {
        return DIContainer.shared.resolve((any AuthenticationServiceProtocol).self)
    }
    
    private var eventPublisher: (any EventPublisherProtocol)? {
        return DIContainer.shared.resolve((any EventPublisherProtocol).self)
    }
    
    private let supabaseClient: SupabaseClient
    
    public init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Friendship Operations
    
    public func loadFriends() async -> Result<[UnifiedUserProfile], UnifiedError> {
        guard let currentUserId = authService?.currentUser?.id else {
            return .failure(.authentication(.notAuthenticated))
        }
        
        do {
            isLoading = true
            
            // Supabase クエリで友達一覧を取得
            let response: [FriendshipRecord] = try await supabaseClient
                .from("friendships")
                .select("*, sender_profile:profiles!friendships_sender_id_fkey(*), receiver_profile:profiles!friendships_receiver_id_fkey(*)")
                .or("sender_id.eq.\(currentUserId),receiver_id.eq.\(currentUserId)")
                .eq("status", value: "accepted")
                .execute()
                .value
            
            let friendProfiles = response.compactMap { friendship in
                // 自分以外のプロフィールを取得
                if friendship.senderId == currentUserId {
                    return friendship.receiverProfile?.toUnifiedProfile()
                } else if friendship.receiverId == currentUserId {
                    return friendship.senderProfile?.toUnifiedProfile()
                }
                return nil
            }
            
            friends = friendProfiles
            
            await eventPublisher?.publish(FriendsLoadedEvent(friends: friendProfiles))
            
            isLoading = false
            return .success(friendProfiles)
            
        } catch {
            isLoading = false
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func sendFriendRequest(to userId: String) async -> Result<Void, UnifiedError> {
        guard let currentUserId = authService?.currentUser?.id else {
            return .failure(.authentication(.notAuthenticated))
        }
        
        do {
            let request = CreateFriendRequestData(
                senderId: currentUserId,
                receiverId: userId,
                status: "pending"
            )
            
            let _: FriendshipRecord = try await supabaseClient
                .from("friendships")
                .insert(request)
                .execute()
                .value
            
            await eventPublisher?.publish(FriendRequestSentEvent(receiverId: userId))
            
            return .success(())
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func acceptFriendRequest(_ request: FriendRequest) async -> Result<Void, UnifiedError> {
        do {
            let _: FriendshipRecord = try await supabaseClient
                .from("friendships")
                .update(["status": "accepted", "updated_at": Date().ISO8601String()])
                .eq("id", value: request.id)
                .execute()
                .value
            
            // ローカル状態を更新
            pendingRequests.removeAll { $0.id == request.id }
            
            // 友達リストを再読み込み
            let _ = await loadFriends()
            
            await eventPublisher?.publish(FriendRequestAcceptedEvent(request: request))
            
            return .success(())
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func rejectFriendRequest(_ request: FriendRequest) async -> Result<Void, UnifiedError> {
        do {
            let _: FriendshipRecord = try await supabaseClient
                .from("friendships")
                .update(["status": "rejected", "updated_at": Date().ISO8601String()])
                .eq("id", value: request.id)
                .execute()
                .value
            
            // ローカル状態を更新
            pendingRequests.removeAll { $0.id == request.id }
            
            await eventPublisher?.publish(FriendRequestRejectedEvent(request: request))
            
            return .success(())
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func removeFriend(_ friend: UnifiedUserProfile) async -> Result<Void, UnifiedError> {
        guard let currentUserId = authService?.currentUser?.id else {
            return .failure(.authentication(.notAuthenticated))
        }
        
        do {
            let _: FriendshipRecord = try await supabaseClient
                .from("friendships")
                .delete()
                .or("sender_id.eq.\(currentUserId),receiver_id.eq.\(currentUserId)")
                .or("sender_id.eq.\(friend.id),receiver_id.eq.\(friend.id)")
                .eq("status", value: "accepted")
                .execute()
                .value
            
            // ローカル状態を更新
            friends.removeAll { $0.id == friend.id }
            
            await eventPublisher?.publish(FriendRemovedEvent(friend: friend))
            
            return .success(())
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func searchUsers(query: String) async -> Result<[UnifiedUserProfile], UnifiedError> {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .success([])
        }
        
        do {
            let response: [SupabaseProfile] = try await supabaseClient
                .from("profiles")
                .select("*")
                .or("full_name.ilike.*\(query)*,nickname.ilike.*\(query)*")
                .limit(20)
                .execute()
                .value
            
            let profiles = response.map { $0.toUnifiedProfile() }
            
            return .success(profiles)
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
}

// MARK: - Modular Profile Service Implementation
@MainActor
public class ModularProfileService: ObservableObject, ProfileServiceProtocol {
    
    @Published public var currentUserProfile: UnifiedUserProfile?
    
    private var authService: (any AuthenticationServiceProtocol)? {
        return DIContainer.shared.resolve((any AuthenticationServiceProtocol).self)
    }
    
    private var eventPublisher: (any EventPublisherProtocol)? {
        return DIContainer.shared.resolve((any EventPublisherProtocol).self)
    }
    
    private let supabaseClient: SupabaseClient
    
    public init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    public func updateProfile(
        fullName: String?,
        nickname: String?,
        bio: String?,
        avatarIconId: String?
    ) async -> Result<Bool, UnifiedError> {
        guard let userId = authService?.currentUser?.id else {
            return .failure(.authentication(.notAuthenticated))
        }
        
        do {
            let updateData = ProfileUpdateData(
                fullName: fullName,
                nickname: nickname,
                bio: bio,
                avatarIconId: avatarIconId,
                updatedAt: Date().ISO8601String()
            )
            
            let _: SupabaseProfile = try await supabaseClient
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
                .value
            
            // ローカルプロフィールを更新
            let _ = await loadCurrentUserProfile()
            
            await eventPublisher?.publish(ProfileUpdatedEvent(userId: userId))
            
            return .success(true)
            
        } catch {
            return .failure(.network(.requestFailed(error.localizedDescription)))
        }
    }
    
    public func loadCurrentUserProfile() async -> Result<UnifiedUserProfile?, UnifiedError> {
        guard let userId = authService?.currentUser?.id else {
            return .failure(.authentication(.notAuthenticated))
        }
        
        do {
            let response: SupabaseProfile = try await supabaseClient
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            let profile = response.toUnifiedProfile()
            currentUserProfile = profile
            
            return .success(profile)
            
        } catch {
            return .failure(.data(.notFound))
        }
    }
    
    public func refreshAllData() async -> Result<Void, UnifiedError> {
        let _ = await loadCurrentUserProfile()
        return .success(())
    }
}

// MARK: - Supporting Data Structures

private struct FriendshipRecord: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let status: String
    let createdAt: String
    let updatedAt: String
    let senderProfile: SupabaseProfile?
    let receiverProfile: SupabaseProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case senderProfile = "sender_profile"
        case receiverProfile = "receiver_profile"
    }
}

private struct CreateFriendRequestData: Encodable {
    let senderId: String
    let receiverId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
    }
}

private struct SupabaseProfile: Codable {
    let id: String
    let email: String?
    let fullName: String?
    let nickname: String?
    let avatarUrl: String?
    let bio: String?
    let statusMessage: String?
    let isOnline: Bool?
    let lastActiveAt: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case nickname
        case avatarUrl = "avatar_url"
        case bio
        case statusMessage = "status_message"
        case isOnline = "is_online"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toUnifiedProfile() -> UnifiedUserProfile {
        return UnifiedUserProfile(
            id: id,
            email: email,
            fullName: fullName,
            nickname: nickname,
            avatarURL: avatarUrl,
            avatarIconId: avatarUrl, // アイコンIDとして使用
            bio: bio,
            statusMessage: statusMessage,
            isOnline: isOnline ?? false,
            lastActiveAt: lastActiveAt?.toDate(),
            createdAt: createdAt?.toDate() ?? Date(),
            updatedAt: updatedAt?.toDate() ?? Date()
        )
    }
}

private struct ProfileUpdateData: Encodable {
    let fullName: String?
    let nickname: String?
    let bio: String?
    let avatarIconId: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case nickname
        case bio
        case avatarIconId = "avatar_url"
        case updatedAt = "updated_at"
    }
}

// MARK: - Events

public struct FriendsLoadedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let friends: [UnifiedUserProfile]
    
    public init(friends: [UnifiedUserProfile]) {
        self.friends = friends
    }
}

public struct FriendRequestSentEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let receiverId: String
    
    public init(receiverId: String) {
        self.receiverId = receiverId
    }
}

public struct FriendRequestAcceptedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let request: FriendRequest
    
    public init(request: FriendRequest) {
        self.request = request
    }
}

public struct FriendRequestRejectedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let request: FriendRequest
    
    public init(request: FriendRequest) {
        self.request = request
    }
}

public struct FriendRemovedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let friend: UnifiedUserProfile
    
    public init(friend: UnifiedUserProfile) {
        self.friend = friend
    }
}

public struct ProfileUpdatedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let userId: String
    
    public init(userId: String) {
        self.userId = userId
    }
}

// MARK: - Helper Extensions

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}

private extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}