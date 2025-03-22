//
//  PlaybackAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import AVFoundation

class PlaybackAudioUseCase: IPlaybackAudioUseCase {
    private let audioRepository: IAudioRepository
    
    init(audioRepository: IAudioRepository) {
        self.audioRepository = audioRepository
    }
    
    func execute() -> Observable<Bool> {
        return audioRepository.startPlayback()
    }
    
    func stop() {
        audioRepository.stopPlayback()
    }
    
    func getCurrentTime() -> TimeInterval {
        return audioRepository.getCurrentPlaybackTime()
    }
    
    func isPlaying() -> Bool {
        return audioRepository.isPlaying()
    }
    
    func setDelegate(_ delegate: AVAudioPlayerDelegate) {
        audioRepository.setPlaybackDelegate(delegate)
    }
    
    func verifyRecordingPlayable() -> Observable<String> {
        return audioRepository.verifyRecordingPlayable()
    }
}
