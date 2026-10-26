import Foundation
import Supabase

/// Provides the shared Supabase client configured by the app's build settings.
enum SupabaseService {
    /// Client shared by all app scenes and services for the lifetime of the process.
    static let client: SupabaseClient = {
        // Project endpoint expanded from the selected xcconfig into the app bundle.
        guard let projectURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PROJECT_URL") as? String,
              let url = URL(string: projectURL),
              url.scheme == "https",
              let host = url.host(), !host.isEmpty
        else {
            fatalError("Set a valid SUPABASE_PROJECT_URL in Config/development.xcconfig.")
        }

        // Only a publishable client key belongs in the shipped application.
        guard let publishableKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              publishableKey.hasPrefix("sb_publishable_")
        else {
            fatalError("Set SUPABASE_PUBLISHABLE_KEY in Config/development.xcconfig to a publishable key.")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: publishableKey,
            options: SupabaseClientOptions(
                // Initial sessions can be expired; check isExpired before using them for signed-in UI.
                auth: .init(emitLocalSessionAsInitialSession: true),
            ),
        )
    }()
}
