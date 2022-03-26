//
//  WebAPI.swift
//
//  Created by LFT on 2022/3/7.
//

import Foundation

class WebAPI {
    private static let resolver = DataResolver()

    // struct Result: Decodable, Encodable {
    //    let id: Int
    //    let userId: String
    //    let title: String
    //    let completed: String
    
    // }


    ///
    ///   parse a file from your disk
    /// - Parameters:
    ///   - type: the type you want to convert to [Note] XML Only support NativeXmlObject.self
    ///   - path: File path
    ///   - whenNotNull: When file found and can parse
    ///   - whenNull: When file not found or can not parse
    public static func local<T: Decodable>(_ type: T.Type, _ path: String, _ whenNotNull: @escaping (T) -> Void, _ whenNull: @escaping () -> Void) {
        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            let info = resolver.resolve(data, T.self)
            if let data = info {
                whenNotNull(data)
                return;
            }
        } catch {
        }
        whenNull()
    }

    ///
    /// var dic = ["userId":"300","title":"My urgent task","completed": "false"]
    /// WebAPI.post(Result.self, "https://jsonplaceholder.typicode.com/todos", dic) { result in
    ///     print(result)
    /// }
    /// - Parameters:
    ///   - type: the type you want to convert to [Note] XML Only support NativeXmlObject.self
    ///   - urlString: http network address like http://www.baidu.com
    ///   - params: the params store in a dictionary
    ///   - callback: called on web request successfully get data from network
    public static func post<T: Decodable>(_ type: T.Type, _ urlString: String, _ params: [String:String], _ whenNotNull: @escaping (T) -> Void, _ whenNull: @escaping () -> Void ) {
        var query = ""
        for (key, value) in params {
            query += "\(key)=\(value)&"
        }
        query.removeLast()
        let callback: (T?) -> Void  = {data in
            if let unwarp = data {
                whenNotNull(unwarp)
            } else {
                whenNull();
            }
        }
        post(type, urlString, query, callback)
    }

    ///
    /// var dic = ["userId":"300","title":"My urgent task","completed": "false"]
    /// WebAPI.post(Result.self, "https://jsonplaceholder.typicode.com/todos", dic) { result in
    ///     print(result)
    /// }
    /// - Parameters:
    ///   - type: the type you want to convert to
    ///   - urlString: http network address like http://www.baidu.com
    ///   - params: the params store in a dictionary
    ///   - callback: called on web request successfully get data from network
    public static func post<T: Decodable>(_ type: T.Type, _ urlString: String, _ params: [String:String], _ callback: @escaping (T?) -> Void) {
        var query = ""
        for (key, value) in params {
            query += "\(key)=\(value)&"
        }
        query.removeLast()
        post(type, urlString, query, callback)
    }

    ///
    /// Send a get request for a http network address
    /// WebAPI.post(Result.self, "https://jsonplaceholder.typicode.com/todos", "userId=300&title=My urgent task&completed=false") { result in
    ///     print(result)
    /// }
    /// - Parameters:
    ///   - type: the type you want to convert to
    ///   - urlString: http network address like http://www.baidu.com
    ///   - params: quest param like id=1&name=LFT
    ///   - callback: called on web request successfully get data from network
    public static func post<T: Decodable>(_ type: T.Type, _ urlString: String, _ params: String, _ callback: @escaping (T?) -> Void) {
        // Prepare URL
        let url = URL(string: urlString)
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"

        // HTTP Request Parameters which will be sent in HTTP Request Body
        // Set HTTP Request Body
        request.httpBody = params.data(using: String.Encoding.utf8);
            // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Errorƒ
            if let error = error {
                print("Error took place \(error)")
                return
            }

            // Convert HTTP Response Data to a String
            if let data = data {
                let info = resolver.resolve(data, T.self)
                callback(info)
            }
        }
        task.resume()
    }
}
