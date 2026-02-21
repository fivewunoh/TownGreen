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
    static let anonKey = "sb_publishable_aA7IZuGYfp3EihD4uUbGDg_pN4jPxUE"
}

extension SupabaseClient {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }()
}
