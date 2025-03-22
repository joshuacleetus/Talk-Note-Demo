//
//  GoogleSpeechModels.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation

struct GoogleSpeechResponse: Codable {
    let results: [GoogleSpeechResult]
    let totalBilledTime: String
    let requestId: String
}

struct GoogleSpeechResult: Codable {
    let alternatives: [GoogleSpeechAlternative]
    let resultEndTime: String
    let languageCode: String
}

struct GoogleSpeechAlternative: Codable {
    let transcript: String
    let confidence: Float?
    let words: [GoogleSpeechWordInfo]?
}

struct GoogleSpeechWordInfo: Codable {
    let startTime: String
    let endTime: String
    let word: String
}
