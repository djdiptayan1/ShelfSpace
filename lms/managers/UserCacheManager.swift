import Foundation

// Wrapper class to make User struct compatible with NSCache
class UserWrapper {
    let user: User
    let timestamp: Date
    
    init(user: User) {
        self.user = user
        self.timestamp = Date()
    }
    
    var isExpired: Bool {
        // Cache expires after 1 hour
        return Date().timeIntervalSince(timestamp) > 3600
    }
}

class UserCacheManager {
    static let shared = UserCacheManager()
    private let cache = NSCache<NSString, UserWrapper>()
    private let cacheKey = "currentUser"
    private let userDefaults = UserDefaults.standard
    private let userKey = "cachedUser"
    private let libraryKey = "cachedLibrary"
    private let detailedUserKey = "cachedDetailedUser"
    private let otpKey = "cachedOTP"
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of users to cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limit
    }
    func cacheOtp(){
        let isVerified = true
        userDefaults.set(isVerified, forKey: otpKey)
    }
    func getCachedOtp() -> Bool? {
        return userDefaults.object(forKey: otpKey) as? Bool
    }
    
    func cacheUser(_ user: User) {
        print("Caching user data for: \(user.email)")
        // Store in memory cache
        let wrapper = UserWrapper(user: user)
        cache.setObject(wrapper, forKey: cacheKey as NSString)
        
        // Store in UserDefaults for persistence
        do {
            let encodedData = try JSONUtility.shared.encode(user)
            userDefaults.set(encodedData, forKey: userKey)
            print("User data cached successfully")
        } catch {
            print("Failed to encode user data for caching:")
            error.logDetails()
        }
    }
    
    func getCachedUser() -> User? {
        print("Attempting to get cached user data")
        
        // First try to get from memory cache
        if let cachedWrapper = cache.object(forKey: cacheKey as NSString) {
            if !cachedWrapper.isExpired {
                print("Found valid user in memory cache")
            return cachedWrapper.user
            } else {
                print("Cached user data expired, removing from cache")
                cache.removeObject(forKey: cacheKey as NSString)
            }
        }
        
        // If not in memory or expired, try to get from UserDefaults
        if let savedData = userDefaults.data(forKey: userKey) {
            do {
                let decodedUser = try JSONUtility.shared.decode(User.self, from: savedData)
            print("Found user in UserDefaults, caching in memory")
            // Store in memory cache for future use
            let wrapper = UserWrapper(user: decodedUser)
            cache.setObject(wrapper, forKey: cacheKey as NSString)
            return decodedUser
            } catch {
                print("Failed to decode user data from UserDefaults:")
                error.logDetails()
                // Remove corrupted data
                userDefaults.removeObject(forKey: userKey)
            }
        }
        
        print("No valid cached user data found")
        return nil
    }
    
    func clearCache() {
        print("Clearing user cache")
        cache.removeObject(forKey: cacheKey as NSString)
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: libraryKey)
        userDefaults.removeObject(forKey: detailedUserKey)
        userDefaults.removeObject(forKey: otpKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Additional Helper Methods
    
    func updateUser(_ updatedUser: User) {
        // Update both cache and UserDefaults
        cacheUser(updatedUser)
    }
    
    func isUserCached() -> Bool {
        return getCachedUser() != nil
    }
    
    func getCachedUserEmail() -> String? {
        return getCachedUser()?.email
    }
    
    func getCachedUserRole() -> UserRole? {
        return getCachedUser()?.role
    }
    
    func cacheLibrary(_ library: Library) {
        if let encoded = try? JSONEncoder().encode(library) {
            userDefaults.set(encoded, forKey: libraryKey)
            userDefaults.synchronize()
        }
    }
    
    func getCachedLibrary() -> Library? {
        guard let data = userDefaults.data(forKey: libraryKey),
              let library = try? JSONDecoder().decode(Library.self, from: data) else {
            return nil
        }
        return library
    }
    
    func cacheDetailedUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: detailedUserKey)
            userDefaults.synchronize()
        }
    }
    
    func getCachedDetailedUser() -> User? {
        guard let data = userDefaults.data(forKey: detailedUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
} 
