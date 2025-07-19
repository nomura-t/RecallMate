# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RecallMate is an iOS app built with SwiftUI that implements spaced repetition learning techniques with social features. The app helps users track learning activities, manage recall-based studying, and connect with other learners.

## Development Commands

### Building and Running
- **Build**: Xcode → Product → Build (`⌘+B`)
- **Run**: Xcode → Product → Run (`⌘+R`)
- **Clean**: Xcode → Product → Clean Build Folder (`⌘+⇧+K`)
- **Test**: Xcode → Product → Test (`⌘+U`)

### Testing
- **Run specific test**: Click on the diamond next to test method in Xcode
- **Test files**: `RecallMateTests/` (uses Swift Testing framework with `import Testing`)
- **UI Tests**: `RecallMateUITests/`

### Linting and Type Checking
- **Swift format**: Use Xcode's built-in formatting (`⌃+I`)
- **SwiftLint**: If installed, runs automatically during build

## Architecture

### Core Stack
- **SwiftUI + MVVM** with `@StateObject` and `ObservableObject`
- **Core Data** for local persistence
- **Supabase** for cloud sync and authentication
- **Combine** for reactive programming

### Authentication System
- **Providers**: Apple Sign In, Google Sign In, Guest (Anonymous)
- **Manager**: `AuthenticationManager.shared` (singleton)
- **State**: `AuthenticationStateManager` handles auth state
- **Guest Features**: Limited functionality defined in `GuestUserFeatures.swift`

### Data Layer
Core Data Entities:
- `Memo` - Learning content with spaced repetition tracking
- `LearningActivity` - Time-tracked study sessions
- `Tag` - Content categorization
- `MemoHistoryEntry` - Review performance history
- `StudyGroup`, `GroupMember` - Social learning features
- `SocialNotification` - In-app notifications

### Feature Organization
```
RecallMate/
├── Core/
│   ├── Models/         # Core Data models, domain models
│   ├── Services/       # Business logic, managers
│   └── Protocols/      # Service protocols for DI
├── Features/
│   ├── Home/          # Main review interface
│   ├── MemoManagement/# CRUD operations for memos
│   ├── WorkTimer/     # Study session tracking
│   ├── Social/        # Friends, groups, rankings
│   ├── Profile/       # User profile management
│   └── Authentication/# Login/signup flows
└── Shared/
    └── Components/    # Reusable UI components
```

### Social Features Architecture
- **Friends System**: Follow/follower relationships
- **Study Groups**: Create/join groups with member roles
- **Rankings**: Leaderboards based on study time
- **Notifications**: Real-time updates for social interactions
- **Gradual Access Model**: Public content viewable without auth

### Key Managers and Services
- `PersistenceController` - Core Data stack
- `SupabaseManager` - Cloud sync and auth
- `ReviewCalculator` - Spaced repetition algorithm
- `NotificationManager` - In-app notifications
- `FriendshipManager` - Social connections
- `StudyGroupManager` - Group functionality

### Dependency Injection
- `DIContainer` provides service instances
- Protocol-based design for testability
- Unified models in `UnifiedModels.swift`

## Localization
- Languages: English, Japanese, Chinese (Simplified/Traditional)
- Files: `*.lproj/Localizable.strings`
- Usage: `"key".localized` extension

## Supabase Configuration
Required tables (see SQL files in project root):
- `user_profiles` - Extended user data
- `study_groups` - Group information
- `group_members` - Group membership
- `friendships` - Friend relationships
- `social_notifications` - Notification data

## Recent Major Updates
1. **Authentication System** - Apple/Google/Guest login
2. **Social Features** - Friends, groups, rankings
3. **Profile Management** - Editable user profiles
4. **Guest User Support** - Limited feature access
5. **Clean Architecture** - Protocol-based services with DI