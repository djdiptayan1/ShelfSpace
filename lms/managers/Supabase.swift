//
//  Supabase.swift
//  lms
//
//  Created by Diptayan Jash on 19/04/25.
//

import Foundation
import Supabase
import OSLog

let supabase = SupabaseClient(
    supabaseURL: URL(string: SupabaseConfig.Supaurl)!,
    supabaseKey: SupabaseConfig.key,
        
  options: .init(
      global: .init(logger: AppLogger())
    )
)

struct AppLogger: SupabaseLogger {
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "supabase")

  func log(message: SupabaseLogMessage) {
    switch message.level {
    case .verbose:
      logger.log(level: .info, "\(message.description)")
    case .debug:
      logger.log(level: .debug, "\(message.description)")
    case .warning, .error:
      logger.log(level: .error, "\(message.description)")
    }
  }
}
