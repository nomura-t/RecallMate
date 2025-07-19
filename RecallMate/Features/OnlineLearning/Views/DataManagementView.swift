import SwiftUI

struct DataManagementView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isLoading = false
    @State private var showingBackupConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var statusMessage: String?
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 接続状態
                    connectionStatusSection
                    
                    // データ同期
                    if authManager.isAuthenticated {
                        dataSyncSection
                        
                        // バックアップ・復元
                        backupRestoreSection
                        
                        // エクスポート・インポート
                        exportImportSection
                    } else {
                        authenticationPrompt
                    }
                    
                    // ストレージ情報
                    storageInfoSection
                }
                .padding()
            }
            .navigationTitle("データ管理")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました")
        }
        .confirmationDialog("バックアップ", isPresented: $showingBackupConfirmation) {
            Button("すべてのデータをバックアップ") {
                Task {
                    await performBackup()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在のデータをクラウドにバックアップしますか？")
        }
        .confirmationDialog("復元", isPresented: $showingRestoreConfirmation) {
            Button("バックアップから復元", role: .destructive) {
                Task {
                    await performRestore()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("バックアップからデータを復元しますか？\n現在のデータは上書きされます。")
        }
    }
    
    // MARK: - Sections
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("接続状態")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(supabaseManager.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(supabaseManager.connectionStatus)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !supabaseManager.isConnected {
                    Button("接続") {
                        Task {
                            await supabaseManager.connect()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var dataSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("データ同期")
                .font(.headline)
            
            VStack(spacing: 12) {
                // 自動同期設定
                HStack {
                    Text("自動同期")
                    Spacer()
                    Text("未実装")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Divider()
                
                // 最終同期日時
                HStack {
                    Text("最終同期")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("未同期")
                        .foregroundColor(.secondary)
                }
                
                // 手動同期ボタン
                Button(action: {
                    Task {
                        await performSync()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("今すぐ同期")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var backupRestoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("バックアップ・復元")
                .font(.headline)
            
            HStack(spacing: 12) {
                // バックアップボタン
                Button(action: {
                    showingBackupConfirmation = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title2)
                        Text("バックアップ")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
                .disabled(isLoading || !supabaseManager.isConnected)
                
                // 復元ボタン
                Button(action: {
                    showingRestoreConfirmation = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.title2)
                        Text("復元")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
                .disabled(isLoading || !supabaseManager.isConnected)
            }
            
            // 最終バックアップ日時は将来実装
        }
    }
    
    private var exportImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("エクスポート・インポート")
                .font(.headline)
            
            HStack(spacing: 12) {
                // エクスポートボタン
                Button(action: {
                    showingExportOptions = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("エクスポート")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                // インポートボタン
                Button(action: {
                    showingImportPicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                        Text("インポート")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
    }
    
    private var authenticationPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.icloud")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("クラウド機能を使用するには")
                .font(.headline)
            
            Text("データの同期・バックアップ機能を利用するには、アカウントにログインしてください。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: LoginView()) {
                Text("ログイン・新規登録")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var storageInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ストレージ情報")
                .font(.headline)
            
            VStack(spacing: 8) {
                storageInfoRow(label: "メモ数", value: "---")
                storageInfoRow(label: "タグ数", value: "---")
                storageInfoRow(label: "学習記録", value: "---")
                
                Divider()
                
                storageInfoRow(label: "使用容量", value: "---")
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func storageInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Methods
    
    private func performSync() async {
        isLoading = true
        statusMessage = "同期中..."
        
        // 同期機能は将来実装
        errorMessage = "同期機能は現在開発中です"
        showError = true
        
        isLoading = false
    }
    
    private func performBackup() async {
        isLoading = true
        statusMessage = "バックアップ中..."
        
        // バックアップ機能は将来実装
        errorMessage = "バックアップ機能は現在開発中です"
        showError = true
        
        isLoading = false
    }
    
    private func performRestore() async {
        isLoading = true
        statusMessage = "復元中..."
        
        // 復元機能は将来実装
        errorMessage = "復元機能は現在開発中です"
        showError = true
        
        isLoading = false
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview

struct DataManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DataManagementView()
    }
}