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
    public class EventSubscription: Hashable {
        private let cancel: () -> Void

        init(cancel: @escaping () -> Void) {
            self.cancel = cancel
        }

        deinit {
            cancel()
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
