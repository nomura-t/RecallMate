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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 28))
                
                Text("\(currentStreak) 日連続")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text("最長記録: \(longestStreak) 日")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
            .shadow(radius: 2))
    }
}
