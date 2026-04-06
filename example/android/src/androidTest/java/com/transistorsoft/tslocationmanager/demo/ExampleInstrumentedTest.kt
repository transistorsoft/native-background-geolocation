package com.transistorsoft.tslocationmanager.demo

import android.Manifest
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.rule.GrantPermissionRule
import com.transistorsoft.tslocationmanager.demo.helpers.EventAwaiter
import com.transistorsoft.tslocationmanager.demo.helpers.MockLocationHelper
import com.transistorsoft.tslocationmanager.demo.helpers.RouteHelper
import com.transistorsoft.tslocationmanager.demo.helpers.SDKTestHelper

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {

    @get:Rule
    val permissionRule: GrantPermissionRule = GrantPermissionRule.grant(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.ACCESS_BACKGROUND_LOCATION
    )

    private lateinit var sdk: SDKTestHelper
    private lateinit var mock: MockLocationHelper

    @Before
    fun setUp() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        sdk = SDKTestHelper(context)
        // Use LOCATION_MANAGER mode — injects via LocationManager test providers,
        // which feed into FLP from below. Works reliably on API 16+ emulators.
        mock = MockLocationHelper(context, MockLocationHelper.MockMode.LOCATION_MANAGER)
    }

    @After
    fun tearDown() {
        mock.disable()
        sdk.tearDown()
    }

    @Test
    fun sanityCheck_appContext() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.transistorsoft.tslocationmanager.demo", context.packageName)
    }

    @Test
    fun ready_succeeds() {
        sdk.ready()
    }

    @Test
    fun getCurrentPosition_returnsLocation() {
        sdk.ready()
        val event = sdk.getCurrentPosition()
        assertNotNull("Should receive a location", event)
    }

    @Test
    fun mockLocation_deliveredToSDK() {
        sdk.ready()
        mock.enable()

        // Push a known location via LocationManager test providers.
        mock.pushLocation(37.422, -122.084, accuracy = 10f)
        Thread.sleep(500)

        // getCurrentPosition should pick up the mock location.
        val event = sdk.getCurrentPosition(maximumAge = 5_000L, samples = 1, timeout = 10)
        assertNotNull("Should receive mock location", event)
    }

    @Test
    fun tracking_onLocation_receivesMockLocations() {
        // Configure before ready(): small distance filter, no elasticity.
        sdk.config.edit().apply {
            geo().setDistanceFilter(10f)
            geo().setElasticityMultiplier(0f)
        }.commit()

        sdk.ready()
        sdk.start()
        mock.enable()

        // Load real walking data recorded on Pixel 6 (~6km Laurier Park loop, Montreal).
        val testContext = InstrumentationRegistry.getInstrumentation().context
        val route = RouteHelper.loadGpx(testContext, "pixel6_laurier_park_walk.gpx")

        // Subscribe to onLocation BEFORE changePace so we don't miss the first event.
        EventAwaiter.location(sdk.bgGeo, expectedCount = 3).use { awaiter ->
            sdk.changePace(true)
            mock.pushLocations(route, intervalMs = 200L)

            val events = awaiter.await(timeoutSeconds = 30)
            assertTrue(
                "Expected at least 3 onLocation events, got ${events.size}",
                events.size >= 3
            )
        }
    }
}
