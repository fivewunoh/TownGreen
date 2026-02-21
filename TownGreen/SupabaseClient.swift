//
//  SupabaseClient.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://asacnzkqaypjcleyqbyq.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzYWNuemtxYXlwamNsZXlxYnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2ODU1OTYsImV4cCI6MjA4NzI2MTU5Nn0.yC2Cz5iigZ5JUH1QDDaHWpyBxo2tBJtQ1mfNsSHcG28"
}

extension SupabaseClient {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }()
}
