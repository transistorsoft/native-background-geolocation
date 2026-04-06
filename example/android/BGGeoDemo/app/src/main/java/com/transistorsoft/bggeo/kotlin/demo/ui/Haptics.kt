package com.transistorsoft.bggeo.kotlin.demo.ui

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View

/**
 * Simple iOS-style haptics wrapper.
 */
object Haptics {
    fun impactLight(view: View) =
        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)

    fun impactMedium(view: View) =
        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)

    fun impactHeavy(view: View) =
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)

    fun selectionChanged(view: View) =
        view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)

    fun success(context: Context) = vibrate(context, 30)
    fun warning(context: Context) = vibrate(context, 45)
    fun error(context: Context) = vibrate(context, 60)

    private fun vibrate(context: Context, ms: Long) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(ms)
        }
    }
}