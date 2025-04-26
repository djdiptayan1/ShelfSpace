import Foundation

// Wrapper class to make User struct compatible with NSCache
class UserWrapper {
    let user: User
    
    init(user: User) {
        self.user = user
    }
}

class UserCacheManager {
    static let shared = UserCacheManager()
    private let cache = NSCache<NSString, UserWrapper>()
    private let cacheKey = "currentUser"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of users to cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limit
    }
    
    func cacheUser(_ user: User) {
        print("Caching user data for: \(user.email)")
        // Store in memory cache
        let wrapper = UserWrapper(user: user)
        cache.setObject(wrapper, forKey: cacheKey as NSString)
        
        // Store in UserDefaults for persistence
        if let encodedData = try? JSONEncoder().encode(user) {
            userDefaults.set(encodedData, forKey: cacheKey)
            print("User data cached successfully")
        } else {
            print("Failed to encode user data for caching")
        }
    }
    
    func getCachedUser() -> User? {
        print("Attempting to get cached user data")
        // First try to get from memory cache
        if let cachedWrapper = cache.object(forKey: cacheKey as NSString) {
            print("Found user in memory cache")
            return cachedWrapper.user
        }
        
        // If not in memory, try to get from UserDefaults
        if let savedData = userDefaults.data(forKey: cacheKey),
           let decodedUser = try? JSONDecoder().decode(User.self, from: savedData) {
            print("Found user in UserDefaults, caching in memory")
            // Store in memory cache for future use
            let wrapper = UserWrapper(user: decodedUser)
            cache.setObject(wrapper, forKey: cacheKey as NSString)
            return decodedUser
        }
        
        print("No cached user data found")
        return nil
    }
    
    func clearCache() {
        print("Clearing user cache")
        cache.removeObject(forKey: cacheKey as NSString)
        userDefaults.removeObject(forKey: cacheKey)
    }
} 