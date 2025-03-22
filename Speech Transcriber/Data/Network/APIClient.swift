//
//  APIClient.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

class APIClient {
    private let session = URLSession.shared
    
    func request<T: Decodable>(endpoint: Endpoint) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIClient deallocated"]))
                return Disposables.create()
            }
            
            var request = URLRequest(url: endpoint.url)
            request.httpMethod = endpoint.method.rawValue
            
            for (key, value) in endpoint.headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            if let body = endpoint.body {
                request.httpBody = body
            }
            
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let data = data else {
                    observer.onError(NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(T.self, from: data)
                    observer.onNext(response)
                    observer.onCompleted()
                } catch {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    observer.onError(error)
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
