//
//  AudioRepository.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import AVFoundation

class AudioRepository: IAudioRepository {
    private let audioService: AudioService
    
    init(audioService: AudioService) {
        self.audioService = audioService
    }
    
    func startRecording() -> Observable<Bool> {
        return audioService.startRecording()
    }
    
    func stopRecording() -> Observable<URL> {
        return audioService.stopRecording()
    }
    
    func getRecordingData() -> Observable<Data> {
        return audioService.getRecordingData()
    }
    
    func startPlayback() -> Observable<Bool> {
        return audioService.startPlayback()
    }
    
    func stopPlayback() {
        audioService.stopPlayback()
    }
    
    func getCurrentPlaybackTime() -> TimeInterval {
        return audioService.getCurrentPlaybackTime()
    }
    
    func isPlaying() -> Bool {
        return audioService.isPlaying()
    }
    
    func setPlaybackDelegate(_ delegate: AVAudioPlayerDelegate) {
        audioService.setPlaybackDelegate(delegate)
    }
    
    func verifyRecordingPlayable() -> Observable<String> {
        return audioService.verifyRecordingPlayable()
    }
    
    func getCurrentRecordingURL() -> URL? {
        return audioService.getCurrentRecordingURL()
    }
}
