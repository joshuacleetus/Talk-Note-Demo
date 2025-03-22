//
//  Observable+Extensions.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/22/25.
//

import RxSwift
import SwiftUI

extension Observable {
    func timeout(_ seconds: RxTimeInterval, message: String, scheduler: SchedulerType) -> Observable<Element> {
        return self.timeout(seconds, scheduler: scheduler)
            .catch { error -> Observable<Element> in
                if error is RxError {
                    return Observable.error(NSError(domain: "TimeoutError", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: message]))
                }
                return Observable.error(error)
            }
    }
}
