// StreakCardView.swift
import SwiftUI
import CoreData

struct StreakCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "StreakData", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(keyPath: \StreakData.lastActiveDate, ascending: true)]
    )
    private var streakData: FetchedResults<StreakData>
    
    var currentStreak: Int {
        Int(streakData.first?.currentStreak ?? 0)
    }
    
    var longestStreak: Int {
        Int(streakData.first?.longestStreak ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { // spacing を小さく
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 22)) // サイズを小さく
                
                Text("%d 日連続".localizedWithInt(currentStreak))
                    .font(.subheadline) // フォントサイズを小さく
                    .foregroundColor(.primary)
            }
            
            Text("%d 日連続".localizedWithInt(currentStreak))
                .font(.caption) // より小さいフォント
                .foregroundColor(.gray)
        }
        .padding(12) // パディングを小さく
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
            .shadow(radius: 2))
    }
}
