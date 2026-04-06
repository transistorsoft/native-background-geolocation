package com.transistorsoft.tslocationmanager.demo.helpers

import android.content.Context
import android.util.Log
import com.transistorsoft.locationmanager.adapter.BackgroundGeolocation
import com.transistorsoft.locationmanager.adapter.callback.TSCallback
import com.transistorsoft.locationmanager.adapter.callback.TSLocationCallback
import com.transistorsoft.locationmanager.config.TSConfig
import com.transistorsoft.locationmanager.event.LocationEvent
import com.transistorsoft.locationmanager.lifecycle.LifecycleManager
import com.transistorsoft.locationmanager.location.TSCurrentPositionRequest
import org.junit.Assert.assertTrue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Manages BackgroundGeolocation SDK lifecycle for instrumented tests.
 *
 * Handles ready/start/stop with synchronous latch-based waiting so tests
 * don't need to manage async callbacks directly.
 *
 * Usage:
 * ```
 * val sdk = SDKTestHelper(context)
 * sdk.ready()                       // blocks until ready
 * sdk.start()                       // blocks until started
 * val event = sdk.getCurrentPosition()
 * sdk.stop()
 * sdk.tearDown()                    // call in @After
 * ```
 */
class SDKTestHelper(private val context: Context) {

    companion object {
        private const val TAG = "SDKTestHelper"
        private const val DEFAULT_TIMEOUT_S = 10L
    }

    val bgGeo: BackgroundGeolocation = BackgroundGeolocation.getInstance(context)
    val config: TSConfig = TSConfig.getInstance(context)

    init {
        // Tell the SDK we're a foreground client — instrumented tests have no Activity,
        // so LifecycleManager defaults to headless mode. Without this, EventManager
        // won't deliver events (onLocation, onGeofence, etc.) to client listeners.
        LifecycleManager.getInstance(context).setHeadless(false)

        config.reset()
        config.edit().apply {
            logger().setDebug(true)
            logger().setLogLevel(5)
            app().setStopOnTerminate(false)
            persistence().setMaxRecordsToPersist(0)
        }.commit()
    }

    /**
     * Calls ready() and blocks until complete.
     * @throws AssertionError if ready doesn't complete within [timeoutSeconds].
     */
    fun ready(timeoutSeconds: Long = DEFAULT_TIMEOUT_S) {
        val latch = CountDownLatch(1)
        var error: String? = null

        bgGeo.ready(object : TSCallback {
            override fun onSuccess() {
                Log.i(TAG, "ready onSuccess")
                latch.countDown()
            }
            override fun onFailure(err: String?) {
                Log.e(TAG, "ready onFailure: $err")
                error = err
                latch.countDown()
            }
        })

        assertTrue("ready() timed out after ${timeoutSeconds}s", latch.await(timeoutSeconds, TimeUnit.SECONDS))
        if (error != null) {
            throw AssertionError("ready() failed: $error")
        }
    }

    /**
     * Calls start() and blocks until complete.
     */
    fun start(timeoutSeconds: Long = DEFAULT_TIMEOUT_S) {
        val latch = CountDownLatch(1)
        var error: String? = null

        bgGeo.start(object : TSCallback {
            override fun onSuccess() {
                Log.i(TAG, "start onSuccess")
                latch.countDown()
            }
            override fun onFailure(err: String?) {
                Log.e(TAG, "start onFailure: $err")
                error = err
                latch.countDown()
            }
        })

        assertTrue("start() timed out after ${timeoutSeconds}s", latch.await(timeoutSeconds, TimeUnit.SECONDS))
        if (error != null) {
            throw AssertionError("start() failed: $error")
        }
    }

    /**
     * Calls stop() and blocks until complete.
     */
    fun stop(timeoutSeconds: Long = DEFAULT_TIMEOUT_S) {
        val latch = CountDownLatch(1)

        bgGeo.stop(object : TSCallback {
            override fun onSuccess() {
                Log.i(TAG, "stop onSuccess")
                latch.countDown()
            }
            override fun onFailure(err: String?) {
                Log.e(TAG, "stop onFailure: $err")
                latch.countDown()
            }
        })

        latch.await(timeoutSeconds, TimeUnit.SECONDS)
    }

    /**
     * Synchronous getCurrentPosition. Returns the LocationEvent or null on error/timeout.
     */
    fun getCurrentPosition(
        desiredAccuracy: Double = 0.0,
        maximumAge: Long = 60_000L,
        samples: Int = 1,
        timeout: Int = 30,
        persist: Boolean = false,
        timeoutSeconds: Long = timeout.toLong() + 5
    ): LocationEvent? {
        val latch = CountDownLatch(1)
        var result: LocationEvent? = null

        val request = TSCurrentPositionRequest.Builder(context)
            .setTimeout(timeout)
            .setMaximumAge(maximumAge)
            .setDesiredAccuracy(desiredAccuracy)
            .setSamples(samples)
            .setPersist(persist)
            .setCallback(object : TSLocationCallback {
                override fun onLocation(event: LocationEvent) {
                    Log.i(TAG, "getCurrentPosition success: $event")
                    result = event
                    latch.countDown()
                }
                override fun onError(code: Int?) {
                    Log.e(TAG, "getCurrentPosition error: $code")
                    latch.countDown()
                }
            }).build()

        bgGeo.getCurrentPosition(request)

        assertTrue(
            "getCurrentPosition timed out after ${timeoutSeconds}s",
            latch.await(timeoutSeconds, TimeUnit.SECONDS)
        )
        return result
    }

    /**
     * Calls changePace() and blocks until complete.
     */
    fun changePace(isMoving: Boolean, timeoutSeconds: Long = DEFAULT_TIMEOUT_S) {
        val latch = CountDownLatch(1)
        var error: String? = null

        bgGeo.changePace(isMoving, object : TSCallback {
            override fun onSuccess() {
                Log.i(TAG, "changePace($isMoving) onSuccess")
                latch.countDown()
            }
            override fun onFailure(err: String?) {
                Log.e(TAG, "changePace($isMoving) onFailure: $err")
                error = err
                latch.countDown()
            }
        })

        assertTrue("changePace() timed out after ${timeoutSeconds}s", latch.await(timeoutSeconds, TimeUnit.SECONDS))
        if (error != null) {
            throw AssertionError("changePace() failed: $error")
        }
    }

    /**
     * Clean up SDK state. Call in @After.
     */
    fun tearDown() {
        bgGeo.stop()
        bgGeo.removeGeofences()
        bgGeo.destroyLocations()
    }
}
