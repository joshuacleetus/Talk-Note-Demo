//
//  GoogleSpeechService.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

class GoogleSpeechService {
    private let apiKey: String
    private let apiClient: APIClient
    
    init(apiKey: String, apiClient: APIClient) {
        self.apiKey = apiKey
        self.apiClient = apiClient
    }
    
    func recognizeSpeech(audioData: Data, sampleRate: Int = 44100) -> Observable<GoogleSpeechResponse> {
        let endpoint = Endpoint.googleSpeechRecognition(apiKey: apiKey, audioData: audioData, sampleRate: sampleRate)
        return apiClient.request(endpoint: endpoint)
    }
    
    func parseTimeString(_ timeString: String) -> TimeInterval {
        let trimmed = timeString.replacingOccurrences(of: "s", with: "")
        return TimeInterval(trimmed) ?? 0.0
    }
}
