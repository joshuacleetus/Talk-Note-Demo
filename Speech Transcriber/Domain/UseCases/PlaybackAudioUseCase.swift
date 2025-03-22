//
//  PlaybackAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import AVFoundation

// In PlaybackAudioUseCase.swift
class PlaybackAudioUseCase: IPlaybackAudioUseCase {
    private let audioRepository: IAudioRepository
    private let disposeBag = DisposeBag()
    private var timeTrackingTimer: Timer?
    
    // Add this subject to track current playback time
    private let currentTimeSubject = PublishSubject<TimeInterval>()
    var currentTimeObservable: Observable<TimeInterval> {
        return currentTimeSubject.asObservable()
    }
    
    init(audioRepository: IAudioRepository) {
        self.audioRepository = audioRepository
    }
    
    func execute() -> Observable<Bool> {
        return audioRepository.startPlayback()
            .do(onNext: { [weak self] success in
                if success {
                    // Start tracking time when playback begins
                    self?.startTimeTracking()
                }
            })
    }
    
    func stop() {
        audioRepository.stopPlayback()
        stopTimeTracking()
    }
    
    func setDelegate(_ delegate: AVAudioPlayerDelegate) {
        audioRepository.setPlaybackDelegate(delegate)
    }
    
    func isPlaying() -> Bool {
        return audioRepository.isPlaying()
    }
    
    func getCurrentTime() -> TimeInterval {
        return audioRepository.getCurrentPlaybackTime()
    }
    
    // Add this method to start the time tracking
    private func startTimeTracking() {
        // Cancel any existing timer first
        stopTimeTracking()
        
        // Create a new timer
        timeTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying() else { return }
            let currentTime = self.getCurrentTime()
            self.currentTimeSubject.onNext(currentTime)
        }
    }
    
    // Add this method to stop time tracking
    private func stopTimeTracking() {
        timeTrackingTimer?.invalidate()
        timeTrackingTimer = nil
    }
}
