//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptiTrack {

    private struct Constants {
        static let eventBatchLimit = 50
        static let queueLabel = "com.optimove.track"
    }

    var dispatchInterval: TimeInterval = 10 {
        didSet {
            startDispatchTimer()
        }
    }

    private let queue: OptistreamQueue
    private let networking: OptistreamNetworking
    private let configuration: OptitrackConfig
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var dispatchTimer: Timer?
    private let dispatchQueue = DispatchQueue(label: Constants.queueLabel, qos: .default, attributes: .concurrent)

    private var isDispatching: Bool {
        get {
            var name = false
            dispatchQueue.sync {
                name = private_isDispatching
            }
            return name
        }
        set {
            dispatchQueue.async(flags: .barrier) {
                self.private_isDispatching = newValue
            }
        }
    }
    private var private_isDispatching = false

    init(
        queue: OptistreamQueue,
        networking: OptistreamNetworking,
        configuration: OptitrackConfig
    ) {
        self.queue = queue
        self.networking = networking
        self.configuration = configuration
        startDispatchTimer()
    }

    private func startBackgroundTask() {
        stopBackgroundTask()
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Dispatch now") {
            self.stopBackgroundTask()
        }
    }

    private func stopBackgroundTask() {
        guard self.backgroundTaskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
        self.backgroundTaskId = .invalid
    }
}

extension OptiTrack: OptistreamComponent {

    func handle(_ operation: OptistreamOperation) throws {
        switch operation {
        case let .report(events: events):
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let events = events.map(self.applyRealtimeMutation)
                self.queue.enqueue(events: events)
                if events.map(self.shouldDispatchNow).contains(true) {
                    self.dispatch()
                }
            }
        case .dispatchNow:
            self.startBackgroundTask()
            self.dispatch()
        }
    }

}

private extension OptiTrack {

    func startDispatchTimer() {
        guard dispatchInterval > 0  else { return }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
        }
        dispatchTimer = Timer(
            timeInterval: self.dispatchInterval,
            target: self,
            selector: #selector(dispatch),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(dispatchTimer!, forMode: RunLoop.Mode.common)
    }

    func applyRealtimeMutation(_ event: OptistreamEvent) -> OptistreamEvent {
        var event = event
        event.metadata.realtime = event.metadata.realtime && configuration.isEnableRealtime
        return event
    }

    func shouldDispatchNow(_ event: OptistreamEvent) -> Bool {
        return event.metadata.realtime
    }

    @objc func dispatch() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            guard !self.isDispatching else {
                self.stopBackgroundTask()
                Logger.debug("Tracker is already dispatching.")
                return
            }
            guard !self.queue.isEmpty else {
                Logger.debug("No need to dispatch. Dispatch queue is empty.")
                self.startDispatchTimer()
                self.stopBackgroundTask()
                return
            }
            Logger.info("Start dispatching events")
            self.isDispatching = true
            self.dispatchBatch()
        }
    }

    func dispatchBatch() {
        let events = queue.first(limit: Constants.eventBatchLimit)
        guard !events.isEmpty else {
            self.isDispatching = false
            self.startDispatchTimer()
            stopBackgroundTask()
            Logger.debug("Finished dispatching events")
            return
        }
        networking.send(events: events) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                self.queue.remove(events: events)
                self.dispatchBatch()
            case .failure(let error):
                Logger.error(error.localizedDescription)
                switch error {
                case .requestInvalid:
                    self.queue.remove(events: events)
                default:
                    break
                }
                self.isDispatching = false
            }
        }
    }

}
