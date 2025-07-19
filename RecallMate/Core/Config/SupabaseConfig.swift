import Foundation

struct SupabaseConfig {
    // TODO: Replace with your actual Supabase project values
    // These can be found in your Supabase project dashboard under Settings > API
    
    // 復旧したSupabaseプロジェクトの設定
    static let supabaseURL = "https://tozqfkfjpetipxcdhzwx.supabase.co"
    
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvenFma2ZqcGV0aXB4Y2Roend4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTM2MTcsImV4cCI6MjA2Njg2OTYxN30.Ul6bfKQ8hFiWZWZbF38xw64a4x1B3BQ2vpeoi8lLLes"
    
    // Optional: Service role key for admin operations (keep secure!)
    static let supabaseServiceKey = "YOUR_SUPABASE_SERVICE_ROLE_KEY"
}

// MARK: - How to get these values:
/*
1. Go to your Supabase project dashboard
2. Navigate to Settings > API
3. Copy the following:
   - Project URL (supabaseURL)
   - anon/public key (supabaseAnonKey)
   - service_role key (supabaseServiceKey) - optional, for admin operations

Example values location:
┌─────────────────────────────────────────┐
│ Project URL                             │
│ https://xyzcompany.supabase.co          │
│                                         │
│ API Keys                                │
│ anon public    eyJhbGciOiJIUzI1NiI...  │
│ service_role   eyJhbGciOiJIUzI1NiI...  │
└─────────────────────────────────────────┘
*/