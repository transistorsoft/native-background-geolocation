package com.transistorsoft.bggeo.kotlin.demo.ui.settings

import android.app.Dialog
import android.content.DialogInterface
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.PopupMenu
import androidx.core.widget.doAfterTextChanged
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.location.Priority
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputLayout
import com.google.android.material.textfield.TextInputEditText
import android.widget.LinearLayout
import android.widget.FrameLayout
import android.content.Context
import android.widget.Toast
import com.transistorsoft.locationmanager.kotlin.config.AuthorizationStrategy
import com.transistorsoft.locationmanager.kotlin.config.Config
import com.transistorsoft.locationmanager.kotlin.config.DesiredAccuracy
import com.transistorsoft.locationmanager.kotlin.config.LogLevel
import com.transistorsoft.locationmanager.kotlin.config.PersistMode
import com.transistorsoft.locationmanager.kotlin.config.LocationAuthorizationRequest
import com.transistorsoft.locationmanager.kotlin.config.TrackingMode
import com.transistorsoft.locationmanager.kotlin.BGGeo
import com.transistorsoft.locationmanager.kotlin.TransistorAuthorizationService
import kotlinx.coroutines.launch
import com.transistorsoft.bggeo.kotlin.demo.location.TRACKER_HOST
import com.transistorsoft.bggeo.kotlin.demo.location.LocationManager
import com.transistorsoft.bggeo.kotlin.demo.R
import com.transistorsoft.bggeo.kotlin.demo.UiConfigState
import com.transistorsoft.bggeo.kotlin.demo.databinding.SheetSettingsBinding
import com.transistorsoft.bggeo.kotlin.demo.settings.ConfigViewModel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

class SettingsBottomSheet : BottomSheetDialogFragment() {

    companion object {
        private const val TAG = "SettingsBottomSheet"

        // Dropdown options
        private val ACCURACY_OPTIONS = arrayOf("Navigation", "High", "Medium", "Low", "Minimum")
        private val AUTH_OPTIONS = arrayOf("Always", "WhenInUse", "Any")
        private val TRACKING_MODE_OPTIONS = arrayOf("Location + Geofences", "Geofences only")
        private val AUTO_SYNC_OPTIONS = arrayOf("0", "5", "10", "20", "50", "100")
        private val MAX_BATCH_OPTIONS = arrayOf("5", "10", "20", "50", "100")
        private val MAX_RECORDS_OPTIONS = arrayOf("-1", "0", "1", "3", "10", "100")
        private val MAX_DAYS_OPTIONS = arrayOf("-1", "1", "2", "3", "5", "7", "14")
        private val PERSIST_MODE_OPTIONS = arrayOf("ALL", "LOCATIONS", "GEOFENCES", "NONE")
        private val HEARTBEAT_OPTIONS = arrayOf("-1", "60", "120", "300", "900")
        private val LOG_LEVEL_OPTIONS = arrayOf("OFF", "ERROR", "WARN", "INFO", "DEBUG", "VERBOSE")
        private val LOG_DAYS_OPTIONS = arrayOf("1", "2", "3", "4", "5", "6", "7")

        // Transistor Authorization preference keys (defined in LocationManager.companion)
        private val PREFS_NAME get() = LocationManager.PREFS_NAME
        private val KEY_ORG get() = LocationManager.KEY_ORG
        private val KEY_USERNAME get() = LocationManager.KEY_USERNAME
    }

    private var _binding: SheetSettingsBinding? = null
    private val binding get() = _binding!!
    private val vm: ConfigViewModel by activityViewModels()

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        return BottomSheetDialog(requireContext(), theme)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = SheetSettingsBinding.inflate(inflater, container, false)
        setupHeaderActions()
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Begin edit session
        vm.begin()
        Log.d(TAG, "Edit session started")

        // Setup UI components
        setupDropdowns()
        setupSteppers()
        setupSwitches()
        setupTextInputs()

        // Observe state changes
        observeConfigChanges()
    }

    private fun setupHeaderActions() {
        binding.btnCancel.setOnClickListener {
            vm.cancel()
            dismiss()
        }

        binding.btnSave.setOnClickListener {
            Log.d(TAG, "Saving configuration changes")
            vm.persistAndApply()
            dismiss()
        }

        binding.btnOverflow.setOnClickListener { v ->
            PopupMenu(requireContext(), v).apply {
                menu.add("Transistor Auth").setOnMenuItemClickListener {
                    transistorAuthorization()
                    true
                }
                menu.add("Remove Geofences").setOnMenuItemClickListener {
                    confirmRemoveGeofences()
                    true
                }
                menu.add("Clear log").setOnMenuItemClickListener {
                    destroyLog()
                    true
                }
                show()
            }
        }
    }

    private fun setupDropdowns() {
        val snap = vm.snapshot.value

        // Setup individual dropdowns with their options and current values
        setupAccuracyDropdown(snap.desiredAccuracy)
        setupIntervalDropdowns(snap.locationUpdateInterval, snap.fastestLocationUpdateInterval)
        setupAuthorizationDropdown(snap.locationAuthorizationRequest)
        setupTrackingModeDropdown()
        setupHttpDropdowns(snap.autoSyncThreshold, snap.maxBatchSize)
        setupPersistenceDropdowns(snap.maxRecordsToPersist, snap.maxDaysToPersist, snap.persistMode)
        setupApplicationDropdowns(snap.heartbeatInterval)
        setupDebugDropdowns(snap.logLevel, snap.logMaxDays)
    }

    private fun setupAccuracyDropdown(currentAccuracy: DesiredAccuracy) {
        binding.dropDesiredAccuracy.apply {
            setSimpleItems(ACCURACY_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(accuracyToString(currentAccuracy), false)
            setOnItemClickListener { _, _, position, _ ->
                val accuracy = stringToAccuracy(ACCURACY_OPTIONS[position])
                vm.setDesiredAccuracy(accuracy)
            }
        }
    }

    private fun setupIntervalDropdowns(locationInterval: Long, fastestInterval: Long) {
        val intervalItems = resources.getStringArray(R.array.interval_ms_entries)

        binding.dropLocationUpdateInterval.apply {
            setSimpleItems(intervalItems)
            setOnClickListener { showDropDown() }
            setText(locationInterval.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setLocationUpdateInterval(intervalItems[position].toInt())
            }
        }

        binding.dropFastestLocationUpdateInterval.apply {
            setSimpleItems(intervalItems)
            setOnClickListener { showDropDown() }
            setText(fastestInterval.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setFastestLocationUpdateInterval(intervalItems[position].toInt())
            }
        }
    }

    private fun setupAuthorizationDropdown(currentAuth: LocationAuthorizationRequest) {
        binding.dropAuthorization.apply {
            setSimpleItems(AUTH_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(currentAuth.value, false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setAuthorization(LocationAuthorizationRequest.fromValue(AUTH_OPTIONS[position]))
            }
        }
    }

    private fun setupTrackingModeDropdown() {
        val currentMode = when (BGGeo.instance.config.trackingMode) {
            TrackingMode.LOCATION -> "Location + Geofences"
            else -> "Geofences only"
        }

        binding.dropTrackingMode.apply {
            setSimpleItems(TRACKING_MODE_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(currentMode, false)
            setOnItemClickListener { _, _, position, _ ->
                val mode = when (position) {
                    0 -> UiConfigState.TrackingMode.LOCATION_AND_GEOFENCES
                    else -> UiConfigState.TrackingMode.GEOFENCES_ONLY
                }
                vm.setTrackingMode(mode)
            }
        }
    }

    private fun setupHttpDropdowns(autoSyncThreshold: Int, maxBatchSize: Int) {
        binding.dropAutoSyncThreshold.apply {
            setSimpleItems(AUTO_SYNC_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(autoSyncThreshold.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setAutoSyncThreshold(AUTO_SYNC_OPTIONS[position].toInt())
            }
        }

        binding.dropMaxBatchSize.apply {
            setSimpleItems(MAX_BATCH_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(maxBatchSize.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setMaxBatchSize(MAX_BATCH_OPTIONS[position].toInt())
            }
        }
    }

    private fun setupPersistenceDropdowns(maxRecords: Int, maxDays: Int, persistMode: PersistMode) {
        binding.dropMaxRecordsToPersist.apply {
            setSimpleItems(MAX_RECORDS_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(maxRecords.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setMaxRecordsToPersist(MAX_RECORDS_OPTIONS[position].toInt())
            }
        }

        binding.dropMaxDaysToPersist.apply {
            setSimpleItems(MAX_DAYS_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(maxDays.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setMaxDaysToPersist(MAX_DAYS_OPTIONS[position].toInt())
            }
        }

        binding.dropPersistMode.apply {
            setSimpleItems(PERSIST_MODE_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(persistModeToString(persistMode), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setPersistMode(stringToPersistMode(PERSIST_MODE_OPTIONS[position]))
            }
        }
    }

    private fun setupApplicationDropdowns(heartbeatInterval: Double) {
        binding.dropHeartbeatInterval.apply {
            setSimpleItems(HEARTBEAT_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(heartbeatInterval.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setHeartbeatInterval(HEARTBEAT_OPTIONS[position].toInt())
            }
        }
    }

    private fun setupDebugDropdowns(logLevel: LogLevel, logMaxDays: Int) {
        binding.dropLogLevel.apply {
            setSimpleItems(LOG_LEVEL_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(logLevelToString(logLevel), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setLogLevel(stringToLogLevel(LOG_LEVEL_OPTIONS[position]))
            }
        }

        binding.dropLogMaxDays.apply {
            setSimpleItems(LOG_DAYS_OPTIONS)
            setOnClickListener { showDropDown() }
            setText(logMaxDays.toString(), false)
            setOnItemClickListener { _, _, position, _ ->
                vm.setLogMaxDays(LOG_DAYS_OPTIONS[position].toInt())
            }
        }
    }

    private fun setupSteppers() {
        val snap = vm.snapshot.value

        // Setup stepper fields with current values and change handlers
        binding.dfStepper.apply {
            setValueSilently(snap.distanceFilter)
            onValueChanged = { value -> vm.setDistanceFilter(value) }
        }

        binding.srStepper.apply {
            setValueSilently(snap.stationaryRadius.toFloat())
            onValueChanged = { value -> vm.setStationaryRadius(value) }
        }

        binding.stopStepper.apply {
            setValueSilently(snap.stopTimeout.toFloat())
            onValueChanged = { value -> vm.setStopTimeout(value.toInt()) }
        }

        binding.gprStepper.apply {
            setValueSilently(snap.geofenceProximityRadius.toFloat())
            onValueChanged = { value -> vm.setGeofenceProximityRadius(value.toInt()) }
        }

        binding.mdDelayStepper.apply {
            setValueSilently(snap.stopDetectionDelayMs.toFloat())
            onValueChanged = { value -> vm.setStopDetectionDelayMs(value.toLong()) }
        }
    }

    private fun setupSwitches() {
        val snap = vm.snapshot.value

        // Setup switches with current values and change handlers
        binding.switchDisableMotionActivityUpdates.apply {
            isChecked = snap.disableMotionActivityUpdates
            setOnCheckedChangeListener { _, checked -> vm.setDisableMotionActivityUpdates(checked) }
        }

        binding.switchDisableStopDetection.apply {
            isChecked = snap.disableStopDetection
            setOnCheckedChangeListener { _, checked -> vm.setDisableStopDetection(checked) }
        }

        binding.switchAutoSync.apply {
            isChecked = snap.autoSync
            setOnCheckedChangeListener { _, checked -> vm.setAutoSync(checked) }
        }

        binding.switchBatchSync.apply {
            isChecked = snap.batchSync
            setOnCheckedChangeListener { _, checked -> vm.setBatchSync(checked) }
        }

        binding.switchSignificantChanges.apply {
            isChecked = snap.significantChangesOnly
            setOnCheckedChangeListener { _, checked -> vm.setUseSignificantChangesOnly(checked) }
        }

        binding.switchGeofenceHighAccuracy.apply {
            isChecked = snap.geofenceModeHighAccuracy
            setOnCheckedChangeListener { _, checked -> vm.setGeofenceModeHighAccuracy(checked) }
        }

        binding.switchStopOnTerminate.apply {
            isChecked = snap.stopOnTerminate
            setOnCheckedChangeListener { _, checked -> vm.setStopOnTerminate(checked) }
        }

        binding.switchStartOnBoot.apply {
            isChecked = snap.startOnBoot
            setOnCheckedChangeListener { _, checked -> vm.setStartOnBoot(checked) }
        }

        binding.switchDebug.apply {
            isChecked = snap.debug
            setOnCheckedChangeListener { _, checked -> vm.setDebug(checked) }
        }

        binding.switchDisableElasticity.apply {
            isChecked = snap.disableElasticity
            setOnCheckedChangeListener { _, checked ->
                vm.setDisableElasticity(checked)
            }
        }
    }

    private fun setupTextInputs() {
        val snap = vm.snapshot.value

        // HTTP URL input
        binding.inputHttpUrl.apply {
            setText(snap.url)
            doAfterTextChanged { editable ->
                vm.setUrl(editable?.toString() ?: "")
            }
        }
    }

    private fun observeConfigChanges() {
        vm.snapshot.onEach { snap ->
            // Update UI when config changes (e.g., desired accuracy dropdown)
            Log.d(TAG, "Config updated: desiredAccuracy=${snap.desiredAccuracy}")

            val currentAccuracyLabel = accuracyToString(snap.desiredAccuracy)
            val currentDropdownText = binding.dropDesiredAccuracy.text?.toString()

            if (currentDropdownText != currentAccuracyLabel) {
                binding.dropDesiredAccuracy.setText(currentAccuracyLabel, false)
                Log.d(TAG, "Updated accuracy dropdown: $currentDropdownText -> $currentAccuracyLabel")
            }
        }.launchIn(viewLifecycleOwner.lifecycleScope)
    }

    // --- Helper Methods for Value Mapping ---

    private fun accuracyToString(accuracy: DesiredAccuracy): String = when (accuracy) {
        DesiredAccuracy.HIGH -> "High"
        DesiredAccuracy.MEDIUM -> "Medium"
        DesiredAccuracy.LOW -> "Low"
        DesiredAccuracy.LOWEST -> "Minimum"
    }

    private fun stringToAccuracy(label: String): DesiredAccuracy = when (label) {
        "Navigation", "High" -> DesiredAccuracy.HIGH
        "Medium" -> DesiredAccuracy.MEDIUM
        "Low" -> DesiredAccuracy.LOW
        "Minimum" -> DesiredAccuracy.LOWEST
        else -> DesiredAccuracy.HIGH
    }

    private fun persistModeToString(mode: PersistMode): String = when (mode) {
        PersistMode.ALL -> "ALL"
        PersistMode.LOCATION -> "LOCATIONS"
        PersistMode.NONE -> "NONE"
        PersistMode.GEOFENCE -> "GEOFENCES"
    }

    private fun stringToPersistMode(label: String): PersistMode = when (label) {
        "ALL" -> PersistMode.ALL
        "LOCATIONS" -> PersistMode.LOCATION
        "NONE" -> PersistMode.NONE
        "GEOFENCES" -> PersistMode.GEOFENCE
        else -> PersistMode.ALL
    }

    private fun logLevelToString(level: LogLevel): String = when (level) {
        LogLevel.OFF -> "OFF"
        LogLevel.ERROR -> "ERROR"
        LogLevel.WARNING -> "WARN"
        LogLevel.INFO -> "INFO"
        LogLevel.DEBUG -> "DEBUG"
        LogLevel.VERBOSE -> "VERBOSE"
    }

    private fun stringToLogLevel(label: String): LogLevel = when (label) {
        "OFF" -> LogLevel.OFF
        "ERROR" -> LogLevel.ERROR
        "WARN" -> LogLevel.WARNING
        "INFO" -> LogLevel.INFO
        "DEBUG" -> LogLevel.DEBUG
        "VERBOSE" -> LogLevel.VERBOSE
        else -> LogLevel.INFO
    }

    private fun destroyLog() {
        lifecycleScope.launch {
            BGGeo.instance.logger.destroyLog()
        }
    }

    private fun transistorAuthorization() {
        val ctx = requireContext()
        val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val orgInitial = prefs.getString(KEY_ORG, "") ?: ""
        val userInitial = prefs.getString(KEY_USERNAME, "") ?: ""

        // Build a small form programmatically to avoid a new XML file
        val container = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 32, 48, 8) // dp-ish; Material will scale on density
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        val tilOrg = TextInputLayout(ctx).apply {
            hint = "Organization name"
            isHintEnabled = true
        }
        val etOrg = TextInputEditText(tilOrg.context).apply {
            setText(orgInitial)
        }
        tilOrg.addView(
            etOrg,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )

        val tilUser = TextInputLayout(ctx).apply {
            hint = "Username"
            isHintEnabled = true
        }
        val etUser = TextInputEditText(tilUser.context).apply {
            setText(userInitial)
        }
        tilUser.addView(
            etUser,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )

        container.addView(tilOrg)
        container.addView(tilUser)

        val dlg = MaterialAlertDialogBuilder(ctx)
            .setTitle("Demo Server Registration")
            .setView(container)
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Register", null) // we'll override click to validate
            .create()

        dlg.setOnShowListener {
            val btn = dlg.getButton(DialogInterface.BUTTON_POSITIVE)
            btn.setOnClickListener {
                val org = etOrg.text?.toString()?.trim().orEmpty()
                val user = etUser.text?.toString()?.trim().orEmpty()

                tilOrg.error = null
                tilUser.error = null

                var valid = true
                if (org.isEmpty()) { tilOrg.error = "Required"; valid = false }
                if (user.isEmpty()) { tilUser.error = "Required"; valid = false }
                if (!valid) return@setOnClickListener

                prefs.edit()
                    .putString(KEY_ORG, org)
                    .putString(KEY_USERNAME, user)
                    .apply()


                val trackerHost = TRACKER_HOST
                lifecycleScope.launch {
                    try {
                        TransistorAuthorizationService.destroyToken(ctx, trackerHost)
                        val token = TransistorAuthorizationService.findOrCreateToken(ctx, org, user, trackerHost)
                        BGGeo.instance.config.edit {
                            http.url = "$trackerHost/api/locations"
                            authorization.strategy = AuthorizationStrategy.JWT
                            authorization.accessToken = token.accessToken
                            authorization.refreshToken = token.refreshToken
                            authorization.expires = token.expires
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Authorization failed: ${e.message}")
                    }
                }

                Toast.makeText(ctx, "Registered for demo server", Toast.LENGTH_SHORT).show()
                dlg.dismiss()
            }
        }

        dlg.show()
    }

    private fun confirmRemoveGeofences() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Remove all geofences?")
            .setMessage("This will remove all monitored geofences from the SDK.")
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Remove") { _, _ ->
                lifecycleScope.launch {
                    try {
                        BGGeo.instance.geofences.removeAll()
                        Log.d(TAG, "All geofences removed successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to remove geofences: ${e.message}")
                    }
                }
            }
            .show()
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        parentFragmentManager.setFragmentResult("settings_closed", Bundle())
    }

    override fun onDestroyView() {
        super.onDestroyView()
        parentFragmentManager.setFragmentResult("settings_closed", Bundle())
        _binding = null
    }
}
