# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RecallMate is an iOS app built with SwiftUI that helps users track learning activities and manage recall-based studying. The app focuses on spaced repetition learning techniques and time-based study tracking.

## Development Commands

### Building and Running
- **Build**: Use Xcode to build the project (`⌘+B`)
- **Run**: Use Xcode to run on simulator or device (`⌘+R`)
- **Test**: Use Xcode to run tests (`⌘+U`)

### Testing
- **Unit Tests**: Located in `RecallMateTests/`
- **UI Tests**: Located in `RecallMateUITests/`
- Tests use Swift Testing framework (`import Testing`)

## Architecture

### Core Data Model
The app uses Core Data with the following main entities:
- **Memo**: Primary learning content with recall scores and review dates
- **LearningActivity**: Time-tracked activities with types (reading, exercise, lecture, etc.)
- **Tag**: Categorization system for memos
- **StreakData**: Tracks learning streaks and consistency
- **ComparisonQuestion**: Custom questions for memo review
- **MemoHistoryEntry**: Historical recall performance data

### App Structure
- **SwiftUI + MVVM**: Uses SwiftUI with view models for state management
- **Three-tab interface**:
  1. 復習管理 (Review Management) - `HomeView`
  2. 作業記録 (Work Recording) - `WorkTimerView`  
  3. 振り返り (Reflection) - `ActivityProgressView`

### Key Managers
- **PersistenceController**: Core Data stack management
- **ReviewManager**: App Store review prompts and task completion tracking
- **StreakTracker**: Learning streak calculation and maintenance
- **NotificationSettingsManager**: Push notification management
- **TagService**: Tag management and operations

### Localization
- Supports multiple languages: English, Japanese, Chinese (Simplified/Traditional/Hong Kong)
- Localization files in `*.lproj/Localizable.strings`

## File Organization

### Core Files
- `RecallMateApp.swift`: Main app entry point with Core Data initialization
- `MainView.swift`: Tab-based main interface
- `Persistence.swift`: Core Data setup and preview data
- `ContentView.swift`: Main memo creation/editing interface

### Feature Areas
- **Timer/Work Tracking**: `WorkTimerView.swift`, `WorkTimerManager.swift`
- **Review System**: `ReviewCalculator.swift`, `ReviewManager.swift`
- **Activity Tracking**: `ActivityProgressView.swift`, `ActivityTracker.swift`
- **Settings**: `AppSettings.swift`, `SettingsView.swift`
- **Notifications**: `NotificationSettingsManager.swift`, `StreakNotificationManager.swift`

### UI Components
- Shared components in `SharedComponents.swift`
- Canvas/drawing support with PencilKit integration
- Tag management UI in `TagChip.swift`, `TagSelectionView.swift`

## Code Conventions

- Swift naming conventions (camelCase, PascalCase)
- Japanese comments throughout codebase
- SwiftUI declarative syntax
- Core Data with `@FetchRequest` and `@StateObject`
- Environment objects for shared state (`AppSettings`)
- Combine framework for reactive programming where applicable