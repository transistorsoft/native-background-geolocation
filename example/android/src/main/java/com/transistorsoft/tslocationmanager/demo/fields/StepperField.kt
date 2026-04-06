package com.transistorsoft.tslocationmanager.demo.fields

import android.content.Context
import android.util.AttributeSet
import android.view.Gravity
import android.view.LayoutInflater
import android.widget.ImageButton
import android.widget.LinearLayout
import com.google.android.material.textview.MaterialTextView
import com.transistorsoft.tslocationmanager.demo.R

class StepperField @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0
) : LinearLayout(context, attrs, defStyle) {

    private val labelView: MaterialTextView
    private val minus: ImageButton
    private val plus: ImageButton

    var label: String = ""
        set(v) { field = v; labelView.text = displayText() }

    var unit: String = "m"
        set(v) { field = v; labelView.text = displayText() }

    var min = 0f
    var max = 1000f
    var step = 5f

    var value = 50f
        set(v) {
            field = v.coerceIn(min, max)
            labelView.text = displayText()
            onValueChanged?.invoke(field)
        }

    var onValueChanged: ((Float) -> Unit)? = null

    /** Programmatically set value without invoking onValueChanged */
    fun setValueSilently(v: Float) {
        val cb = onValueChanged
        onValueChanged = null
        value = v
        onValueChanged = cb
    }

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        LayoutInflater.from(context).inflate(R.layout.stepper_field, this, true)
        labelView = findViewById(R.id.label)
        minus = findViewById(R.id.btnMinus)
        plus = findViewById(R.id.btnPlus)

        if (attrs != null) {
            val a = context.obtainStyledAttributes(attrs, R.styleable.StepperField)
            label = a.getString(R.styleable.StepperField_sr_label) ?: label
            unit = a.getString(R.styleable.StepperField_sr_unit) ?: unit
            min = a.getFloat(R.styleable.StepperField_sr_min, min)
            max = a.getFloat(R.styleable.StepperField_sr_max, max)
            step = a.getFloat(R.styleable.StepperField_sr_step, step)
            value = a.getFloat(R.styleable.StepperField_sr_value, value)
            a.recycle()
        }

        minus.setOnClickListener { value -= step }
        plus.setOnClickListener { value += step }
    }

    private fun displayText() = "$label: ${value.toInt()} $unit"
}