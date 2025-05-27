// TimePickerView.swift - 通知時間選択のためのピッカー
import SwiftUI

struct TimePickerView: View {
    @Binding var selectedTime: Date
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "通知時間",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .navigationTitle("通知時間を設定")
            .navigationBarItems(
                leading: Button("キャンセル", action: onCancel),
                trailing: Button("保存", action: onSave)
            )
        }
    }
}
