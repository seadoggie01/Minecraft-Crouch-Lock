#Region ### AutoIt Wrapper ###

#AutoIt3Wrapper_Res_Fileversion=0.0.0.2
#AutoIt3Wrapper_Res_FileVersion_AutoIncrement=y

#EndRegion ### AutoIt Wrapper ###

#Region ### Includes ###

#include <TrayConstants.au3>			; Nicer looking tray constants
#Include <WinAPI.au3>					; Check on CapsLock status
#include <WinAPIvkeysConstants.au3>		; Check on CapsLock status

#EndRegion ### Includes ###

#Region ### HotKeys ###

; Whenever these keys are pressed, these functions will be called

;~; We don't watch for starting of chat until Caps Lock is pressed
;~; HotKeySet($T_HOTKEY, "StartChat")

;~; We don't watch for exiting of chat until chat is entered
;~; HotKeySet("{ESC}", "StopChat")
;~; HotKeySet("{ENTER}", "StopChat")

#EndRegion ### HotKeys ###

#Region ### Global Variables ###

;~ ; A config if I need it later... not now
;~ Global Const $config = @CommonFilesDir & "\AutoIt\RepeatKeys.ini"
;~ DirCreate(@CommonFilesDir & "\AutoIt\")

Global $HoldShift = False
Global $chatting = False
Global $version = FileGetVersion(@ScriptFullPath)
; Use regular expression to find Minecraft... hopefully they don't mess with the title too much... should add the Class here too eventually
Global Const $MINECRAFT_TITLE = "[REGEXPTITLE:(?i)Minecraft.*; CLASS:GLFW30]"
Global Const $T_HOTKEY = "T"

#EndRegion ### Global Variables ###

#Region ### AutoIt Options ###

AutoItSetOption("TrayMenuMode", 1+2+4+8)	;<-- 1. Don't use a default menu,
											;    2. Don't auto-check items,
											;    4. Don't return a default when double clicked,
											;    8. And don't auto-check radio items. Jeesh
AutoItSetOption("SendCapsLockMode", 0)		; Don't press CapsLock to send items... I don't know if it's important anymore. Should check.

#EndRegion ### AutoIt Options ###

Init()
Main()

Func Init()

	TrayCreateItem("Minecraft Crouch Lock")
		TrayItemSetState(-1, $TRAY_DISABLE)
	TrayCreateItem("")								; <-- A seperator
		TrayItemSetState(-1, $TRAY_DISABLE)
	Global $trayLockShiftItem = TrayCreateItem("Lock Shift")
	TrayCreateItem("")								; <-- A seperator
		TrayItemSetState(-1, $TRAY_DISABLE)
	Global $trayAboutItem = TrayCreateItem("About")
	Global $trayExitItem = TrayCreateItem("Exit")

EndFunc

Func Main()

	; Essentially, loop forever
	While True

		Switch TrayGetMsg()
			Case $trayLockShiftItem
				Send("{CAPSLOCK on}")
				ToggleShift()
			Case $trayAboutItem
				MsgBox(0, "Minecraft Crouch Lock", _
				"Minecraft Crouch Lock" & @CRLF & _
				"By: Seadoggie01" & @CRLF & _
				"" & @CRLF & _
				"When you're in Minecraft and press Caps Lock, this program will hold Shift for you for easy building, hiding, or whatever you need." & @CRLF & _
				"Please post any issues or suggestions to GitHub and look there for updates." & @CRLF & _
				"Version: " & $version)
			Case $trayExitItem
				ExitLoop
		EndSwitch

		; If we're in Minecraft
		If WinActive($MINECRAFT_TITLE, "") Then

			; If Caps Lock is on
			If BitAND(_WinAPI_GetKeyState($VK_CAPITAL), 1) = 1 Then

				; If not holding shift
				If Not $HoldShift Then
					; We should be holding shift
					ToggleShift()
				EndIf

			Else ; Caps is off

				; If we're holding shift, we shouldn't be
				If $HoldShift And Not $chatting Then
					; Release shift
					ToggleShift()

				EndIf

			EndIf

		EndIf

	WEnd

EndFunc

Func ToggleShift()

	$HoldShift = Not $HoldShift

	; If the user doesn't want shift held
	If $HoldShift Then
		Debug("Watching for t")
		; Hold down shift
		Send("{SHIFTDOWN}")
		; Watch for chatting
		HotKeySet($T_HOTKEY, "StartChat")
		Sleep(25)
	Else
		Debug("Releasing escape and t")
		; Ignore key presses of Escape and t
		HotKeySet("{ESC}")
		HotKeySet("{ENTER}")
		HotKeySet($T_HOTKEY)
		; Release shift
		Send("{SHIFTUP}")
		Sleep(25)
	EndIf

EndFunc

Func StartChat()

	Debug("StartChat called")

	; Release the HotKey
	HotKeySet($T_HOTKEY)
	; Send the t that the user attempted to send
	Send($T_HOTKEY)

	; Check if we're in Minecraft and Holding Shift for the user
	If WinActive($MINECRAFT_TITLE, "") And $HoldShift Then
		; Turn caps lock off
		Send("{CAPSLOCK off}")
		; Release shift
		Send("{SHIFTUP}")
		; User is chatting
		$chatting = True
		; Add escape/enter to watch for exit of chat
		HotKeySet("{ESC}", "StopChat")
		HotKeySet("{ENTER}", "StopChat")
	EndIf

EndFunc

Func StopChat()

	Debug("StopChat called")

	; Send Escape/Enter without launching this again
	HotKeySet(@HotKeyPressed)
	Send(@HotKeyPressed)

	; Check if we're in Minecraft and chatting and holding shift
	If WinActive($MINECRAFT_TITLE, "") Then

		; They pressed escape/enter, so they aren't chatting anymore
		$chatting = False
		; Re-enable pressing t to start chat
		HotKeySet($T_HOTKEY, "StartChat")
		Send("{SHIFTDOWN}")
		; Re-enable caps
		Send("{CAPSLOCK on}")
		; Remove hotkeys for this function (only after chat is started)
		HotKeySet("{ESC}")
		HotKeySet("{ENTER}")

	EndIf

EndFunc

Func Debug($Msg, $prefix = "+")

	; If this is still in au3 (not exe) then write to the console
	If Not @Compiled Then ConsoleWrite($prefix & " " & $Msg & @CRLF)

EndFunc
