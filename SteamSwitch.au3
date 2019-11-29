#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=SteamSwitch.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=SteamSwitch
#AutoIt3Wrapper_Res_Description=SteamSwitch
#AutoIt3Wrapper_Res_Fileversion=1.5
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Icon_Add=icons\SteamSwitch1.ico
#AutoIt3Wrapper_Res_Icon_Add=icons\SteamSwitch2.ico
#AutoIt3Wrapper_Res_Icon_Add=icons\SteamSwitch3.ico
#AutoIt3Wrapper_Res_Icon_Add=icons\SteamSwitch4.ico
#AutoIt3Wrapper_Res_Icon_Add=icons\SteamSwitch5.ico
#AutoIt3Wrapper_Run_Before=IF "%fileversion%" NEQ "" COPY "%in%" "%scriptdir%\%scriptfile% (v%fileversion%).au3"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <TabConstants.au3>
#include <GuiTab.au3>
#include <GuiMenu.au3>
#include <Date.au3>

#include <Json.au3> ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn/

Opt('MustDeclareVars', 1)

Global Const $STEAM_REG = 'HKCU\Software\Valve\Steam'
Global Const $STEAM_EXE = RegRead($STEAM_REG, 'SteamExe')
Global Const $STEAM_PATH = RegRead($STEAM_REG, 'SteamPath')
Global Const $STEAM_CFG_PATH = $STEAM_PATH & '\config\loginusers.vdf'
Global Const $REG_USERNAME = 'AutoLoginUser'
Global Const $REG_REMPASS = 'RememberPassword'
Global Const $CURR_USER = RegRead($STEAM_REG, $REG_USERNAME)
Global Const $CFG_PATH = @AppDataDir & '\therkSoft\SteamSwitch\'
Global Const $USERS_FILE = $CFG_PATH & 'userlist.cfg'
Global Const $WAIT_ANIM = $CFG_PATH & 'waiting.ani'
Global Const $AVATAR_PATH = $CFG_PATH & 'avatars\'
Global Const $NO_AVATAR = $AVATAR_PATH & '.none.gif'
Global Const $DEFAULT_AV = $AVATAR_PATH & '.default.gif'
Global Const $MAX_WIDTH = Int(@DesktopWidth *.8)
Global Const $MAX_HEIGHT = Int(@DesktopHeight * 0.7)
Global Const $DOWNLOAD_PARAM = '/_DownloadAvatars'

Global $WMG_HMAIN, $WMG_TAB, $WMG_ME_MENU, $WMG_MI_TITLE, $WMG_MI_ONLINE, $WMG_MI_OFFLINE ; Window Message Globals
Global Enum $UL_USER, $UL_AVATAR, $UL_DOWNLOAD, $UL_PIC_CTRL, $UL_BTN_CTRL, $UL_UBOUND
Global $USER_LIST[1][$UL_UBOUND]

Main()

Func Main()
	; Cannot find steam installation so quit
	If Not $STEAM_EXE Then
		Exit @ScriptLineNumber+0*MsgBox(0x10, 'SteamSwitch', 'Could not read Steam registry key.' & @LF & 'Please ensure Steam has been installed and started at least once before using this program.')
	EndIf

	; Create appdata folders
	If Not FileExists($AVATAR_PATH) Then DirCreate($AVATAR_PATH)

	; Install waiting animation and default avatar
	FileInstall('Waiting.ani', $WAIT_ANIM, 1)
	FileInstall('SteamSwitch_None.gif', $NO_AVATAR)
	FileInstall('SteamSwitch_Default.gif', $DEFAULT_AV)

	; Run downloader and exit
	If $CmdLine[0] And $CmdLine[1] = $DOWNLOAD_PARAM Then Exit @ScriptLineNumber+0*_DownloadAvatars()

	Local $aUsernames, $sUsersFiltered, $aTabRect, $iButtonMax, $iButtonPos, $iSteamPID, $aWinOffset, $aWinGetPos, _
		$sDownloadList, $sCmdPassthru, $bNoNumbers, $bAutoExpand, $sAutoLogin, $iAvatarSize = 64, $vCenterAt = 'screen', _
		$iTrackWidth = 210, $iTrackHeight = 0, $iWinWidth, $iWinHeight, $iWinHeightExpand, $aCtrlPos, $sButtonText, $iOfflineMode = 0, $aAccel, _
		$hGUIParent, $bt_Banner, $cm_Banner, $mi_OpenSteam, $mi_CloseSteam, $mi_GoOnline, $mi_GoOffline, $mi_ReloadAvatar, $aRange_UserBtns[2], _
		$bt_AddMore, $bt_Extra, $aRange_ExtraCtrls[2], $aRange_PicCtrls[2], $ra_OfflineDef, $ra_OfflineNo, $ra_OfflineYes, $bt_ReloadAvatars, $lb_Help, $GM

	; Command line switches:
	; /avatarSize=##, /autoLogin=username, /noNumbers, /offline, /online, /extra, /atMouse
	If $CmdLine[0] Then
		For $i = 1 To $CmdLine[0]
			Switch $CmdLine[$i]
				Case '/online', '/on'
					$iOfflineMode = 1
				Case '/offline', '/of'
					$iOfflineMode = 2
				Case '/noNumbers', '/nn'
					$bNoNumbers = True
				Case '/atMouse', '/am'
					$vCenterAt = 'mouse'
				Case '/extra', '/ex'
					$bAutoExpand = True
				Case Else
					If StringInStr($CmdLine[$i], '/avatarSize=') = 1 Or StringInStr($CmdLine[$i], '/as=') = 1 Then
						$iAvatarSize = Int(StringSplit($CmdLine[$i], '=')[2])
					ElseIf StringInStr($CmdLine[$i], '/autoLogin=') = 1 Or StringInStr($CmdLine[$i], '/al=') = 1 Then
						$sAutoLogin = StringSplit($CmdLine[$i], '=')[2]
					Else
						; Any command that isn't interpreted by this app gets passed through to Steam
						If StringInStr($CmdLine[$i], ' ') Then
							$CmdLine[$i] = '"' & $CmdLine[$i] & '"'
						EndIf
						$sCmdPassthru &= ' ' & $CmdLine[$i]
					EndIf
			EndSwitch
		Next
	EndIf

	; Auto login, jump straight to login function and exit
	If $sAutoLogin Then Exit @ScriptLineNumber+0*_SteamLogin(0, $sAutoLogin, $iOfflineMode, $sCmdPassthru)

	Opt('GUIResizeMode', $GUI_DOCKALL) ; Disable control drifting

	#region - Get user list and create array
		$aUsernames = FileReadToArray($USERS_FILE)
		For $i = 0 To UBound($aUsernames)-1
			; Filter entries to only valid Steam usernames (alphanumeric, underscore, and minimum 3 char)
			; This string ($sUsersFiltered) is also used later to pre-fill the Add Users dialog.
			If StringRegExp($aUsernames[$i], '^[a-zA-Z0-9_]{3,}$') Then $sUsersFiltered &= $aUsernames[$i] & @LF
		Next
		$aUsernames = StringSplit(StringStripWS($sUsersFiltered, 3), @LF)

		If Not $aUsernames[1] Then
			$aUsernames[0] = 0 ; If there were no users then set the count to 0 and the whole button creation will get skipped.
		Else
			ReDim $USER_LIST[$aUsernames[0]+1][$UL_UBOUND]
			$USER_LIST[0][0] = $aUsernames[0]
		EndIf
	#endregion

	; ====================================================================================================================
	#region - Build main GUI
		$hGUIParent = GUICreate('') ; Hidden parent to hide taskbar button
		$WMG_HMAIN = GUICreate('Steam Switcher  ——  F1 for help', 10, 10, Default, Default, $WS_SYSMENU, $WS_EX_TOPMOST)

		; Create context menu that will be used for the user buttons
		$WMG_ME_MENU = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
			$WMG_MI_TITLE = GUICtrlCreateMenuItem('-', $WMG_ME_MENU)
				GUICtrlSetState(-1, BitOR($GUI_DEFBUTTON, $GUI_DISABLE))
			GUICtrlCreateMenuItem('', $WMG_ME_MENU)
			$WMG_MI_ONLINE = GUICtrlCreateMenuItem('Start O&nline', $WMG_ME_MENU)
			$WMG_MI_OFFLINE = GUICtrlCreateMenuItem('Start O&ffline', $WMG_ME_MENU)
			$mi_ReloadAvatar = GUICtrlCreateMenuItem('&Reload Avatar', $WMG_ME_MENU)
		GUIRegisterMsg($WM_CONTEXTMENU, WM_CONTEXTMENU)

		; Show banner if Steam is running
		If ProcessExists('steam.exe') Then
			$bt_Banner = GUICtrlCreateButton('Steam running as ' & $CURR_USER & ' (' & (_SteamCheckOffline($CURR_USER) ? 'Offline' : 'Online') & ')', 0, 0, 10, 25)
				GUICtrlSetFont(-1, 11, 700)
				GUICtrlSetBkColor(-1, 0x1a3f56)
				GUICtrlSetColor(-1, 0x66c0f4)
				GUICtrlSetCursor(-1, 0)
				GUICtrlSetTip(-1, 'Click for options')

			; Banner context menu
			$cm_Banner = GUICtrlCreateContextMenu($bt_Banner)
				$mi_OpenSteam  = GUICtrlCreateMenuItem('Open Steam',  $cm_Banner)
				$mi_CloseSteam = GUICtrlCreateMenuItem('Close Steam', $cm_Banner)

			; If current profile is offline show the Online button and vice versa
			If _SteamCheckOffline($CURR_USER) Then
				$mi_GoOnline   = GUICtrlCreateMenuItem('Go Online',   $cm_Banner)
			Else
				$mi_GoOffline  = GUICtrlCreateMenuItem('Go Offline',  $cm_Banner)
			EndIf
			$iTrackHeight = 25
		EndIf

		$iButtonMax = $aUsernames[0]
		; Calculate the area the user buttons will take up.
		If $iAvatarSize * $aUsernames[0] > $MAX_HEIGHT Then
			$iButtonMax = Int($MAX_HEIGHT / $iAvatarSize) ; How many buttons can properly fit within $MAX_HEIGHT

			$WMG_TAB = GUICtrlCreateTab(0, $iTrackHeight, 100, 100, $TCS_FIXEDWIDTH)

			; Create temporary tab to measure the height of the label for the button offset ($iButtonPos, $iTrackHeight)
			_GUICtrlTab_InsertItem($WMG_TAB, 0, 'temp')
			$aTabRect = _GUICtrlTab_GetItemRect($WMG_TAB, 0)
			_GUICtrlTab_DeleteItem($WMG_TAB, 0)
			$iTrackHeight += $aTabRect[3]
		EndIf
		$iButtonPos = $iTrackHeight

		GUISetFont($iAvatarSize * 0.375) ; Default font (for buttons) proportional to the avatar size
		$aRange_UserBtns[0] = GUICtrlCreateDummy() ; Start control range for user buttons
		For $i = 1 To $aUsernames[0]
			If Mod($i, $iButtonMax) == 1 Then
				GUICtrlCreateTabItem('Tab ' & Ceiling($i/$iButtonMax) & '/' & Ceiling($aUsernames[0]/$iButtonMax))
				$iButtonPos = $iTrackHeight
			EndIf
			$USER_LIST[$i][$UL_USER] = $aUsernames[$i] ; Store username in array

			; Check for user avatars
			$USER_LIST[$i][$UL_AVATAR] = _Avatar($aUsernames[$i])
			If @error Then
				; If no avatar found, flag as needing to be downloaded...
				$USER_LIST[$i][$UL_DOWNLOAD] = True
				; ... and add the name to a download list
				$sDownloadList &= ' ' & $USER_LIST[$i][$UL_USER]
			EndIf
			; This "deferred" function stores the Pic control data to be created later. This allows the arrow keys to cycle through the user buttons.
			$USER_LIST[$i][$UL_PIC_CTRL] = _DeferredGUICtrlCreatePic($USER_LIST[$i][$UL_AVATAR], 0, $iButtonPos, $iAvatarSize, $iAvatarSize)

			; Display (or not) prefix numbers for buttons
			If $bNoNumbers Then
				$sButtonText = ' ' & $aUsernames[$i] & ' '
			Else
				$sButtonText = ($i < 10 ? ' &' & $i : ($i = 10 ? ' 1&0' : ' ' & $i)) & ': ' & $aUsernames[$i]
			EndIf

			$USER_LIST[$i][$UL_BTN_CTRL] = GUICtrlCreateButton($sButtonText, $iAvatarSize, $iButtonPos, Default, $iAvatarSize, BitOR($BS_FLAT, $BS_LEFT))
				GUICtrlSetTip(-1, 'Right-click for more options')
				$iButtonPos += $iAvatarSize

			; Measure button width, and track the largest
			$aCtrlPos = ControlGetPos($WMG_HMAIN, '', $USER_LIST[$i][$UL_BTN_CTRL])
			$iTrackWidth = $iTrackWidth < $aCtrlPos[2] ? $aCtrlPos[2] : $iTrackWidth
		Next
		$aRange_UserBtns[1] = GUICtrlCreateDummy() ; End user button range

		; Snap width to 90% of screen width
		If $iTrackWidth + $iAvatarSize > $MAX_WIDTH Then $iTrackWidth = $MAX_WIDTH - $iAvatarSize

		; Set all the button widths to be equal to the largest
		For $i = 1 To $aUsernames[0]
			GUICtrlSetPos($USER_LIST[$i][$UL_BTN_CTRL], Default, Default, $iTrackWidth)
		Next

		$iWinWidth = $iTrackWidth + $iAvatarSize ; Add avatar size to button width, we'll be using this to size the rest of the window

		; Resize the banner button
		GUICtrlSetPos($bt_Banner, Default, Default, $iWinWidth)

		; Close out and position tab control if necessary. Register mouse wheel message for scrolling said tab control.
		If $WMG_TAB Then
			GUICtrlCreateTabItem('')
			GUICtrlSetPos($WMG_TAB, Default, Default, $iWinWidth, $aTabRect[3])
			GUIRegisterMsg($WM_MOUSEWHEEL, WM_MOUSEWHEEL)
		EndIf

		$iTrackHeight += $iButtonMax * $iAvatarSize ; Add on the user buttons to the height tracker.

		GUISetFont(9) ; Reset font to a regular size

		$bt_AddMore = GUICtrlCreateButton('&Add/Edit Users', 0, $iTrackHeight, $iWinWidth, 25)
			$iTrackHeight += 25

		$bt_Extra = GUICtrlCreateButton('E&xtra Options', 0, $iTrackHeight, $iWinWidth, 20)
			GUICtrlSetFont(-1, 8)
			$iTrackHeight += 20

		$iWinHeight = $iTrackHeight ; Record height now for non-expanded window.

		; ====================================================================================================================
		#region - Extra options controls
			$aRange_ExtraCtrls[0] = GUICtrlCreateDummy() ; Start range for "extra" controls
				$iTrackHeight -= 15 ; Reduce $iTrackHeight a bit cus this group overlaps the "Extra" button
				GUICtrlCreateGroup('Connection Mode:', 5, $iTrackHeight, $iWinWidth-10, 45)
					$iTrackHeight += 20

				$ra_OfflineDef = GUICtrlCreateRadio('&Default', 10, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Use last login connection mode')
				$ra_OfflineNo = GUICtrlCreateRadio('O&nline', 75, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Start in online mode')
				$ra_OfflineYes = GUICtrlCreateRadio('O&ffline', 140, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Start in offline mode')
					$iTrackHeight += 25
					GUICtrlSetState($ra_OfflineDef + $iOfflineMode, $GUI_CHECKED) ; Use $iOfflineMode to determine default-checked radio control

				$bt_ReloadAvatars = GUICtrlCreateButton('&Reload Avatars', 5, $iTrackHeight, $iWinWidth-10, 25)
					$iTrackHeight += 25

				$lb_Help = GUICtrlCreateLabel('Version: ' & FileGetVersion(@ScriptFullPath), 0, $iTrackHeight, $iWinWidth, 10, $SS_CENTER)
					GUICtrlSetFont(-1, 6)
					GUICtrlSetCursor(-1, 4)
					$iTrackHeight += 10
			$aRange_ExtraCtrls[1] = GUICtrlCreateDummy() ; End range
		#endregion
		; ====================================================================================================================
		$iWinHeightExpand = $iTrackHeight ; Record height after extra controls for expanded window

		; Create deferred pic controls now
		$aRange_PicCtrls[0] = GUICtrlCreateDummy()
		For $i = 1 To $USER_LIST[0][0]
			$USER_LIST[$i][$UL_PIC_CTRL] = _DeferredGUICtrlCreatePic($USER_LIST[$i][$UL_PIC_CTRL])
		Next
		$aRange_PicCtrls[1] = GUICtrlCreateDummy()

		For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1]
			GUICtrlSetState($i, $GUI_HIDE) ; Hide the extra controls
		Next

		Dim $aAccel = [ [ '{f1}', $lb_Help ] ]
		GUISetAccelerators($aAccel)

		; Resize and center window
		$aWinOffset = _WinGetClientOffset($WMG_HMAIN)
		If $bAutoExpand Then
			$bAutoExpand = False
			GUICtrlSetState($bt_Extra, $GUI_HIDE)
			For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1]
				GUICtrlSetState($i, $GUI_SHOW)
			Next
			_WinCenter($WMG_HMAIN, $iWinWidth + $aWinOffset[0], $iWinHeightExpand + $aWinOffset[1], $vCenterAt)
		Else
			_WinCenter($WMG_HMAIN, $iWinWidth + $aWinOffset[0], $iWinHeight + $aWinOffset[1], $vCenterAt)
		EndIf

		GUICtrlSetState($bt_AddMore, $GUI_FOCUS)
	#endregion

	; ====================================================================================================================

	GUISetState(@SW_SHOWNORMAL, $WMG_HMAIN)

	If $sDownloadList Then _DownloadAvatars($sDownloadList) ; Start avatar downloads if necessary

	While WinActive($WMG_HMAIN) ; If window loses focus then close immediately.

		$GM = GUIGetMsg()
		Switch $GM
			Case $GUI_EVENT_NONE
				; Some controls are not actually created if not required (ie: $bt_Banner) and
				; their variable defaults to ''. This will match the default GUIGetMsg return (0)
				; and that would erroneously trigger that Case statement.
				; So instead we "handle" the default GUIGetMsg ($GUI_EVENT_NONE) and then the flow
				; never reaches the undeclared variable's Case.
			Case $bt_Banner
				; Clicking the banner triggers the context menu
				$aWinGetPos = WinGetPos(GUICtrlGetHandle($bt_Banner))
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_Banner), $WMG_HMAIN, $aWinGetPos[0]+$aWinGetPos[2], $aWinGetPos[1]+$aWinGetPos[3], 2, 1)
			Case $mi_OpenSteam
				_SteamLogin($WMG_HMAIN)
			Case $mi_CloseSteam
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				If _SteamClose($WMG_HMAIN) Then
					; If Steam closes successfully, then close and relaunch this app (to launch without $bt_Banner)
					GUISetState(@SW_HIDE, $WMG_HMAIN)
					ShellExecute(@AutoItExe, $CmdLineRaw)
					Exit @ScriptLineNumber
				EndIf
				; If Steam didn't close (cancelled or timeout)
				GUISetState(@SW_ENABLE, $WMG_HMAIN)
				WinActivate($WMG_HMAIN)

			; These are from the $bt_Banner menu
			Case $mi_GoOnline
				_SteamLogin($WMG_HMAIN, $CURR_USER, 1, $sCmdPassthru)
			Case $mi_GoOffline
				_SteamLogin($WMG_HMAIN, $CURR_USER, 2, $sCmdPassthru)

			; These are from the user button context menu
			Case $WMG_MI_ONLINE
				_SteamLogin($WMG_HMAIN, GUICtrlRead($WMG_MI_TITLE, 1), 1, $sCmdPassthru)
			Case $WMG_MI_OFFLINE
				_SteamLogin($WMG_HMAIN, GUICtrlRead($WMG_MI_TITLE, 1), 2, $sCmdPassthru)
			Case $mi_ReloadAvatar
				For $i = 1 To $USER_LIST[0][0]
					If $USER_LIST[$i][$UL_USER] = GUICtrlRead($WMG_MI_TITLE, 1) Then
						GUICtrlSetImage($USER_LIST[$i][$UL_PIC_CTRL], $DEFAULT_AV)
						$USER_LIST[$i][$UL_DOWNLOAD] = True
						FileDelete($AVATAR_PATH & $USER_LIST[$i][$UL_USER] & '.jpg')
						_DownloadAvatars($USER_LIST[$i][$UL_USER])
						ExitLoop
					EndIf
				Next

			; User buttons and pics
			Case $aRange_UserBtns[0] To $aRange_UserBtns[1], $aRange_PicCtrls[0] To $aRange_PicCtrls[1]
				For $i = 1 To $USER_LIST[0][0]
					If $GM = $USER_LIST[$i][$UL_PIC_CTRL] Or $GM = $USER_LIST[$i][$UL_BTN_CTRL] Then

						; Instead of 3 If's comparing each state to true, one Switch statement to compare true to each state
						Switch True
							Case BitAND(GUICtrlRead($ra_OfflineDef), $GUI_CHECKED)
								$iOfflineMode = 0
							Case BitAND(GUICtrlRead($ra_OfflineNo), $GUI_CHECKED)
								$iOfflineMode = 1
							Case BitAND(GUICtrlRead($ra_OfflineYes), $GUI_CHECKED)
								$iOfflineMode = 2
						EndSwitch

						_SteamLogin($WMG_HMAIN, $USER_LIST[$i][$UL_USER], $iOfflineMode, $sCmdPassthru)
					EndIf
				Next

			Case $bt_AddMore
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				_AddUsers($WMG_HMAIN, $sUsersFiltered)
				GUISetState(@SW_ENABLE, $WMG_HMAIN)
				WinActivate($WMG_HMAIN)

			Case $bt_Extra
				GUICtrlSetState($bt_Extra, $GUI_HIDE)
				For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1]
					GUICtrlSetState($i, $GUI_SHOW)
				Next
				WinMove($WMG_HMAIN, '', Default, Default, Default, $iWinHeightExpand + $aWinOffset[1])

			Case $lb_Help
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				_Help($WMG_HMAIN)
				GUISetState(@SW_ENABLE, $WMG_HMAIN)
				WinActivate($WMG_HMAIN)

			Case $bt_ReloadAvatars
				For $i = 1 To $USER_LIST[0][0]
					; Set all pics to default avatar
					GUICtrlSetImage($USER_LIST[$i][$UL_PIC_CTRL], $DEFAULT_AV)
					; Mark all items as needed for download
					$USER_LIST[$i][$UL_DOWNLOAD] = True
					; Add usernames to download list
					$sDownloadList &= ' ' & $USER_LIST[$i][$UL_USER]
				Next
				; Delete the whole avatar folder
				DirRemove($AVATAR_PATH, 1)
				; Launch downloader process
				_DownloadAvatars($sDownloadList)

			Case $GUI_EVENT_CLOSE
				Exit @ScriptLineNumber
		EndSwitch
	WEnd
EndFunc

Func _SteamClose($hMain) ; Open cancellable timeout window for Steam closure
	Local $hGUIWait, $lb_Wait, $bt_Cancel, $GM, $iSteamPID, $iTimer, $iCountdown = 15, _
		$iMsgBox, $sMsgBox = 'Failed to shutdown properly.' & @LF & @LF & _
		'Force shutdown?' & @LF & @LF & _
		'Yes:	Kill process (may result in lost data).' & @LF & _
		'No:	Continue waiting for normal shutdown.' & @LF & _
		'Cancel:	Stop trying to shutdown Steam.'

	$hGUIWait = GUICreate('', 200, 110, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hMain)
	$lb_Wait = GUICtrlCreateLabel('Closing Steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($WAIT_ANIM, 0, 84, 40, 32, 32)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 70, 85, 60, 20)

	$iSteamPID = ProcessExists('steam.exe')
	If $iSteamPID Then
		ShellExecute($STEAM_EXE, '-shutdown') ; Send shutdown command to Steam
		GUISetState(@SW_SHOW, $hGUIWait)

		$iTimer = TimerInit() ; Start timer
		GUICtrlSetData($lb_Wait, 'Closing Steam...')
		While ProcessExists($iSteamPID) ; Will immediately exit if Steam exits
			$GM = GUIGetMsg()
			If $GM = $bt_Cancel Or $GM = $GUI_EVENT_CLOSE Then ExitLoop ; Allow cancel

			If TimerDiff($iTimer) > 1000 Then ; Reset $iTimer so this statement runs about once per second
				$iTimer = TimerInit()
				$iCountdown -= 1

				If $iCountdown <= 0 Then
					; Reached end of timeout
					$iMsgBox = MsgBox(0x2213, 'Error', $sMsgBox, 0, $hMain) ; Yes: 6, No: 7, Cancel: 2
					If $iMsgBox = 6 Then ; 6 = Yes = Kill process
						; Confirm kill process
						If MsgBox(0x134, 'Notice', 'Are you sure you want to force Steam to close? This may result in lost data if Steam is still working (eg: uploading cloud saves).', 0, $hMain) = 6 Then
							; Try to kill the process, reset the countdown and continue loop
							ProcessClose($iSteamPID)
							$iCountdown = 10
							GUICtrlSetData($lb_Wait, 'Closing Steam...')
							ContinueLoop
						EndIf
					ElseIf $iMsgBox = 7 Then
						; Try sending the normal Steam shutdown command again, reset countdown, continue loop
						ShellExecute($STEAM_EXE, '-shutdown')
						$iCountdown = 10
						GUICtrlSetData($lb_Wait, 'Closing Steam...')
						ContinueLoop
					Else
						; Just give up already!
						ExitLoop
					EndIf
				ElseIf $iCountdown <= 10 Then
					; Timeout countdown is down to 10 seconds, start showing to user
					GUICtrlSetData($lb_Wait, 'Closing Steam...' & @LF & '(timeout ' & $iCountdown & ' seconds)')
				EndIf
			EndIf
		WEnd
	EndIf

	GUIDelete($hGUIWait)
	Return Not ProcessExists($iSteamPID) ; Return true if Steam is closed or not running
EndFunc

Func _SteamLogin($hMain, $sUsername = $CURR_USER, $iOfflineMode = 0, $sCmdPassthru = '') ; Set login user, offline mode, close Steam if necessary, and relaunch
	Local $iMsgBox, $bReadonly
	GUISetState(@SW_HIDE, $hMain)
	If $CURR_USER <> $sUsername Or $iOfflineMode <> 0 Then
		; We only need to try and close Steam if the user or the offline mode needs to change
		If Not _SteamClose($hMain) Then Return GUISetState(@SW_SHOW, $hMain)

		RegWrite($STEAM_REG, $REG_USERNAME, 'REG_SZ', $sUsername)
	EndIf
	; Make sure Remember Password is enabled. Otherwise Steam will prompt for password, completely defeating the whole purpose of this app.
	RegWrite($STEAM_REG, $REG_REMPASS, 'REG_DWORD', 1)

	; Change offline mode if required
	Switch $iOfflineMode
		Case 0
			_SteamConfig($sUsername, Default)
		Case 1
			_SteamConfig($sUsername, False)
		Case 2
			_SteamConfig($sUsername, True)
	EndSwitch

	; Warn if _SteamConfig failed, but only if user wanted to change offline mode
	If $iOfflineMode Then
		Switch @error
			Case 1
				$bReadonly = StringInStr(FileGetAttrib($STEAM_CFG_PATH), 'R')
				$iMsgBox = MsgBox(0x31, 'Warning', 'Unable to write to ' & $STEAM_CFG_PATH & ($bReadonly ? ' - File is read-only' : '') & '. Cannot change offline mode. Continue anyway?', 0, $hMain)
			Case 2
				$iMsgBox = MsgBox(0x31, 'Warning', 'Unable to find and write user config (possible first time login?). Cannot change offline mode. Continue anyway?', 0, $hMain)
		EndSwitch

		If $iMsgBox = 2 Then Return GUISetState(@SW_SHOW, $hMain)
	EndIf

	; Run Steam with the passed through parameters
	ShellExecute($STEAM_EXE, $sCmdPassthru)
	Exit @ScriptLineNumber
EndFunc

Func _SteamCheckOffline($sUser) ; Quick RegEx check to see if Offline mode is enabled for the requested username
	Return StringRegExp(FileRead($STEAM_CFG_PATH), '(?i)"AccountName"\h*"' & $sUser & '"[^}]+"WantsOfflineMode"\h*"1"')
EndFunc

Func _SteamConfig($sUser, $bOffline = Default) ; Steam config file modifier, toggles offline mode on/off
	#cs
	The loginusers.vdf file is formatted as such:
	"users"
	{
		"STEAM-USER-ID"
		{
			"AccountName"		"USERNAME"
			"Timestamp"		"1234567890"
			"MostRecent"		"1"
			"PersonaName"		"DISPLAY NAME"
			"RememberPassword"		"1"
			"WantsOfflineMode"		"0"
			"SkipOfflineModeWarning"		"0"
		}
		"ANOTHER STEAM-USER-ID"
		{
			"AccountName"		"USERNAME_2"
			"Timestamp"		"1234567890"
			"MostRecent"		"0"
			"PersonaName"		"DISPLAY NAME"
			"RememberPassword"		"1"
		}
		"ANOTHER STEAM-USER-ID"
		{
			[ ... ]
		}
	}

	Pertinent:
		"AccountName"				Matches the username provided to this application.
		"Timestamp" 				A UNIX timestamp. Seems to be set to the last successful login. This timestamp needs
									to be within a certain time frame or else Steam will forget the login credentials.
									I haven't tested for the exact time frame, I just know that setting it too low caused
									me to have to re-enter my password. This application just sets it to the current time(stamp).
		"WantsOfflineMode"			(0 or 1) Indicates whether to start Steam in offline mode.
		"SkipOfflineModeWarning"	(0 or 1) Indicates whether to skip the prompt that Steam displays when starting in offline mode.
									Steam itself sets this value to 1 when manually switching to offline mode (to prevent the dialog
									with the "Go Online" and "Start in Offline Mode" buttons). Steam always sets this value back to 0
									after launching, so this application sets it back to 1 whenever it launches offline mode.
									I've had some trouble lately (after the Steam new library update) getting this to reliably take
									effect. It usually works but now and then I will get the dialog and I can't figure out why.
	Non-pertinent:
		"PersonaName" 				The user's custom display name.
		"MostRecent"				An indicator of which user was most recently logged in. Modifying doesn't seem to affect anything.
		"RememberPassword"			Changing this doesn't seem to have any effect either. The RememberPassword registry entry seems
									to be the only thing that actually has an effect.



	This function will take this content and separate it into 3 segments for easier handling.
		- Segment 1: All content BEFORE user section (up to {)
		- Segment 2: User section itself
		- Segment 3: All content AFTER user section (starting from })

	So for the example provided above we'd get this (for USERNAME_2):
	- Segment 1:
		"users"
		{
			"STEAM-USER-ID"
			{
				"AccountName"		"USERNAME"
				"Timestamp"		"1234567890"
				"MostRecent"		"1"
				"PersonaName"		"DISPLAY NAME"
				"RememberPassword"		"1"
				"WantsOfflineMode"		"0"
				"SkipOfflineModeWarning"		"0"
			}
			"ANOTHER STEAM-USER-ID"
			{

	- Segment 2:
				"AccountName"		"USERNAME_2"
				"Timestamp"		"1234567890"
				"MostRecent"		"0"
				"PersonaName"		"DISPLAY NAME"
				"RememberPassword"		"1"

	- Segment 3:
			}
			"ANOTHER STEAM-USER-ID"
			{
				[ ... ]
			}
		}

	Then we use some regular expressions to replace values in Segment 2. Take this edited config data, sandwich it between Segment 1 & 3,
	and write the combined data to the config file.
	#ce

	Local $sNewConfig, $aSegments, $hFile, _
		$iTimestamp = _DateDiff('s', '1970/01/01 00:00:00', _NowCalc()), _ ; Get UNIX timestamp
		$sConfigData = FileRead($STEAM_CFG_PATH) ; Read in loginusers.vdf

	$aSegments = StringRegExp($sConfigData, '(?si)^(.*{)(.*?"AccountName"\s*"'& $sUser & '".*?)(}.*)$', 1) ; Isolate user segment for rewrite.
	If UBound($aSegments) = 3 Then
		; If Offline mode isn't specifically set, check the current offline mode.
		If $bOffline = Default Then $bOffline = StringRegExp($aSegments[1], '(?i)"WantsOfflineMode"\s*"1"')

		; If the Timestamp value is missing or set low (ie: a long time ago) the password will expire and Steam will prompt to re-enter the password.
		$sNewConfig = StringRegExpReplace($aSegments[1], '(?i)(Timestamp"\s*)".+?"', '\1"' & $iTimestamp & '"')

		; The SkipOfflineModeWarning should, as it implies, skip that prompt on launch but it seems to be inconsistent lately (can't figure out why).
		If $bOffline Then
			; Replace existing value, if replace fails add new value to segment
			$sNewConfig = StringRegExpReplace($sNewConfig, '("WantsOfflineMode"\s*)"."', '\1"1"')
			If Not @extended Then $sNewConfig &= StringFormat('\t"WantsOfflineMode"\t\t"1"\n\t')

			; Same as previous
			$sNewConfig = StringRegExpReplace($sNewConfig, '("SkipOfflineModeWarning"\s*)"."', '\1"1"')
			If Not @extended Then $sNewConfig &= StringFormat('\t"SkipOfflineModeWarning"\t\t"1"\n\t')
		Else
			; Replace existing value, if replace fails just ignore (value not necessary if not using offline mode)
			$sNewConfig = StringRegExpReplace($sNewConfig, '("WantsOfflineMode"\s*)"."', '\1"0"')
			$sNewConfig = StringRegExpReplace($sNewConfig, '("SkipOfflineModeWarning"\s*)"."', '\1"0"')
		EndIf

		; Combine new config with outer segments.
		$sNewConfig = $aSegments[0] & $sNewConfig & $aSegments[2]

		$hFile = FileOpen($STEAM_CFG_PATH, 2)
		If $hFile <> -1 Then
			FileWrite($hFile, $sNewConfig)
			FileClose($hFile)
			Return 1
		Else
			Return SetError(1, 0, 0)
		EndIf
	EndIf
	Return SetError(2, 0, 0)
EndFunc


Func _Help($hMain) ; Help dialog
	Local $GM, $hGUIHelp = GUICreate('Help  —  v' & FileGetVersion(@ScriptFullPath), 400, 300, Default, Default, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX), Default, $hMain), _
	$sHelpDoc = 'Welcome to Steam Switch!' & @CRLF & _
		@CRLF & _
		'    This application lets you switch Steam profiles/logins without having to retype your password all the time, so long as you''ve normally logged in at least once before.' & @CRLF & _
		'    The application doesn''t store your passwords anywhere and never asks for them. Instead it relies on Steam''s built in password memory. The only data it actually stores is the' & _
		' list of usernames that you provide and the publicly available avatars of said users.' & @CRLF & _
		'    Theoretically you will only have to re-enter your password if Steam''s settings get lost or changed. I personally used the app for months without having to re-enter my password.' & @CRLF & _
		@CRLF & _
		'    To get started, click the Add/Edit Users button.' & @CRLF & _
		'    You will be presented with a text box. Type in the usernames you want to be able to switch between, one on each line, and hit OK.' & _
		' The program will close and reopen with all your chosen usernames and their avatars listed (they may take a few seconds to download).' & @CRLF & _
		'    Now click on the user you want to log in as.' & @CRLF & _
		'    If Steam is already running as that user it will simply open/refocus the Steam window. If Steam is running as another user, it will be closed gracefully and relaunched as the chosen user' & _
		' (if for some reason Steam will not close within 15 seconds you will be prompted to wait longer or to cancel).' & @CRLF & _
		'    If you want Steam to start in offline mode (or conversely online mode if it was last run in offline mode) then you can click the Extra Options button at the bottom of the window to see those options.' & _
		' This setting will restart Steam regardless of whether the chosen user is already logged in.' & @CRLF & _
		'    There is also a button in the Extra Options to reload avatars. This simply deletes all the stored avatars then relaunches the application which then re-downloads them.' & @CRLF & _
		@CRLF & _
		'Command line parameters:' & @CRLF & _
		'    /as, /AvatarSize=## -- Sets the size of the avatars displayed (Also adjusts username button/text size; default is 64).' & @CRLF & _
		'    /al, /AutoLogin=USERNAME -- Auto logs in the user, useful for shortcuts.' & @CRLF & _
		'    /of, /Offline -- Sets connection mode to Offline by default.' & @CRLF & _
		'    /on, /Online -- Sets connection mode to Online by default.' & @CRLF & _
		'    /nn, /NoNumbers -- Removes the prefixed shortcut numbers on each username.' & @CRLF & _
		'    /am, /AtMouse -- Starts UI centered on mouse position.' & @CRLF & _
		'    /ex, /Extra -- Starts UI with Extra Options panel revealed.' & @CRLF & _
		@CRLF & _
		'Any other command line parameters will be passed on to Steam itself. Some handy options are:' & @CRLF & _
		'    -silent -- Suppresses the dialog box that opens when you start steam.' & @CRLF & _
		'    -tenfoot -- Start Steam in Big Picture Mode.' & @CRLF & _
		'    -noverifyfiles -- Prevents the client from checking files integrity.' & @CRLF & _
		'    For a full list of parameters read here: https://developer.valvesoftware.com/wiki/Command_Line_Options#Steam_.28Windows.29' & @CRLF & _
		@CRLF & _
		'So for example, if you wanted to create a shortcut that started Steam as "FunFrank" in offline and Big Picture mode, you would create a shortcut to this target:' & @CRLF & _
		'    "' & @ScriptFullPath & '" /autoLogin=FunFrank /offline -tenfoot' & @CRLF & _
		@CRLF & _
		'Any and all data stored by the application is in AppData, if you want to "uninstall" then just delete ' & @ScriptName & ' and any files in the following folder:' & @CRLF & _
		'    ' & $CFG_PATH & @CRLF & _
		@CRLF & _
		'Author: therks@therks.com'

	GUICtrlCreateEdit($sHelpDoc, 0, 0, 400, 300, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	GUISetState()
	ControlSend($hGUIHelp, '', 'Edit1', '^{home}')

	Do
	Until GUIGetMsg() = $GUI_EVENT_CLOSE
	GUIDelete($hGUIHelp)
EndFunc

Func _AddUsers($hMain, $sPrefill) ; Add/edit users dialog
	Local $hGUIAdd, $ed_Users, $bt_OK, $bt_Cancel, $aAccel, $GM, $aContent[2], $hFile

	$hGUIAdd = GUICreate('Add Users', 300, 265, Default, Default, $WS_CAPTION, Default, $hMain)
	GUISetFont(9)
	GUICtrlCreateLabel('Usernames (1 per line):', 5, 5, 140, 25)
	$ed_Users = GUICtrlCreateEdit(StringAddCR($sPrefill), 0, 25, 150, 200)
	GUICtrlCreateLabel('Use Steam ACCOUNT names not DISPLAY names.' &@LF& 'Account names are restricted to A-Z, 0-9, and underscore (_), and have a minimum length of 3 characters.', 155, 25, 140, 175)
	$bt_OK = GUICtrlCreateButton('&OK', 5, 230, 145, 30)
		GUICtrlSetState(-1, $GUI_DEFBUTTON)
		GUICtrlSetTip(-1, 'Shortcut: Ctrl+Enter')
	$bt_Cancel = GUICtrlCreateButton('Cancel', 155, 230, 140, 30)
	_WinCenter($hGUIAdd, Default, Default, $hMain)
	GUISetState()

	Dim $aAccel = [ [ '^{enter}', $bt_OK ] ]
	GUISetAccelerators($aAccel)

	ControlSend($hGUIAdd, '', $ed_Users, '^{end}') ; Put cursor at end of list

	While 1
		$GM = GUIGetMsg()
		Switch $GM
			Case $bt_OK
				$aContent[0] = GUICtrlRead($ed_Users)
				$aContent[1] = StringRegExpReplace($aContent[0], '[^a-zA-Z0-9_\r\n]', '') ; Change any entries to be compatible Steam usernames
				If $aContent[0] <> $aContent[1] Then
					; If any entries were changed, replace the edit control contents
					GUICtrlSetData($ed_Users, $aContent[1])
				Else
					$hFile = FileOpen($USERS_FILE, 2)
					If $hFile <> -1 Then
						FileWrite($hFile, $aContent[0])
						FileClose($hFile)
						; Usernames added, launch new instance and exit current
						GUIDelete($hGUIAdd)
						GUISetState(@SW_HIDE, $hMain)
						ShellExecute(@AutoItExe, $CmdLineRaw)
						Exit @ScriptLineNumber
					Else
						If MsgBox(0x2114, 'Error', 'Cannot write to config file:' & @LF & StringReplace($USERS_FILE, @AppDataDir, '%AppData%') & @LF & @LF & 'Navigate to file location?', 0, $hGUIAdd) = 6 Then
							ShellExecute('explorer.exe', '/select,"' &$USERS_FILE& '"')
						EndIf
					EndIf
				EndIf
			Case $bt_Cancel, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hGUIAdd)
	ToolTip('')
EndFunc

Func _DeferredGUICtrlCreatePic($vData, $iX = Default, $iY = Default, $iW = Default, $iH = Default) ; Log Pic control data to create later
	If IsArray($vData) And UBound($vData) = 5 Then
		Return GUICtrlCreatePic($vData[0], $vData[1], $vData[2], $vData[3], $vData[4])
	Else
		Local $aReturn = [ $vData, $iX, $iY, $iW, $iH ]
		Return $aReturn
	EndIf
EndFunc

Func _WinGetClientOffset($hWnd) ; Get difference between window size and client size (titlebar, window borders, etc)
	Local $aPos = WinGetPos($hWnd), $aClient = WinGetClientSize($hWnd)
	Local $aReturn[2] = [ $aPos[2] - $aClient[0], $aPos[3] - $aClient[1] ]
	Return $aReturn
EndFunc

Func _WinCenter($hWnd, $iWidth = Default, $iHeight = Default, $vPosition = 'center') ; Size and center window at a location/target
	Local $aWinMove[4], $aWinGetPos = WinGetPos($hWnd), $aMouse = MouseGetPos()

	If $iWidth  = Default Then $iWidth  = $aWinGetPos[2]
	If $iHeight = Default Then $iHeight = $aWinGetPos[3]

	$aWinMove[2] = $iWidth
	$aWinMove[3] = $iHeight

	If IsHWnd($vPosition) Then
		$aWinGetPos = WinGetPos($vPosition)
		$aWinMove[0] = $aWinGetPos[0] + ($aWinGetPos[2] - $iWidth)/2
		$aWinMove[1] = $aWinGetPos[1] + ($aWinGetPos[3] - $iHeight)/2
	ElseIf $vPosition = 'screen' Then
		$aWinMove[0] = (@DesktopWidth - $iWidth)/2
		$aWinMove[1] = (@DesktopHeight - $iHeight)/2
	ElseIf $vPosition = 'mouse' Then
		$aWinMove[0] = $aMouse[0] - $iWidth/2
		$aWinMove[1] = $aMouse[1] - $iHeight/2
	EndIf

	If $aWinMove[0] < 0 Then $aWinMove[0] = 0
	If $aWinMove[1] < 0 Then $aWinMove[1] = 0
	If $aWinMove[0] + $aWinMove[2] > @DesktopWidth Then $aWinMove[0] = @DesktopWidth - $aWinMove[2]
	If $aWinMove[1] + $aWinMove[3] > @DesktopHeight Then $aWinMove[1] = @DesktopHeight - $aWinMove[3]

	WinMove($hWnd, '', $aWinMove[0], $aWinMove[1], $aWinMove[2], $aWinMove[3])
EndFunc

Func _Avatar($sUsername) ; Return path to user avatar if exists otherwise return @error and default avatar
	Local $sAvatar = $AVATAR_PATH & $sUsername & '.jpg'
	If FileExists($sAvatar) Then
		If FileGetSize($sAvatar) Then Return $sAvatar
		Return $NO_AVATAR
	Else
		Return SetError(1, 0, $DEFAULT_AV)
	EndIf
EndFunc

Func _CheckDownloads() ; Adlib function to check if avatar downloads have completed
	Local $bDone = True
	For $i = 1 To $USER_LIST[0][0]
		If $USER_LIST[$i][$UL_DOWNLOAD] Then
			$USER_LIST[$i][$UL_AVATAR] = _Avatar($USER_LIST[$i][$UL_USER])
			If @error Then
				$bDone = False
			Else
				$USER_LIST[$i][$UL_DOWNLOAD] = False
				GUICtrlSetImage($USER_LIST[$i][$UL_PIC_CTRL], $USER_LIST[$i][$UL_AVATAR])
			EndIf
		EndIf
	Next

	If $bDone Then AdlibUnRegister(_CheckDownloads)
EndFunc

Func _DownloadAvatars($sDownloadList = '') ; Start and monitor avatar downloading background process
	Local $sAvatarPath, $sAvatarURL, $sAvatarPattern = '(\Qhttps://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/\E.+?_medium\.jpg)', _
		$sProfilePage, $aRegEx, $sSearchHTML, $oJSON, $iDownload

	; If given a list this function launches a background process to handle downloads.
	; That background process calls this function with no list to actually start the downloads.
	If $sDownloadList Then
		If @Compiled Then
			ShellExecute(@AutoItExe, $DOWNLOAD_PARAM & ' ' & $sDownloadList)
		Else
			ShellExecute(@AutoItExe, StringFormat('"%s" %s %s', FileGetShortName(@ScriptFullPath), $DOWNLOAD_PARAM, $sDownloadList))
		EndIf
		Return AdlibRegister(_CheckDownloads, 100)
	Else
		For $i = 2 To $CmdLine[0] ; First param will always be $DOWNLOAD_PARAM
			$iDownload = 0 ; Reset download state to confirm whether download was successful
			$sAvatarURL = ''
			$sAvatarPath = $AVATAR_PATH & $CmdLine[$i] & '.jpg'
			$sProfilePage = BinaryToString(InetRead(StringFormat('https://steamcommunity.com/id/%s/?xml=1', $CmdLine[$i]), 1)) ; Read user profile XML page to string (will unfortunately fail if user has not set their "Custom URL")
			If $sProfilePage Then
				$aRegEx = StringRegExp($sProfilePage, $sAvatarPattern, 1) ; Look for the avatar string.
				If Not @error Then $sAvatarURL = $aRegEx[0]
			EndIf

			If Not $iDownload Then ; Try the search page method...
				; The Steam user search page uses Javascript & Ajax, so we can't just InetRead a simple result page. But we can InetRead the Ajax URL the search page calls on.
				; The Ajax URL requires a session ID, we can get this from the HTML of the search page (it's in a <script> tag).
				$sSearchHTML = BinaryToString(InetRead('https://steamcommunity.com/search/users/', 1)) ; Grab the search page HTML
				$aRegEx = StringRegExp($sSearchHTML, 'g_sessionID = "(.+?)";', 1) ; Look for the session ID
				If Not @error Then
					; Read the Ajax URL with the username we're searching and the session ID, and use the Json_Decode function (by Ward, see #include file)
					$oJSON = Json_Decode(BinaryToString(InetRead(StringFormat('https://steamcommunity.com/search/SearchCommunityAjax?text=%s&filter=users&sessionid=%s', $CmdLine[$i], $aRegEx[0]), 1)))
					If IsObj($oJSON) Then
						$aRegEx = StringRegExp($oJSON.Item('html'), $sAvatarPattern, 1) ; Find the avatar URL in the JSON html element
						If Not @error Then $sAvatarURL = $aRegEx[0] ; Set it for download!
					EndIf
				EndIf
			EndIf

			If $sAvatarURL Then $iDownload = InetGet($sAvatarURL, $sAvatarPath)

			; If nothing could be downloaded create an empty dummy file to prevent future attempts to redownload (we assume the avatar is unobtainable, so just stop trying)
			If Not $iDownload Then FileWrite($sAvatarPath, '')
		Next
	EndIf
EndFunc

Func WM_MOUSEWHEEL($hWnd, $iMsg, $wParam, $lParam) ; Handle mousewheel scroll to cycle through user page tabs
	If $hWnd = $WMG_HMAIN And BitAND(WinGetState($WMG_HMAIN), $WIN_STATE_ENABLED) Then
		Local $iCurr = _GUICtrlTab_GetCurSel($WMG_TAB)
		Local $iLast = _GUICtrlTab_GetItemCount($WMG_TAB)-1
		If _WinAPI_HiWord($wParam) > 0 Then
			$iCurr -= 1
			If $iCurr < 0 Then Return
		Else
			$iCurr += 1
			If $iCurr > $iLast Then Return
		EndIf
		_GUICtrlTab_ActivateTab($WMG_TAB, $iCurr)
	EndIf
EndFunc

Func WM_CONTEXTMENU($hWnd, $iMsg, $wParam, $lParam) ; Handle context menu to modify and pop it on user buttons
	If $hWnd = $WMG_HMAIN Then
		For $i = 1 To $USER_LIST[0][0]
			If $wParam = GUICtrlGetHandle($USER_LIST[$i][$UL_PIC_CTRL]) Or $wParam = GUICtrlGetHandle($USER_LIST[$i][$UL_BTN_CTRL]) Then
				GUICtrlSetData($WMG_MI_TITLE, $USER_LIST[$i][$UL_USER])
				If _SteamCheckOffline($USER_LIST[$i][$UL_USER]) Then
					GUICtrlSetState($WMG_MI_ONLINE, $GUI_UNCHECKED)
					GUICtrlSetState($WMG_MI_OFFLINE, $GUI_CHECKED)
				Else
					GUICtrlSetState($WMG_MI_ONLINE, $GUI_CHECKED)
					GUICtrlSetState($WMG_MI_OFFLINE, $GUI_UNCHECKED)
				EndIf
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($WMG_ME_MENU), $WMG_HMAIN)
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc
