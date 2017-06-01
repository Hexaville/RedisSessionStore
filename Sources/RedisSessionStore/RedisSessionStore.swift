import Foundation
import HexavilleFramework
import SwiftRedis

public enum Result<T> {
    case success(T)
    case failure(Error)
}

func reportError(command: String, error: Error) {
    print("[RedisSessionStoreError] command: \(command), error: \(error)")
}

public struct RedisSessionStore: SessionStoreProvider {
    
    let redis = Redis()
    
    let host: String
    
    let port: Int32
    
    public init(host: String = "localhsot", port: Int32 = 6379) {
        self.host = host
        self.port = port
    }
    
    public func connectIfNeeded(handler: @escaping (Result<Redis>) -> Void) {
        if redis.connected {
            return handler(.success(redis))
        }
        
        redis.connect(host: host, port: port) { error in
            if let error = error {
                return handler(.failure(error))
            }
            
            handler(.success(self.redis))
        }
    }

    // TODO : implement here
    public func flush() throws {
        
    }
    
    public func read(forKey: String) throws -> [String : Any]? {
        let channel = Channel<(Error?, Data?)>.make(capacity: 1)
        connectIfNeeded { result in
            switch result {
            case .success(let redis):
                redis.get(forKey) { str, error in
                    if let error = error {
                        return try! channel.send((error, nil))
                    }
                    try! channel.send((nil, str?.asData))
                }
                
            case .failure(let error):
                try! channel.send((error, nil))
            }
        }
        
        let (error, data) = try channel.receive()
        if let e = error {
            throw e
        }
        if let d = data {
            return try JSONSerialization.jsonObject(with: d, options: []) as? [String: Any]
        }
        return nil
    }
    
    public func write(value: [String : Any], forKey: String, ttl: Int?) throws {
        connectIfNeeded { result in
            switch result {
            case .success(let redis):
                do {
                    var expiresIn: TimeInterval?
                    if let ttl = ttl {
                        expiresIn = TimeInterval(ttl)
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                    let str = RedisString(jsonData)
                    
                    redis.set(forKey, value: str, exists: nil, expiresIn: expiresIn) { bool, error in
                        if let error = error {
                            reportError(command: "SETEX", error: error)
                        }
                    }
                } catch {
                    reportError(command: "SETEX", error: error)
                }
                
            case .failure(let error):
                reportError(command: "CON", error: error)
            }
        }
    }
    
    public func delete(forKey: String) throws {
        connectIfNeeded { result in
            switch result {
            case .success(let redis):
                redis.del(forKey) { int, error in
                    if let error = error {
                        reportError(command: "SETEX", error: error)
                    }
                }
                
            case .failure(let error):
                reportError(command: "CON", error: error)
            }
        }
    }
    
}
