//
//  Endpoints.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Endpoint {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    
    init(url: URL, method: HTTPMethod = .get, headers: [String: String] = [:], body: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

extension Endpoint {
    static func googleSpeechRecognition(apiKey: String, audioData: Data, sampleRate: Int = 22050) -> Endpoint {
        let url = URL(string: "https://speech.googleapis.com/v1p1beta1/speech:recognize?key=\(apiKey)")!
        
        // Base64 encode audio data
        let base64Audio = audioData.base64EncodedString()
        
        // Create request body with the provided sample rate
        let requestDict: [String: Any] = [
            "config": [
                "encoding": "LINEAR16",
                "sampleRateHertz": sampleRate,
                "languageCode": "en-US",
                "enableWordTimeOffsets": true,
                "enableAutomaticPunctuation": true,
                "model": "default"
            ],
            "audio": [
                "content": base64Audio
            ]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: requestDict)
        
        return Endpoint(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: jsonData
        )
    }
}
