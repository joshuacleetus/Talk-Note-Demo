//
//  AppResults.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/22/25.
//

import Foundation

enum AppResult<T> {
    case success(T)
    case failure(AppError)
}

enum AppError: Error {
    case audioRecordingFailed(String)
    case transcriptionFailed(String)
    case playbackFailed(String)
    case timeout(String)
    
    var userMessage: String {
        switch self {
        case .audioRecordingFailed(let message): return "Recording failed: \(message)"
        case .transcriptionFailed(let message): return "Transcription failed: \(message)"
        case .playbackFailed(let message): return "Playback failed: \(message)"
        case .timeout(let message): return message
        }
    }
}
