package com.transistorsoft.tslocationmanager.demo.helpers

import android.content.Context
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory

/**
 * Loads recorded route data from test assets into [MockLocationHelper.LocationSpec] lists.
 *
 * Supports GPX files with `<trkpt>` elements containing `<ele>`, `<speed>`,
 * `<course>`, and `<hdop>` child elements.
 *
 * Usage:
 * ```
 * val route = RouteHelper.loadGpx(context, "pixel6_laurier_park_walk.gpx")
 * mock.pushLocations(route, intervalMs = 1000L)
 * ```
 */
object RouteHelper {

    /**
     * Load a GPX route file from androidTest assets.
     *
     * Parses `<trkpt>` elements from `<trkseg>` sections.
     *
     * @param context  Test context (use InstrumentationRegistry.getInstrumentation().context
     *                 for test APK assets, or .targetContext for app assets).
     * @param fileName Asset file name (e.g. "pixel6_laurier_park_walk.gpx").
     * @return List of [MockLocationHelper.LocationSpec] in file order (chronological).
     */
    fun loadGpx(context: Context, fileName: String): List<MockLocationHelper.LocationSpec> {
        val specs = mutableListOf<MockLocationHelper.LocationSpec>()
        val factory = XmlPullParserFactory.newInstance()
        val parser = factory.newPullParser()

        context.assets.open(fileName).bufferedReader().use { reader ->
            parser.setInput(reader)

            var lat = 0.0
            var lon = 0.0
            var ele = 0.0
            var speed = 0f
            var course = 0f
            var hdop = 5f
            var inTrkpt = false
            var currentTag = ""

            var eventType = parser.eventType
            while (eventType != XmlPullParser.END_DOCUMENT) {
                when (eventType) {
                    XmlPullParser.START_TAG -> {
                        currentTag = parser.name
                        if (currentTag == "trkpt") {
                            inTrkpt = true
                            lat = parser.getAttributeValue(null, "lat")?.toDoubleOrNull() ?: 0.0
                            lon = parser.getAttributeValue(null, "lon")?.toDoubleOrNull() ?: 0.0
                            ele = 0.0
                            speed = 0f
                            course = 0f
                            hdop = 5f
                        }
                    }
                    XmlPullParser.TEXT -> {
                        if (inTrkpt) {
                            val text = parser.text.trim()
                            if (text.isNotEmpty()) {
                                when (currentTag) {
                                    "ele" -> ele = text.toDoubleOrNull() ?: 0.0
                                    "speed" -> speed = text.toFloatOrNull() ?: 0f
                                    "course" -> course = text.toFloatOrNull() ?: 0f
                                    "hdop" -> hdop = text.toFloatOrNull() ?: 5f
                                }
                            }
                        }
                    }
                    XmlPullParser.END_TAG -> {
                        if (parser.name == "trkpt") {
                            specs.add(
                                MockLocationHelper.LocationSpec(
                                    latitude = lat,
                                    longitude = lon,
                                    accuracy = hdop,
                                    speed = speed,
                                    heading = course,
                                    altitude = ele
                                )
                            )
                            inTrkpt = false
                        }
                        currentTag = ""
                    }
                }
                eventType = parser.next()
            }
        }
        return specs
    }
}
