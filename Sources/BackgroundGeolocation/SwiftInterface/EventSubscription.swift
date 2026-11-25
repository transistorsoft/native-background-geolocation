//
//  EventSubscription.swift
//  TSLocationManager
//
//  Created by Christopher Scott on 2026-03-23.
//  Copyright © 2026 Transistor Software. All rights reserved.
//

import Foundation
import TSLocationManager

extension BGGeo {
    /// The handle an `on*` method returns for the listener it registered.
    ///
    /// The listener stays registered for as long as this object is alive: releasing it removes the
    /// listener. Keep it for as long as you want events, typically in a property of a long-lived object
    /// with ``store(in:)``, and call ``cancel()`` to remove the listener sooner.
    ///
    /// ```swift
    /// private var subscriptions = Set<BGGeo.EventSubscription>()
    ///
    /// bgGeo.onLocation { location in
    ///     print("[onLocation] \(location)")
    /// }.store(in: &subscriptions)
    /// ```
    public class EventSubscription: Hashable {
        private let lock = NSLock()
        private var cancelAction: (() -> Void)?

        init(cancel: @escaping () -> Void) {
            self.cancelAction = cancel
        }

        deinit {
            cancel()
        }

        /// Removes the listener. Calling it again, or releasing the subscription afterwards, does nothing
        /// more. (WO-199)
        public func cancel() {
            lock.lock()
            let action = cancelAction
            cancelAction = nil
            lock.unlock()
            action?()
        }

        public func store(in set: inout Set<EventSubscription>) {
            set.insert(self)
        }

        public static func == (lhs: EventSubscription, rhs: EventSubscription) -> Bool {
            lhs === rhs
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }
}
