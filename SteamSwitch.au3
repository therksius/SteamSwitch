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
Global $WMG_HMAIN, $WMG_TAB, $WMG_CONTEXT, $WMG_CONTEXT_TITLE ; Window Message Globals
Global Enum $UL_USER, $UL_AVATAR, $UL_DOWNLOAD, $UL_PIC_CTRL, $UL_BTN_CTRL, $UL_UBOUND
Global $USER_LIST[1][$UL_UBOUND]

Main()

Func Main()
	; Create config folders
	If Not FileExists($AVATAR_PATH) Then DirCreate($AVATAR_PATH)

	; Install waiting animation and default avatar
	FileInstall('Waiting.ani', $WAIT_ANIM, 1)
	FileInstall('SteamSwitch_None.gif', $NO_AVATAR)
	FileInstall('SteamSwitch_Default.gif', $DEFAULT_AV)

	If $CmdLine[0] And $CmdLine[1] = $DOWNLOAD_PARAM Then Exit _DownloadAvatars() *0+@ScriptLineNumber ; Run downloader and exit

	Local $aUsernames, $sUsersFilter, $aTabRect, $iButtonMax, $iButtonPos, $iSteamPID, $aWinOffset, _
		$sDownloadList, $sCmdPassthru, $bNoNumbers, $bAutoExpand, $sAutoLogin, $iAvatarSize = 64, $vCenterAt = 'screen', _
		$iTrackWidth = 210, $iTrackHeight = 0, $iWinWidth, $iWinHeight, $iWinHeightExpand, $aCtrlPos, $sButtonText, $iOfflineMode = 0, $aAccel, _
		$hGUIParent, $lb_SteamRunning, $bt_OpenSteam, $bt_CloseSteam, $bt_GoOnline, $bt_GoOffline, $mi_Online, $mi_Offline, $mi_ReloadAvatar, $aRange_UserBtns[2], _
		$bt_AddMore, $bt_Extra, $aRange_ExtraCtrls[2], $ra_OfflineDef, $ra_OfflineNo, $ra_OfflineYes, $bt_ReloadAvatars, $lb_Help, $GM

	; Cannot find steam installation so quit
	If Not $STEAM_EXE Then
		Exit MsgBox(0x30, 'SteamSwitch', 'Could not find Steam registry key.' & @LF & 'Please ensure Steam has been installed and started at least once before using this program.') *0+@ScriptLineNumber
	EndIf

	; Command line switches:
	If $CmdLine[0] Then
		#cs
			/avatarSize=##
			/autoLogin=username
			/noNumbers
			/offline
			/online
			/extra
			/atMouse
		#ce
		For $i = 1 To $CmdLine[0]
			If StringRegExp($CmdLine[$i], '(?i)/avatarSize=') = 1 Then
				$iAvatarSize = Int(StringSplit($CmdLine[$i], '=')[2])
			ElseIf StringInStr($CmdLine[$i], '/autoLogin=') = 1 Then
				$sAutoLogin = StringSplit($CmdLine[$i], '=')[2]
			ElseIf $CmdLine[$i] = '/online' Then
				$iOfflineMode = 1
			ElseIf $CmdLine[$i] = '/offline' Then
				$iOfflineMode = 2
			ElseIf $CmdLine[$i] = '/noNumbers' Then
				$bNoNumbers = True
			ElseIf $CmdLine[$i] = '/atMouse' Then
				$vCenterAt = 'mouse'
			ElseIf $CmdLine[$i] = '/extra' Then
				$bAutoExpand = True
			Else
				If StringInStr($CmdLine[$i], ' ') Then
					$CmdLine[$i] = '"' & $CmdLine[$i] & '"'
				EndIf
				$sCmdPassthru &= ' ' & $CmdLine[$i]
			EndIf
		Next
	EndIf

	If $sAutoLogin Then Exit _SteamLogin(0, $sAutoLogin, $iOfflineMode, $sCmdPassthru) *0+@ScriptLineNumber

	Opt('GUIResizeMode', $GUI_DOCKALL) ; Disable control drifting

	#region - Get user list and create array
		$aUsernames = FileReadToArray($USERS_FILE)
		For $i = 0 To UBound($aUsernames)-1
			If StringRegExp($aUsernames[$i], '^[a-zA-Z0-9_]{3,}$') Then $sUsersFilter &= $aUsernames[$i] & @LF
		Next
		$aUsernames = StringSplit(StringStripWS($sUsersFilter, 3), @LF)

		If Not $aUsernames[1] Then
			$aUsernames[0] = 0
		Else
			ReDim $USER_LIST[$aUsernames[0]+1][$UL_UBOUND]
			$USER_LIST[0][0] = $aUsernames[0]
		EndIf
	#endregion

	; ====================================================================================================================
	#region - Build main GUI
		$hGUIParent = GUICreate('') ; Hidden parent to hide taskbar button
		$WMG_HMAIN = GUICreate('Steam Switcher -- F1 for help', 10, 10, Default, Default, $WS_SYSMENU, $WS_EX_TOPMOST)

		; Show banner if Steam is running
		If ProcessExists('steam.exe') Then
			$lb_SteamRunning = GUICtrlCreateLabel('Logged in as ' & $CURR_USER & ' (' & ( _SteamCheckOffline($STEAM_CFG_PATH, $CURR_USER) ? 'Offline' : 'Online' ) & ')', 0, 0, 10, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
				GUICtrlSetFont(-1, 11, 700)
				GUICtrlSetBkColor(-1, 0x1a3f56)
				GUICtrlSetColor(-1, 0x66c0f4)
			$bt_OpenSteam  = GUICtrlCreateButton('Open Steam',  0, 20, 80, 20)
			$bt_CloseSteam = GUICtrlCreateButton('Close Steam', 0, 20, 80, 20)
			$bt_GoOnline   = GUICtrlCreateButton('Go Online',   0, 20, 80, 20)
			$bt_GoOffline  = GUICtrlCreateButton('Go Offline',  0, 20, 80, 20)
			; If current profile is offline show the Online button and vice versa
			If _SteamCheckOffline($STEAM_CFG_PATH, $CURR_USER) Then
				GUICtrlSetState($bt_GoOffline, $GUI_HIDE)
			Else
				GUICtrlSetState($bt_GoOnline, $GUI_HIDE)
			EndIf
			$iTrackHeight = 40
		EndIf

		$iButtonMax = $aUsernames[0]
		If $iAvatarSize * $iButtonMax > $MAX_HEIGHT Then
			$iButtonMax = Int($MAX_HEIGHT / $iAvatarSize)
			$WMG_TAB = GUICtrlCreateTab(0, $iTrackHeight, 100, 100, $TCS_FIXEDWIDTH)
			_GUICtrlTab_InsertItem($WMG_TAB, 0, '')
			$aTabRect = _GUICtrlTab_GetItemRect($WMG_TAB, 0)
			_GUICtrlTab_DeleteItem($WMG_TAB, 0)
			$iTrackHeight += $aTabRect[3]
		EndIf
		$iButtonPos = $iTrackHeight

		$WMG_CONTEXT = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
			$WMG_CONTEXT_TITLE = GUICtrlCreateMenuItem('-', $WMG_CONTEXT)
				GUICtrlSetState(-1, BitOR($GUI_DEFBUTTON, $GUI_DISABLE))
			GUICtrlCreateMenuItem('', $WMG_CONTEXT)
			$mi_Online = GUICtrlCreateMenuItem('Start O&nline', $WMG_CONTEXT)
			$mi_Offline = GUICtrlCreateMenuItem('Start O&ffline', $WMG_CONTEXT)
			$mi_ReloadAvatar = GUICtrlCreateMenuItem('&Reload Avatar', $WMG_CONTEXT)

		GUIRegisterMsg($WM_CONTEXTMENU, WM_CONTEXTMENU)

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
			$USER_LIST[$i][$UL_PIC_CTRL] = GUICtrlCreatePic($USER_LIST[$i][$UL_AVATAR], 0, $iButtonPos, $iAvatarSize, $iAvatarSize)

			; Display (or not) prefix numbers for buttons
			If $bNoNumbers Then
				$sButtonText = ' ' & $aUsernames[$i] & ' '
			Else
				$sButtonText = ($i < 10 ? ' &' & $i : ($i = 10 ? ' 1&0' : ' ' & $i)) & ': ' & $aUsernames[$i] & ' '
			EndIf

			$USER_LIST[$i][$UL_BTN_CTRL] = GUICtrlCreateButton($sButtonText, $iAvatarSize, $iButtonPos, Default, $iAvatarSize, BitOR($BS_FLAT, $BS_LEFT))

			GUISetFont(8)
			GUISetFont($iAvatarSize * 0.375)
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

		GUICtrlSetPos($lb_SteamRunning, Default,        Default, $iWinWidth)
		GUICtrlSetPos($bt_OpenSteam,    Default,        Default, $iWinWidth/3)
		GUICtrlSetPos($bt_CloseSteam,   $iWinWidth/3,   Default, $iWinWidth/3)
		GUICtrlSetPos($bt_GoOnline,     $iWinWidth/3*2, Default, $iWinWidth/3)
		GUICtrlSetPos($bt_GoOffline,    $iWinWidth/3*2, Default, $iWinWidth/3)

		If $WMG_TAB Then
			GUICtrlCreateTabItem('')
			GUICtrlSetPos($WMG_TAB, Default, Default, $iWinWidth, $aTabRect[3])
			GUIRegisterMsg($WM_MOUSEWHEEL, WM_MOUSEWHEEL)
		EndIf


		$iTrackHeight += $iButtonMax * $iAvatarSize ; Get the current height of the collective controls

		GUISetFont(9) ; Reset font to a regular size

		$bt_AddMore = GUICtrlCreateButton('&Add/Edit Users', 0, $iTrackHeight, $iWinWidth, 25)
			$iTrackHeight += 25

		$bt_Extra = GUICtrlCreateButton('E&xtra options', 0, $iTrackHeight, $iWinWidth, 20)
			GUICtrlSetFont(-1, 8)
			$iTrackHeight += 20

		$iWinHeight = $iTrackHeight ; Record height after Extra button for window

		; ====================================================================================================================
		#region - Extra options controls
			$aRange_ExtraCtrls[0] = GUICtrlCreateDummy() ; Start range for "extra" controls
				$iTrackHeight -= 15 ; Reduce $iTrackHeight a bit cus this group overlaps the "Extra" button
				GUICtrlCreateGroup('Connection Mode:', 5, $iTrackHeight, $iWinWidth-10, 45)
					$iTrackHeight += 20

				$ra_OfflineDef = GUICtrlCreateRadio('&Default', 10, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Uses last login connection mode')
				$ra_OfflineNo = GUICtrlCreateRadio('O&nline', 75, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Start in online mode')
				$ra_OfflineYes = GUICtrlCreateRadio('O&ffline', 140, $iTrackHeight, 60, 15)
					GUICtrlSetTip(-1, 'Start in offline mode')
					$iTrackHeight += 25
					GUICtrlSetState($ra_OfflineDef + $iOfflineMode, $GUI_CHECKED) ; Default check proper radio according to $iOfflineMode

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

		For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1] ; Hide the extra controls
			GUICtrlSetState($i, $GUI_HIDE)
		Next

		Local $aAccel = [ [ '{f1}', $lb_Help ] ]
		GUISetAccelerators($aAccel)

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

	If $sDownloadList Then
		_DownloadAvatars($sDownloadList)
	EndIf

	While WinActive($WMG_HMAIN)

		$GM = GUIGetMsg()
		Switch $GM
			Case $GUI_EVENT_NONE
				; Dummy case to catch uninitialized ctrl variables
			Case $bt_OpenSteam
				_SteamLogin($WMG_HMAIN)
			Case $bt_CloseSteam
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				If _SteamClose($WMG_HMAIN) Then
					GUISetState(@SW_HIDE, $WMG_HMAIN)
					ShellExecute(@AutoItExe, $CmdLineRaw)
					Exit @ScriptLineNumber
				EndIf
				GUISetState(@SW_ENABLE, $WMG_HMAIN)
				WinActivate($WMG_HMAIN)

			Case $bt_GoOnline
				_SteamLogin($WMG_HMAIN, $CURR_USER, 1, $sCmdPassthru)
			Case $bt_GoOffline
				_SteamLogin($WMG_HMAIN, $CURR_USER, 2, $sCmdPassthru)
			Case $mi_Online
				_SteamLogin($WMG_HMAIN, GUICtrlRead($WMG_CONTEXT_TITLE, 1), 1, $sCmdPassthru)
			Case $mi_Offline
				_SteamLogin($WMG_HMAIN, GUICtrlRead($WMG_CONTEXT_TITLE, 1), 2, $sCmdPassthru)
			Case $mi_ReloadAvatar
				For $i = 1 To $USER_LIST[0][0]
					If $USER_LIST[$i][$UL_USER] = GUICtrlRead($WMG_CONTEXT_TITLE, 1) Then
						GUICtrlSetImage($USER_LIST[$i][$UL_PIC_CTRL], $DEFAULT_AV)
						$USER_LIST[$i][$UL_DOWNLOAD] = True
						FileDelete($AVATAR_PATH & $USER_LIST[$i][$UL_USER] & '.jpg')
						_DownloadAvatars($USER_LIST[$i][$UL_USER])
;~ 						ExitLoop
					EndIf
				Next
			Case $aRange_UserBtns[0] To $aRange_UserBtns[1]
				For $i = 1 To $USER_LIST[0][0]
					If $GM = $USER_LIST[$i][$UL_PIC_CTRL] Or $GM = $USER_LIST[$i][$UL_BTN_CTRL] Then

						Switch true
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
				_AddUsers($WMG_HMAIN, $sUsersFilter)
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
				GUISetState(@SW_HIDE, $WMG_HMAIN)
				DirRemove($AVATAR_PATH, 1)
				ShellExecute(@AutoItExe, $CmdLineRaw)
				Exit @ScriptLineNumber

			Case $GUI_EVENT_CLOSE
				Exit @ScriptLineNumber
		EndSwitch
	WEnd
EndFunc

Func _SteamClose($hMain) ; WIP
	Local $hGUIWait, $lb_Wait, $bt_Cancel, $GM, $iSteamPID, $iTimer, $iCountdown, _
		$iMsgBox, $sMsgBox = 'Failed to shutdown properly.' & @LF & @LF & _
		'Force shutdown?' & @LF & @LF & _
		'Yes:	Kill process (may result in lost data).' & @LF & _
		'No:	Continue waiting for normal shutdown.' & @LF & _
		'Cancel:	Stop trying to shutdown Steam.'

	$hGUIWait = GUICreate('', 200, 110, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hMain)
	$lb_Wait = GUICtrlCreateLabel('Closing Steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($WAIT_ANIM, 0, (200-32)/2, 40, 32, 32)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 70, 85, 60, 20)

	$iSteamPID = ProcessExists('steam.exe')
	If $iSteamPID Then
		ShellExecute($STEAM_EXE, '-shutdown')
		GUISetState(@SW_SHOW, $hGUIWait)

		$iTimer = TimerInit()
		GUICtrlSetData($lb_Wait, 'Closing Steam...')
		$iCountdown = 15
		While ProcessExists($iSteamPID)
			$GM = GUIGetMsg()
			If $GM = $bt_Cancel Or $GM = $GUI_EVENT_CLOSE Then
				ExitLoop
			EndIf

			If TimerDiff($iTimer) > 1000 Then
				$iCountdown -= 1
				$iTimer = TimerInit()

				If $iCountdown <= 0 Then
					$iMsgBox = MsgBox(0x2213, 'Error', $sMsgBox, 0, $hMain); Yes: 6, No: 7, Cancel: 2
					If $iMsgBox = 6 Then
						If MsgBox(0x134, 'Notice', 'Are you sure you want to force close steam.exe? This may result in lost data if Steam is still working.', 0, $hMain) = 6 Then; Yes: 6, No: 7
							ProcessClose($iSteamPID)
							$iCountdown = 10
							GUICtrlSetData($lb_Wait, 'Closing Steam...')
							ContinueLoop
						EndIf
					ElseIf $iMsgBox = 7 Then
						ShellExecute($STEAM_EXE, '-shutdown')
						$iCountdown = 10
						GUICtrlSetData($lb_Wait, 'Closing Steam...')
						ContinueLoop
					Else
						ExitLoop
					EndIf
				ElseIf $iCountdown <= 10 Then
					GUICtrlSetData($lb_Wait, 'Closing Steam...' & @LF & '(timeout ' & $iCountdown & ' seconds)')
				EndIf
			EndIf
		WEnd
	EndIf

	GUIDelete($hGUIWait)
	Return Not ProcessExists('steam.exe')
EndFunc

Func _SteamLogin($hMain, $sUsername = $CURR_USER, $iOfflineMode = 0, $sCmdPassthru = '')
	Local $hGUIWait, $lb_Wait, $bt_Cancel, $GM, $iSteamPID, $iTimer, $aWait[2]

	$hGUIWait = GUICreate('', 200, 110, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hMain)
	$lb_Wait = GUICtrlCreateLabel('Closing steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($WAIT_ANIM, 0, (200-32)/2, 40, 32, 32)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 70, 85, 60, 20)

	If $CURR_USER <> $sUsername Or $iOfflineMode <> 0 Then
		GUISetState(@SW_HIDE, $hMain)
		If Not _SteamClose($hMain) Then
			GUISetState(@SW_SHOW, $hMain)
			Return
		EndIf

		RegWrite($STEAM_REG, $REG_USERNAME, 'REG_SZ', $sUsername)
	EndIf
	RegWrite($STEAM_REG, $REG_REMPASS, 'REG_DWORD', 1)

	Switch $iOfflineMode
		Case 1
			_SteamConfig($STEAM_CFG_PATH, $sUsername, False)
		Case 2
			_SteamConfig($STEAM_CFG_PATH, $sUsername, True)
	EndSwitch

	ShellExecute($STEAM_EXE, $sCmdPassthru)
	Exit @ScriptLineNumber
EndFunc

Func _SteamCheckOffline($sConfigPath, $sUser)
	Return StringRegExp(FileRead($sConfigPath), '(?i)"AccountName"\h*"' & $sUser & '"[^}]+"WantsOfflineMode"\h*"1"')
EndFunc

Func _SteamConfig($sConfigPath, $sUser, $bOffline)
	Local $sConfigData, $sNewConfig, $aSegments, $aSplitLines, $hFile = -1

	$sConfigData = FileRead($sConfigPath)

	$aSegments = StringRegExp($sConfigData, '(?si)^(.*{)(.*?"AccountName"\h*"'& $sUser & '".*?)(}.*)$', 1) ; Isolate user segment for rewrite.
	If UBound($aSegments) = 3 Then
		; Seems AccountName and Timestamp are the only things required. If Timestamp is set low enough (or missing) Steam will prompt for password on launch.
		$sNewConfig = StringFormat('\n\t\t"AccountName"\t\t"%s"\n\t\t"Timestamp"\t\t"%d"\n\t', $sUser, _DateDiff('s', '1970/01/01 00:00:00', _NowCalc()))

		; The SkipOfflineModeWarning should, as it implies skip that prompt on launch but it seems to be inconsistent lately (can't figure out why).
		If $bOffline Then $sNewConfig &= StringFormat('\t"WantsOfflineMode"\t\t"1"\n\t\t"SkipOfflineModeWarning"\t\t"1"\n\t')

		; Combine new config with outer segments.
		$sNewConfig = $aSegments[0] & $sNewConfig & $aSegments[2]

		$hFile = FileOpen($sConfigPath, 2)
		If $hFile <> -1 Then
			FileWrite($hFile, $sNewConfig)
			FileClose($hFile)
			Return 1
		EndIf
	EndIf
EndFunc


Func _Help($hMain)
	Local $hGUIHelp = GUICreate('Help -- v' & FileGetVersion(@ScriptFullPath), 400, 300, Default, Default, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX), Default, $hMain), $GM, _
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
		'    /AvatarSize=## -- Sets the size of the avatars displayed (Also adjusts username text size; default is 64).' & @CRLF & _
		'    /AutoLogin=USERNAME -- Auto logs in the user, useful for shortcuts.' & @CRLF & _
		'    /Offline -- Sets connection mode to Offline by default.' & @CRLF & _
		'    /Online -- Sets connection mode to Online by default.' & @CRLF & _
		'    /NoNumbers -- Removes the prefixed shortcut numbers on each username.' & @CRLF & _
		'    /AtMouse -- Starts UI centered on mouse position.' & @CRLF & _
		'    /Extra -- Starts UI with extra options revealed.' & @CRLF & _
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
		$GM = GUIGetMsg()
	Until $GM = $GUI_EVENT_CLOSE
	GUIDelete($hGUIHelp)
EndFunc

Func _AddUsers($hMain, $sPrefill)
	Local $hGUIAdd, $ed_Users, $bt_OK, $bt_Cancel, $GM, $aContent[2], $hFile

	$hGUIAdd = GUICreate('Add Users', 200, 250, Default, Default, $WS_CAPTION, Default, $hMain)
	GUISetFont(9)
	GUICtrlCreateLabel('One username per line.' &@LF& '(Min. 3 chars, a-z, A-Z, 0-9, _)', 5, 5, 190, 40)
	$ed_Users = GUICtrlCreateEdit(StringAddCR($sPrefill), 0, 40, 200, 180)
	$bt_OK = GUICtrlCreateButton('&OK', 0, 220, 100, 30)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 100, 220, 100, 30)
	_WinCenter($hGUIAdd, Default, Default, $hMain)
	GUISetState()

	ControlSend($hGUIAdd, '', $ed_Users, '^{end}')

	While 1
		$GM = GUIGetMsg()
		Switch $GM
			Case $bt_OK
				$aContent[0] = GUICtrlRead($ed_Users)
				$aContent[1] = StringRegExpReplace($aContent[0], '[^a-zA-Z0-9_\r\n]', '')
				If $aContent[0] <> $aContent[1] Then
					GUICtrlSetData($ed_Users, $aContent[1])
				Else
					$hFile = FileOpen($USERS_FILE, 2)
					If $hFile <> -1 Then
						FileWrite($hFile, $aContent[0])
						FileClose($hFile)
						GUIDelete($hGUIAdd)
						GUISetState(@SW_HIDE, $hMain)
						ShellExecute(@AutoItExe, $CmdLineRaw)
						Exit @ScriptLineNumber
					Else
						If MsgBox(0x2114, 'Error', 'Cannot write to config file:' & @LF & $USERS_FILE & @LF & @LF & 'Navigate to file location?', 0, $hGUIAdd) = 6 Then
							ShellExecute('explorer.exe', '/select,"' &$USERS_FILE& '"')
						EndIf
					EndIf
					ExitLoop
				EndIf
			Case $bt_Cancel, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hGUIAdd)
EndFunc

Func _WinGetClientOffset($hWnd)
	Local $aPos = WinGetPos($hWnd), $aClient = WinGetClientSize($hWnd)
	Local $aReturn[2] = [ $aPos[2] - $aClient[0], $aPos[3] - $aClient[1] ]
	Return $aReturn
EndFunc

Func _WinCenter($hWnd, $iWidth = Default, $iHeight = Default, $vPosition = 'center')
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

Func _Avatar($sUsername)
	Local $sAvatar = $AVATAR_PATH & $sUsername & '.jpg'
	If FileExists($sAvatar) Then
		Return $sAvatar
	Else
		Return SetError(1, 0, $DEFAULT_AV)
	EndIf
EndFunc

Func _CheckDownloads()
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

Func _DownloadAvatars($sDownloadList = '')
	Local $sAvatarPath, $sProfilePage, $aRegEx, $iDownload

	If $sDownloadList Then
		If @Compiled Then
			ShellExecute(@AutoItExe, $DOWNLOAD_PARAM & ' ' & $sDownloadList)
		Else
			ShellExecute(@AutoItExe, StringFormat('"%s" %s %s', FileGetShortName(@ScriptFullPath), $DOWNLOAD_PARAM, $sDownloadList))
		EndIf
		Return AdlibRegister(_CheckDownloads, 100)
	EndIf

	For $i = 2 To $CmdLine[0]
		$iDownload = 0
		$sAvatarPath = $AVATAR_PATH & $CmdLine[$i] & '.jpg'
		$sProfilePage = BinaryToString(InetRead('https://steamcommunity.com/id/' & $CmdLine[$i] & '/?xml=1', 1))
		If $sProfilePage Then
			$aRegEx = StringRegExp($sProfilePage, '(\Qhttps://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/\E.+?_medium\.jpg)', 1)
			If Not @error Then
				$iDownload = InetGet($aRegEx[0], $sAvatarPath)
			EndIf
		EndIf

		If Not $iDownload And Not FileCreateNTFSLink($NO_AVATAR, $sAvatarPath) Then
			FileCopy($NO_AVATAR, $sAvatarPath)
		EndIf
	Next
EndFunc

Func WM_MOUSEWHEEL($hWnd, $iMsg, $wParam, $lParam)
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

Func WM_CONTEXTMENU($hWnd, $iMsg, $wParam, $lParam)
	If $hWnd = $WMG_HMAIN Then
		For $i = 1 To $USER_LIST[0][0]
			If $wParam = GUICtrlGetHandle($USER_LIST[$i][$UL_PIC_CTRL]) Or $wParam = GUICtrlGetHandle($USER_LIST[$i][$UL_BTN_CTRL]) Then
				GUICtrlSetData($WMG_CONTEXT_TITLE, $USER_LIST[$i][$UL_USER])
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($WMG_CONTEXT), $WMG_HMAIN)
			EndIf
		Next
	EndIf
EndFunc
