//
//  IAudioRepository.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import AVFoundation

protocol IAudioRepository {
    func startRecording() -> Observable<Bool>
    func stopRecording() -> Observable<URL>
    func getRecordingData() -> Observable<Data>
    func startPlayback() -> Observable<Bool>
    func stopPlayback()
    func getCurrentPlaybackTime() -> TimeInterval
    func isPlaying() -> Bool
    func setPlaybackDelegate(_ delegate: AVAudioPlayerDelegate)
    func verifyRecordingPlayable() -> Observable<String>
    func getCurrentRecordingURL() -> URL?
}
