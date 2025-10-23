#Requires AutoHotkey v2.0
#Warn ; Recommended for all new scripts.

; ====================================================================================
; --- Configuration ---
; ====================================================================================
global TargetWindow := "ahk_exe Ryujinx.exe" ; Or "ahk_exe RyujinxCanary.exe"

; --- Key Mappings ---
global MovementKey := "s"
global TurnAroundKey := "s"
global MenuKey := "c"
global R_ShoulderKey := "u"
global ConfirmKey := "z"
global CancelKey := "x"
global CameraLeftKey := "j"

; --- Timing Configuration (in milliseconds) ---
global BenchDialogueDelay := 1000
global BenchCutsceneWait := 15000
global CameraSpinDuration := 5000

; ====================================================================================
; --- Global State Variable ---
; ====================================================================================
; This is our "kill switch". The main automation loop will run as long as this is true.
global g_RunLoop := false

; ====================================================================================
; --- Script Start-up Check ---
; ====================================================================================
controls :=
    "`n`n--- CONTROLS ---`nF3 = Toggle AFK Bench Hunt`nF4 = Toggle AFK Walk`nF5 = Use Bench to Rest Once`nEND = Stop Script`nDel = Exit and kill Script"

if !WinExist(TargetWindow) {
    MsgBox "Pokemon ZA Helper is active but the target window '" . TargetWindow .
        "' was not found.`nPlease start Ryujinx or update the TargetWindow variable." . controls .
        "`n`nAutoHotkey Version: " . A_AhkVersion
} else {
    MsgBox "Pokemon ZA Helper is now active!`nTarget: " . TargetWindow . controls . "`n`nAutoHotkey Version: " .
        A_AhkVersion
}

; ====================================================================================
; --- Core Interruptible Functions ---
; ====================================================================================

; A custom sleep function that can be interrupted by setting g_RunLoop to false.
InterruptibleSleep(Duration) {
    LoopIterations := Duration // 100 ; Check the kill switch every 100ms
    loop LoopIterations {
        if !g_RunLoop
            return false ; Signal that we were interrupted
        Sleep(100)
    }
    return true ; Signal that the sleep completed fully
}

SaveGame() {
    if !g_RunLoop {
        return false
    }
    Tooltip("Saving game...")

    ControlSend("{" MenuKey " down}{" MenuKey " up}", , TargetWindow)
    if !InterruptibleSleep(500) {
        return false
    }

    ControlSend("{" R_ShoulderKey " down}{" R_ShoulderKey " up}", , TargetWindow)
    if !InterruptibleSleep(500) {
        return false
    }

    ControlSend("{" ConfirmKey " down}{" ConfirmKey " up}", , TargetWindow)
    if !InterruptibleSleep(1000) {
        return false
    }

    ControlSend("{" ConfirmKey " down}{" ConfirmKey " up}", , TargetWindow)
    if !InterruptibleSleep(4000) {
        return false
    }

    ControlSend("{" ConfirmKey " down}{" ConfirmKey " up}", , TargetWindow)
    if !InterruptibleSleep(500) {
        return false
    }

    ControlSend("{" CancelKey " down}{" CancelKey " up}", , TargetWindow)

    Tooltip("Save complete!")
    return true
}

UseBench() {
    if !g_RunLoop {
        return false
    }
    Tooltip("Using bench...")

    ; Turn around
    ControlSend("{" TurnAroundKey " down}", , TargetWindow)
    if !InterruptibleSleep(500) {
        return false
    }
    ControlSend("{" TurnAroundKey " up}", , TargetWindow)
    if !InterruptibleSleep(500) {
        return false
    }

    ; Spin Camera
    ControlSend("{" CameraLeftKey " down}", , TargetWindow)
    if !InterruptibleSleep(CameraSpinDuration) {
        return false
    }
    ControlSend("{" CameraLeftKey " up}", , TargetWindow)

    ; Mash through dialogue
    loop 7 {
        if !g_RunLoop {
            return false
        }
        ControlSend("{" ConfirmKey " down}{" ConfirmKey " up}", , TargetWindow)
        Tooltip("Using bench... (" . A_Index . "/7)")
        if !InterruptibleSleep(BenchDialogueDelay) {
            return false
        }
    }

    ; Wait for cutscene
    Tooltip("Waiting for cutscene...")
    if !InterruptibleSleep(BenchCutsceneWait) {
        return false
    }

    Tooltip("Rest complete!")
    return true
}

; This function contains the main automation loop.
MainAutomationLoop() {
    while (g_RunLoop) {
        if !UseBench() {
            break
        } ; If a function was interrupted, stop the loop.
        if !SaveGame() {
            break
        }
    }

    ; Cleanup after the loop stops for any reason.
    global g_RunLoop := false ; Ensure the state is off
    Tooltip("Automation Stopped.")
    Sleep(2000)
    Tooltip()
}

; ====================================================================================
; --- Hotkeys ---
; ====================================================================================

; --- Hotkey: F3 - Toggles the main automation loop ---
F3:: {
    global g_RunLoop := !g_RunLoop ; Flip the switch

    if (g_RunLoop) {
        Tooltip("Automation Started...")
        MainAutomationLoop() ; Start the loop
    } else {
        Tooltip("Stopping...") ; The user wants to stop. The running loop will see this and exit.
    }
}

; --- Hotkey: F4 - Toggle AFK Shiny Hunt using door ---
F4:: {
    static Toggle := false
    Toggle := !Toggle
    if (Toggle) {
        ControlSend("{" MovementKey " down}", , TargetWindow)
        Tooltip("Shiny Hunting: ON")
    } else {
        ControlSend("{" MovementKey " up}", , TargetWindow)
        Tooltip()
    }
}

; --- Hotkey: F5 - Use Bench once (does not loop) ---
F5:: {
    global g_RunLoop := true ; Temporarily enable run condition for this one-off execution
    UseBench()
    global g_RunLoop := false ; Reset the run condition
}

; --- Hotkey: End - Exit Script ---
End:: {
    global g_RunLoop := false ; Stop any running loops
}
; --- Hotkey: Del - Emergency Exit Script ---
Del:: {
    ExitApp()
}
