package com.transistorsoft.tslocationmanager.demo.helpers

import android.util.Log
import com.transistorsoft.locationmanager.adapter.BackgroundGeolocation
import com.transistorsoft.locationmanager.adapter.callback.TSGeofenceCallback
import com.transistorsoft.locationmanager.adapter.callback.TSLocationCallback
import com.transistorsoft.locationmanager.adapter.callback.TSLocationProviderChangeCallback
import com.transistorsoft.locationmanager.event.GeofenceEvent
import com.transistorsoft.locationmanager.event.LocationEvent
import com.transistorsoft.locationmanager.event.LocationProviderChangeEvent
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Generic latch-based event collector for BackgroundGeolocation SDK events.
 *
 * Attaches to an SDK event, collects emitted events, and provides synchronous
 * waiting with timeout. Auto-closes the subscription on [close].
 *
 * Usage:
 * ```
 * val awaiter = EventAwaiter.location(bgGeo, expectedCount = 3)
 * // ... trigger location updates ...
 * val events = awaiter.await(timeoutSeconds = 10)
 * assertEquals(3, events.size)
 * awaiter.close()   // or use .use { } block
 * ```
 */
class EventAwaiter<T> private constructor(
    private val subscription: AutoCloseable,
    private val latch: CountDownLatch,
    private val collected: CopyOnWriteArrayList<T>
) : AutoCloseable {

    companion object {
        private const val TAG = "EventAwaiter"

        /**
         * Listen for location events.
         * @param expectedCount Number of events to wait for (default 1).
         */
        fun location(
            bgGeo: BackgroundGeolocation,
            expectedCount: Int = 1
        ): EventAwaiter<LocationEvent> {
            val collected = CopyOnWriteArrayList<LocationEvent>()
            val latch = CountDownLatch(expectedCount)

            val sub = bgGeo.onLocation(object : TSLocationCallback {
                override fun onLocation(event: LocationEvent) {
                    Log.i(TAG, "[location] received: $event")
                    collected.add(event)
                    latch.countDown()
                }
                override fun onError(code: Int?) {
                    Log.w(TAG, "[location] error: $code")
                }
            })

            return EventAwaiter(sub, latch, collected)
        }

        /**
         * Listen for motionchange events.
         */
        fun motionChange(
            bgGeo: BackgroundGeolocation,
            expectedCount: Int = 1
        ): EventAwaiter<LocationEvent> {
            val collected = CopyOnWriteArrayList<LocationEvent>()
            val latch = CountDownLatch(expectedCount)

            val sub = bgGeo.onMotionChange(object : TSLocationCallback {
                override fun onLocation(event: LocationEvent) {
                    Log.i(TAG, "[motionchange] received: $event")
                    collected.add(event)
                    latch.countDown()
                }
                override fun onError(code: Int?) {
                    Log.w(TAG, "[motionchange] error: $code")
                }
            })

            return EventAwaiter(sub, latch, collected)
        }

        /**
         * Listen for geofence events.
         */
        fun geofence(
            bgGeo: BackgroundGeolocation,
            expectedCount: Int = 1
        ): EventAwaiter<GeofenceEvent> {
            val collected = CopyOnWriteArrayList<GeofenceEvent>()
            val latch = CountDownLatch(expectedCount)

            val sub = bgGeo.onGeofence(TSGeofenceCallback { event ->
                Log.i(TAG, "[geofence] received: action=${event.action}")
                collected.add(event)
                latch.countDown()
            })

            return EventAwaiter(sub, latch, collected)
        }

        /**
         * Listen for provider change events (permission/GPS state changes).
         */
        fun providerChange(
            bgGeo: BackgroundGeolocation,
            expectedCount: Int = 1
        ): EventAwaiter<LocationProviderChangeEvent> {
            val collected = CopyOnWriteArrayList<LocationProviderChangeEvent>()
            val latch = CountDownLatch(expectedCount)

            val sub = bgGeo.onLocationProviderChange(TSLocationProviderChangeCallback { event ->
                Log.i(TAG, "[providerchange] received: status=${event.status}")
                collected.add(event)
                latch.countDown()
            })

            return EventAwaiter(sub, latch, collected)
        }
    }

    /**
     * Block until the expected number of events have been collected, or timeout.
     *
     * @param timeoutSeconds Max time to wait.
     * @return List of collected events (may be fewer than expected if timeout hit).
     */
    fun await(timeoutSeconds: Long = 10L): List<T> {
        latch.await(timeoutSeconds, TimeUnit.SECONDS)
        return collected.toList()
    }

    /**
     * Block and assert that the expected count was reached.
     *
     * @throws AssertionError if timeout is reached before all events arrive.
     */
    fun awaitOrFail(timeoutSeconds: Long = 10L, message: String = "Event awaiter timed out"): List<T> {
        val reached = latch.await(timeoutSeconds, TimeUnit.SECONDS)
        if (!reached) {
            throw AssertionError("$message — received ${collected.size} events, expected ${latch.count + collected.size}")
        }
        return collected.toList()
    }

    /**
     * Return events collected so far without waiting.
     */
    val events: List<T>
        get() = collected.toList()

    /**
     * Unsubscribe from the SDK event.
     */
    override fun close() {
        try {
            subscription.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing subscription: ${e.message}")
        }
    }
}
