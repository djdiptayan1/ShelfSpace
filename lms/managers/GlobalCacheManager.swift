//
//  GlobalCacheManager.swift
//  lms
//
//  Created by dark on 07/05/25.
//

import Foundation
struct CacheWrapper<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 3600
    }
}
class CacheHandler<T: Codable> {
    private let cacheFileName: String
    
    init(cacheFileName: String) {
        self.cacheFileName = cacheFileName
    }
    private var cacheFileURL: URL {
        let documentDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentDir.appendingPathComponent(cacheFileName)
    }
    
    func cacheData(_ data: T) {
        let wrapper = CacheWrapper<T>(data: data, timestamp: Date())
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: cacheFileURL)
        } catch {
            print("Error saving books to cache: \(error)")
        }
    }
    func getCachedData() -> T?{
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let wrapper = try JSONDecoder().decode(CacheWrapper<T>.self, from: data)
            return wrapper.isExpired ? nil : wrapper.data
        } catch {
            print("Error loading books from cache: \(error)")
            return nil
        }
    }
}
