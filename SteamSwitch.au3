#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=SteamSwitch.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=SteamSwitch
#AutoIt3Wrapper_Res_Description=SteamSwitch
#AutoIt3Wrapper_Res_Fileversion=1.5.4.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_ProductName=SteamSwitch
#AutoIt3Wrapper_Res_ProductVersion=1.5.4
#AutoIt3Wrapper_Res_CompanyName=therkSoft
#AutoIt3Wrapper_Res_LegalCopyright=Robert Saunders
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Run_Before=IF "%fileversion%" NEQ "" COPY "%in%" "%scriptdir%\%scriptfile% (v%fileversion%).au3"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <WinAPISys.au3>
#include <WinAPIProc.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <TabConstants.au3>
#include <GuiTab.au3>
#include <GuiMenu.au3>
#include <Date.au3>

#include 'Json.au3' ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn/

Opt('MustDeclareVars', 1)

Global Const $DEBUG = False
Global Const $STEAM_REG = 'HKCU\Software\Valve\Steam'
Global Const $STEAM_EXE = StringReplace(RegRead($STEAM_REG, 'SteamExe'), '/', '\')
Global Const $STEAM_PATH = StringReplace(RegRead($STEAM_REG, 'SteamPath'), '/', '\')
Global Const $STEAM_CFG_PATH = $STEAM_PATH & '\config\loginusers.vdf'
Global Const $REG_USERNAME = 'AutoLoginUser'
Global Const $REG_REMPASS = 'RememberPassword'
Global Const $CURR_USER = RegRead($STEAM_REG, $REG_USERNAME)
Global Const $CFG_PATH = @AppDataDir & '\therkSoft\SteamSwitch\'
Global Const $HELP_FILE = $CFG_PATH & 'help.txt'
Global Const $USERS_FILE = $CFG_PATH & 'userlist.cfg'
Global Const $WAIT_ANIM = $CFG_PATH & 'waiting.ani'
Global Const $AVATAR_PATH = $CFG_PATH & 'avatars\'
Global Const $NO_AVATAR = $AVATAR_PATH & '.none.gif'
Global Const $DEFAULT_AV = $AVATAR_PATH & '.default.gif'
Global Const $MAX_WIDTH = Int(@DesktopWidth *.8)
Global Const $MAX_HEIGHT = Int(@DesktopHeight * 0.7)
Global Const $UNFOCUS_TIMEOUT = 100
Global Const $DOWNLOAD_PARAM = '/download'

Global $WMG_HMAIN, $WMG_TAB, $WMG_ME_MENU, $WMG_MI_TITLE, $WMG_MI_ONLINE, $WMG_MI_OFFLINE ; Window Message Globals
Global Enum $UL_USER, $UL_ISOFFLINE, $UL_AVATAR, $UL_DOWNLOAD, $UL_PIC_CTRL, $UL_BTN_CTRL, $UL_LBL_OFFLINE, $UL_UBOUND
Global $USER_LIST[1][$UL_UBOUND]

Main()

Func Main()
	Local $aUsernames, $sUsersFiltered, $aTabRect, $iButtonMax, $iButtonPos, $aWinOffset, $aGetPos, $iActiveTimeout, $sDownloadList, $aRegEx, _
		$iOfflineMode = 0, $bDoNumbers, $vCenterAt = 'screen', $bAutoExpand, $iAvatarSize = 64, $iOfflineBorder = 2, $sAutoLogin, $sCmdPassthru, _ ; Param vars
		$sButtonText, $sOfflineText, $aAccel, $iTrackWidth = 250, $iTrackHeight = 0, $iWinWidth, $iWinHeight, $iWinHeightExpand, _
		$bt_Banner, $cm_Banner, $mi_OpenSteam, $mi_CloseSteam, $mi_GoOnline, $mi_GoOffline, $mi_ReloadAvatar, $aRange_UserBtns[2], _ ; GUI vars
		$bt_Manage, $bt_Extra, $aRange_ExtraCtrls[2], $ra_OfflineDef, $ra_OfflineNo, $ra_OfflineYes, $bt_ReloadAvatars, $bt_AvatarFolder, $in_SteamParams, $lb_Help, $GM

	; Cannot find steam installation so quit
	If Not $STEAM_EXE Then
		Exit @ScriptLineNumber+0*MsgBox(0x10, 'SteamSwitch', 'Could not read Steam registry key.' & @LF & 'Please ensure Steam has been installed and started at least once before using this program.')
	EndIf

	; Create appdata folders
	If Not FileExists($AVATAR_PATH) Then DirCreate($AVATAR_PATH)

	_Migrate() ; Migrate old config files to new locations

	; Install waiting animation and default avatar
	FileInstall('help.txt', $HELP_FILE, 1)
	FileInstall('SteamSwitch_None.gif', $NO_AVATAR)
	FileInstall('SteamSwitch_Default.gif', $DEFAULT_AV)

	; Run downloader and exit. Has to be after FileInstall lines to make sure default avatars get replaced after a full avatar reload.
	If $CmdLine[0] And $CmdLine[1] = $DOWNLOAD_PARAM Then Exit @ScriptLineNumber+0*_DownloadAvatars()

	; Command line switches:
	; /online, /offline, /doNumbers, /atMouse, /extra, /avatarSize=##, /indicator=##, /autoLogin=username
	If $CmdLine[0] Then
		For $i = 1 To $CmdLine[0]
			Switch $CmdLine[$i]
				Case '/online', '/on'
					$iOfflineMode = 1
				Case '/offline', '/of'
					$iOfflineMode = 2
				Case '/doNumbers', '/dn'
					$bDoNumbers = True
				Case '/atMouse', '/am'
					$vCenterAt = 'mouse'
				Case '/extra', '/ex'
					$bAutoExpand = True
				Case Else
					$aRegEx = StringRegExp($CmdLine[$i], '^/(?i:avatarSize|as)=(\d+)', 1)
					If Not @error Then
						$iAvatarSize = Int($aRegEx[0])
						ContinueLoop
					EndIf

					$aRegEx = StringRegExp($CmdLine[$i], '^/(?i:indicator|in)=(\d+)', 1)
					If Not @error Then
						$iOfflineBorder = Int($aRegEx[0])
						ContinueLoop
					EndIf

					$aRegEx = StringRegExp($CmdLine[$i], '^/(?i:autoLogin|al)=(.+)', 1)
					If Not @error Then
						$sAutoLogin = $aRegEx[0]
						ContinueLoop
					EndIf

					; Any command that isn't interpreted by this app gets passed through to Steam
					If StringInStr($CmdLine[$i], ' ') Then
						$CmdLine[$i] = '"' & $CmdLine[$i] & '"'
					EndIf
					$sCmdPassthru &= ' ' & $CmdLine[$i]
			EndSwitch
		Next
	EndIf

	; Auto login, jump straight to login function and exit
	If $sAutoLogin Then Exit @ScriptLineNumber+0*_SteamLogin($sAutoLogin, $iOfflineMode, $sCmdPassthru)

	Opt('GUIResizeMode', $GUI_DOCKALL) ; Prevent control drifting

	#region - Get user list and create array
		$aUsernames = FileReadToArray($USERS_FILE)
		For $i = 0 To UBound($aUsernames)-1
			; Filter entries to only valid Steam usernames (alphanumeric, underscore, and minimum 3 char)
			; This string ($sUsersFiltered) is also used later to pre-fill the Manage Users dialog.
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
		$WMG_HMAIN = GUICreate('Steam Switcher', 10, 10, Default, Default, $WS_SYSMENU, $WS_EX_TOPMOST)

		; Create context menu that will be used for the user buttons
		$WMG_ME_MENU = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
			$WMG_MI_TITLE = GUICtrlCreateMenuItem('-', $WMG_ME_MENU)
				GUICtrlSetState(-1, $GUI_DEFBUTTON)
			GUICtrlCreateMenuItem('', $WMG_ME_MENU)
			$WMG_MI_ONLINE = GUICtrlCreateMenuItem('Start O&nline', $WMG_ME_MENU)
			$WMG_MI_OFFLINE = GUICtrlCreateMenuItem('Start O&ffline', $WMG_ME_MENU)
			$mi_ReloadAvatar = GUICtrlCreateMenuItem('&Reload Avatar', $WMG_ME_MENU)
		GUIRegisterMsg($WM_CONTEXTMENU, WM_CONTEXTMENU)

		; Show banner if Steam is running
		If _SteamPID() Then
			$bt_Banner = GUICtrlCreateButton('&Steam running as ' & $CURR_USER & (_SteamCheckOffline($CURR_USER) ? ' (Offline)' : ''), 0, 0, 10, 25)
				GUICtrlSetFont(-1, 11, 700)
				GUICtrlSetBkColor(-1, 0x1a3f56)
				GUICtrlSetColor(-1, 0x66c0f4)
				GUICtrlSetCursor(-1, 0)
				GUICtrlSetTip(-1, 'Click for menu (Ctrl+S)')
			$iTrackHeight = 25

			; Banner context menu
			$cm_Banner = GUICtrlCreateContextMenu($bt_Banner)
			; If current profile is offline show the Online button and vice versa
				$mi_OpenSteam  = GUICtrlCreateMenuItem('&Open Steam Window',  $cm_Banner)
				$mi_CloseSteam = GUICtrlCreateMenuItem('&Close Steam', $cm_Banner)
				If _SteamCheckOffline($CURR_USER) Then
					$mi_GoOffline  = GUICtrlCreateMenuItem('&Restart Steam',  $cm_Banner)
					GUICtrlCreateMenuItem('',  $cm_Banner)
					$mi_GoOnline   = GUICtrlCreateMenuItem('Go O&nline',   $cm_Banner)
				Else
					$mi_GoOnline   = GUICtrlCreateMenuItem('&Restart Steam',   $cm_Banner)
					GUICtrlCreateMenuItem('',  $cm_Banner)
					$mi_GoOffline  = GUICtrlCreateMenuItem('Go O&ffline',  $cm_Banner)
				EndIf
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

		; ====================================================================================================================
		#region - User buttons
			GUISetFont($iAvatarSize * 0.375) ; Default font (for buttons) proportional to the avatar size
			$aRange_UserBtns[0] = GUICtrlCreateDummy() ; Start control range for user buttons
			For $i = 1 To $aUsernames[0]
				If Mod($i, $iButtonMax) == 1 Then
					GUICtrlCreateTabItem('Tab ' & Ceiling($i/$iButtonMax) & '/' & Ceiling($aUsernames[0]/$iButtonMax))
					$iButtonPos = $iTrackHeight
				EndIf
				$USER_LIST[$i][$UL_USER] = $aUsernames[$i] ; Store username in array
				$USER_LIST[$i][$UL_ISOFFLINE] = _SteamCheckOffline($aUsernames[$i]) ; Store offline mode status

				; Check for user avatars
				$USER_LIST[$i][$UL_AVATAR] = _Avatar($aUsernames[$i])
				If @error Then
					; If no avatar found, flag as needing to be downloaded...
					$USER_LIST[$i][$UL_DOWNLOAD] = True
					; ... and add the name to a download list
					$sDownloadList &= ' ' & $USER_LIST[$i][$UL_USER]
				EndIf
				$USER_LIST[$i][$UL_PIC_CTRL] = GUICtrlCreatePic($USER_LIST[$i][$UL_AVATAR], 0, $iButtonPos, $iAvatarSize, $iAvatarSize)

				$sButtonText = ' ' & $aUsernames[$i]
				; Add prefix numbers to buttons
				If $bDoNumbers Then
					$sButtonText = ($i < 10 ? ' &' & $i : ($i = 10 ? ' 1&0' : ' ' & $i)) & ':' & $sButtonText
				EndIf

				$sOfflineText = 'Start in ' & ($USER_LIST[$i][$UL_ISOFFLINE] ? 'Off' : 'On') & 'line mode by default'
				$USER_LIST[$i][$UL_BTN_CTRL] = GUICtrlCreateButton($sButtonText, $iAvatarSize, $iButtonPos, Default, $iAvatarSize, BitOR($BS_FLAT, $BS_LEFT))
					GUICtrlSetTip(-1, $sOfflineText & @LF & 'Right-click for options')

				$USER_LIST[$i][$UL_LBL_OFFLINE] = GUICtrlCreateLabel('', 0, $iButtonPos+$iAvatarSize, Default, $iOfflineBorder)
					GUICtrlSetFont(-1, 8, 700)
					GUICtrlSetTip(-1, $sOfflineText)
					GUICtrlSetBkColor(-1, $USER_LIST[$i][$UL_ISOFFLINE] ? 0xff0000 : 0xff00)
					$iButtonPos += $iAvatarSize + $iOfflineBorder

				; Measure button width, and track the largest
				$aGetPos = ControlGetPos($WMG_HMAIN, '', $USER_LIST[$i][$UL_BTN_CTRL])
				$iTrackWidth = $iTrackWidth < $aGetPos[2] ? $aGetPos[2] : $iTrackWidth
			Next
			$aRange_UserBtns[1] = GUICtrlCreateDummy() ; End user button range
		#endregion
		; ====================================================================================================================

		; Snap width to 90% of screen width
		If $iTrackWidth + $iAvatarSize > $MAX_WIDTH Then $iTrackWidth = $MAX_WIDTH - $iAvatarSize
		$iWinWidth = $iTrackWidth + $iAvatarSize ; Add avatar size to button width, we'll be using this to size the rest of the window

		; Set all the button widths to be equal to the largest
		For $i = 1 To $aUsernames[0]
			GUICtrlSetPos($USER_LIST[$i][$UL_BTN_CTRL], Default, Default, $iTrackWidth)
			GUICtrlSetPos($USER_LIST[$i][$UL_LBL_OFFLINE], Default, Default, $iWinWidth)
		Next

		; Resize the banner button
		GUICtrlSetPos($bt_Banner, Default, Default, $iWinWidth)

		; Close out and position tab control if necessary. Register mouse wheel message for scrolling said tab control.
		If $WMG_TAB Then
			GUICtrlCreateTabItem('')
			GUICtrlSetPos($WMG_TAB, Default, Default, $iWinWidth, $aTabRect[3])
			GUIRegisterMsg($WM_MOUSEWHEEL, WM_MOUSEWHEEL)
		EndIf

		$iTrackHeight += $iButtonMax * ($iAvatarSize + $iOfflineBorder) ; Add on the user buttons to the height tracker.

		GUISetFont(9) ; Reset font to a regular size

		$bt_Manage = GUICtrlCreateButton('M&anage Users', 0, $iTrackHeight, $iWinWidth, 25)
			GUICtrlSetTip(-1, 'Ctrl+A')
			$iTrackHeight += 25

		$bt_Extra = GUICtrlCreateButton('E&xtra Options', 0, $iTrackHeight, $iWinWidth, 20)
			GUICtrlSetTip(-1, 'Ctrl+X')
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

				$bt_ReloadAvatars = GUICtrlCreateButton('&Reload Avatars', 5, $iTrackHeight, ($iWinWidth-10)/2, 25)
					GUICtrlSetTip(-1, 'Ctrl+R')
				$bt_AvatarFolder = GUICtrlCreateButton('&Open Avatar Folder', 5+($iWinWidth-10)/2, $iTrackHeight, ($iWinWidth-10)/2, 25)
					GUICtrlSetTip(-1, 'Ctrl+O')
					$iTrackHeight += 25

				GUICtrlCreateLabel('Steam O&ptions:', 5, $iTrackHeight, 90, 20, $SS_CENTERIMAGE)
				$in_SteamParams = GUICtrlCreateInput(StringStripWS($sCmdPassthru, 3), 95, $iTrackHeight, $iWinWidth-100, 20)
					$iTrackHeight += 25

			$aRange_ExtraCtrls[1] = GUICtrlCreateDummy() ; End range

			; Put this outside the range so it doesn't get disabled, and can still trigger from accelerator. It's placed outside normal range anyway so it won't be visible until the window is expanded.
			$lb_Help = GUICtrlCreateLabel('Version: ' & FileGetVersion(@ScriptFullPath), 0, $iTrackHeight, $iWinWidth, 10, $SS_CENTER)
				GUICtrlSetFont(-1, 6)
				GUICtrlSetCursor(-1, 4)
				GUICtrlSetTip(-1, 'View Help file (F1)')
				$iTrackHeight += 10
		#endregion
		; ====================================================================================================================
		$iWinHeightExpand = $iTrackHeight ; Record height after extra controls for expanded window

		Local $dm_TabUp = GUICtrlCreateDummy()
		Local $dm_TabDn = GUICtrlCreateDummy()

		Dim $aAccel = [ [ '{f1}', $lb_Help ], [ '{pgdn}', $dm_TabDn ], [ '{pgup}', $dm_TabUp ], [ '^a', $bt_Manage ], _
			[ '^x', $bt_Extra ], [ '^s', $bt_Banner ], [ '^r', $bt_ReloadAvatars ], [ '^o', $bt_AvatarFolder ] ]
		GUISetAccelerators($aAccel)

		; Resize and center window
		$aWinOffset = _WinGetClientOffset($WMG_HMAIN)
		$iWinWidth += $aWinOffset[0]
		$iWinHeight += $aWinOffset[1]
		$iWinHeightExpand += $aWinOffset[1]

		If $bAutoExpand Then
			GUICtrlSetState($bt_Extra, $GUI_HIDE) ; Hide the "Extra Options" button if starting expanded
			_WinCenter($WMG_HMAIN, $iWinWidth, $iWinHeightExpand, $vCenterAt)
		Else
			For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1]
				GUICtrlSetState($i, BitOR($GUI_DISABLE, $GUI_HIDE)) ; Hide the extra controls if window doesn't start expanded
			Next
			_WinCenter($WMG_HMAIN, $iWinWidth, $iWinHeight, $vCenterAt)
		EndIf

		GUICtrlSetState($bt_Manage, $GUI_FOCUS)

	#endregion

	; ====================================================================================================================

	GUISetState(@SW_SHOWNORMAL, $WMG_HMAIN)

	If $sDownloadList Then _DownloadAvatars($sDownloadList) ; Start avatar downloads if necessary

	$iActiveTimeout = TimerInit()
	While 1
		$GM = GUIGetMsg()
		Switch $GM
			Case $GUI_EVENT_NONE
				; Some controls are not actually created if not required (ie: $bt_Banner) and
				; their variable defaults to ''. This will match the default GUIGetMsg return (0)
				; and that would erroneously trigger that Case statement.
				; So we make sure to handle the default GUIGetMsg ($GUI_EVENT_NONE) first and then the flow
				; never reaches the undeclared variable's Case.
			Case $bt_Banner
				; Clicking the banner triggers the context menu
				$aGetPos = WinGetPos(GUICtrlGetHandle($bt_Banner))
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_Banner), $WMG_HMAIN, $aGetPos[0]+$aGetPos[2], $aGetPos[1]+$aGetPos[3], 2, 1)
			Case $mi_OpenSteam
				_SteamLogin()
			Case $mi_CloseSteam
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				If _SteamClose() Then
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
				_SteamLogin($CURR_USER, 1, GUICtrlRead($in_SteamParams))
			Case $mi_GoOffline
				_SteamLogin($CURR_USER, 2, GUICtrlRead($in_SteamParams))

			; These are from the user context menu
			Case $WMG_MI_TITLE
				_SteamLogin(GUICtrlRead($WMG_MI_TITLE, 1), 0, GUICtrlRead($in_SteamParams))
			Case $WMG_MI_ONLINE
				_SteamLogin(GUICtrlRead($WMG_MI_TITLE, 1), 1, GUICtrlRead($in_SteamParams))
			Case $WMG_MI_OFFLINE
				_SteamLogin(GUICtrlRead($WMG_MI_TITLE, 1), 2, GUICtrlRead($in_SteamParams))
			Case $mi_ReloadAvatar
				For $i = 1 To $USER_LIST[0][0] ; Iterate through user list
					If $USER_LIST[$i][$UL_USER] = GUICtrlRead($WMG_MI_TITLE, 1) Then ; Find the user selected
						GUICtrlSetImage($USER_LIST[$i][$UL_PIC_CTRL], $DEFAULT_AV) ; Set to temp image
						$USER_LIST[$i][$UL_DOWNLOAD] = True ; Set download flag to true
						FileDelete($AVATAR_PATH & $USER_LIST[$i][$UL_USER] & '.*')
						_DownloadAvatars($USER_LIST[$i][$UL_USER]) ; Trigger downloader
						ExitLoop
					EndIf
				Next

			; User buttons and pics
			Case $aRange_UserBtns[0] To $aRange_UserBtns[1]
				For $i = 1 To $USER_LIST[0][0] ; Iterate through user list
					If $GM = $USER_LIST[$i][$UL_PIC_CTRL] Or $GM = $USER_LIST[$i][$UL_BTN_CTRL] Then ; Find the button clicked
						$iOfflineMode = 0
						If BitAND(GUICtrlRead($ra_OfflineNo), $GUI_CHECKED) Then
							$iOfflineMode = 1
						ElseIf BitAND(GUICtrlRead($ra_OfflineYes), $GUI_CHECKED) Then
							$iOfflineMode = 2
						EndIf

						_SteamLogin($USER_LIST[$i][$UL_USER], $iOfflineMode, GUICtrlRead($in_SteamParams))
						ExitLoop
					EndIf
				Next

			Case $bt_Manage
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				_ManageUsers($sUsersFiltered)
				GUISetState(@SW_ENABLE, $WMG_HMAIN)
				WinActivate($WMG_HMAIN)

			Case $bt_Extra
				GUICtrlSetState($bt_Extra, $GUI_HIDE)
				For $i = $aRange_ExtraCtrls[0] To $aRange_ExtraCtrls[1]
					GUICtrlSetState($i, BitOR($GUI_SHOW, $GUI_ENABLE))
				Next
				_WinCenter($WMG_HMAIN, Default, $iWinHeightExpand, $WMG_HMAIN) ; Target itself to center at old position
				GUICtrlSetState($bt_Manage, $GUI_FOCUS)

			Case $lb_Help
				GUISetState(@SW_DISABLE, $WMG_HMAIN)
				_Help()
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

			Case $bt_AvatarFolder
				ShellExecute($AVATAR_PATH)

			Case $dm_TabDn
				_TabSwitch(1)
			Case $dm_TabUp
				_TabSwitch(0)

			Case $GUI_EVENT_CLOSE
				Exit @ScriptLineNumber
		EndSwitch

		If WinActive($WMG_HMAIN) Then
			$iActiveTimeout = TimerInit()
		ElseIf TimerDiff($iActiveTimeout) > $UNFOCUS_TIMEOUT Then
			; Close window after timeout
			Exit @ScriptLineNumber
		EndIf
	WEnd
EndFunc

Func _Migrate() ; Old version config migration
	Local $hAvatars, $sFile
	If FileExists($CFG_PATH & 'SteamSwitch.cfg') And Not FileExists($USERS_FILE) Then
		FileMove($CFG_PATH & 'SteamSwitch.cfg', $USERS_FILE)
	EndIf

	$hAvatars = FileFindFirstFile($CFG_PATH & '*.jpg')

	While $hAvatars <> -1
		$sFile = FileFindNextFile($hAvatars)
		If @error Then ExitLoop

		FileMove($CFG_PATH & $sFile, $AVATAR_PATH & $sFile)
	WEnd
EndFunc

Func _SteamPID() ; Get process ID of Steam process if it matches $STEAM_EXE path
	Local $aModules, $aProcs, $aProcName = StringRegExp($STEAM_EXE, '([^\\/]+?)$', 1)
	If Not @error Then
		; The _WinAPI_EnumProcessModules function works from a 64-bit system only in Windows Vista or later
		If @AutoItX64 And Number(_WinAPI_GetVersion()) < 6.0 Then
			Return ProcessExists($aProcName[0])
		Else
			$aProcs = ProcessList($aProcName[0])
			For $i = 1 To $aProcs[0][0]
				$aModules = _WinAPI_EnumProcessModules($aProcs[$i][1])
				For $m = 1 to $aModules[0][0]
					If $aModules[$m][1] = $STEAM_EXE Then Return $aProcs[$i][1]
				Next
			Next
		EndIf
	EndIf
EndFunc

Func _SteamClose() ; Close Steam window
	Static $hGUIWait, $lb_Wait[15], $bt_Cancel, $bt_Kill
	Local $GM, $iSteamPID, $iTimer, $iAniTimer, $iAniStep = 0, $iAniPhase = 1, $iAniDelay = 200

	If Not $hGUIWait Then
		$hGUIWait = GUICreate('Please wait...', 200, 135, Default, Default, Default, $WS_EX_TOOLWINDOW, $WMG_HMAIN)
		GUICtrlCreateLabel('Closing Steam...', 0, 15, 200, 30, $SS_CENTER)
			GUICtrlSetFont(-1, 12, 700)
		For $i = 0 To 4 ; Only define a portion of the dot labels, this simulates the delay between each animation cycle
			$lb_Wait[$i] = GUICtrlCreateLabel('•', 25+ $i * 30, 50, 30, 30, BitOR($SS_CENTER, $SS_CENTERIMAGE))
				GUICtrlSetFont(-1, 50)
		Next
		$bt_Cancel = GUICtrlCreateButton('Cancel', 20, 100, 75, 25)
		$bt_Kill = GUICtrlCreateButton('Force Close', 105, 100, 75, 25)
	EndIf

	$iSteamPID = _SteamPID()
	If $iSteamPID Then
		If $DEBUG = False Then ShellExecute($STEAM_EXE, '-shutdown') ; Send shutdown command to Steam
		GUISetState(@SW_SHOW, $hGUIWait)

		$iTimer = TimerInit() ; Start timer
		$iAniTimer = TimerInit()
		While ProcessExists($iSteamPID) ; Will exit if Steam exits
			$GM = GUIGetMsg()

			Switch $GM
				Case $GUI_EVENT_NONE
					If TimerDiff($iTimer) > 10000 Then
						; Every 10 seconds resend shutdown command
						$iTimer = TimerInit()
						If $DEBUG = False Then ShellExecute($STEAM_EXE, '-shutdown')
					EndIf

					If TimerDiff($iAniTimer) > $iAniDelay Then
						$iAniTimer = TimerInit()
						$iAniDelay = 200
						If $iAniPhase Then
							GUICtrlSetColor($lb_Wait[$iAniStep], 0x66c0f4)
						Else
							GUICtrlSetColor($lb_Wait[$iAniStep], 0)
						EndIf

						$iAniStep = Mod($iAniStep + 1, 5)
						If Not $iAniStep Then
							$iAniDelay *= 2
							$iAniPhase = Mod($iAniPhase+1, 2)
						EndIf
					EndIf

				Case $bt_Kill
					If MsgBox(0x134, 'Warning!', 'Are you sure you want to force Steam to close?' & @LF & 'This may result in lost data if Steam is still working (eg: uploading cloud saves).', 0, $hGUIWait) = 6 Then
						ProcessClose($iSteamPID)
					EndIf
				Case $bt_Cancel, $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd
	EndIf

	GUISetState(@SW_HIDE, $hGUIWait)
	Return Not ProcessExists($iSteamPID) ; Return true if Steam is closed or not running
EndFunc

Func _SteamLogin($sUsername = $CURR_USER, $iOfflineMode = 0, $sCmdPassthru = '') ; Set login user, offline mode, close Steam if necessary, and relaunch
	Local $iMsgBox, $bReadonly
	GUISetState(@SW_HIDE, $WMG_HMAIN)
	If $CURR_USER <> $sUsername Or $iOfflineMode <> 0 Then
		; We only need to try and close Steam if the user or the offline mode needs to change
		If Not _SteamClose() Then Return GUISetState(@SW_SHOW, $WMG_HMAIN)

		RegWrite($STEAM_REG, $REG_USERNAME, 'REG_SZ', $sUsername)
	Else
		; Check for Steam offline window
		If WinExists('[CLASS:vguiPopupWindow;TITLE:Steam - Offline Mode]') Then
			If Not BitAND(WinGetState('[last]'), 2) Then ; Window exists but is hidden
				WinSetState('[last]', '', @SW_SHOW)
				Local $iMsgBox = MsgBox(0x40, 'Notice', 'The Steam - Offline Mode window was open but hidden.' & @LF & _
					'This happens when you just close the window instead of clicking either the "GO ONLINE" or "START IN OFFLINE MODE" button.' & @LF & _
					'This window must be dealt with before Steam can be opened.', 0, WinGetHandle('[last]'))
			EndIf
			WinActivate('[last]')
			Exit @ScriptLineNumber
		EndIf
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
				$iMsgBox = MsgBox(0x31, 'Warning', 'Unable to find user config (' & $STEAM_CFG_PATH & ').' & @LF & _
					'Cannot change offline mode. Continue anyway?', 0, $WMG_HMAIN)
			Case 2
				$iMsgBox = MsgBox(0x31, 'Warning', 'User config badly formatted.' & @LF & _
					'Cannot change offline mode. Continue anyway?', 0, $WMG_HMAIN)
			Case 3
				$bReadonly = StringInStr(FileGetAttrib($STEAM_CFG_PATH), 'R')
				$iMsgBox = MsgBox(0x31, 'Warning', 'Unable to write to user config' & ($bReadonly ? ' (file is read-only)' : '') & '.' & @LF & _
					'Cannot change offline mode. Continue anyway?', 0, $WMG_HMAIN)
		EndSwitch

		If $iMsgBox = 2 Then Return GUISetState(@SW_SHOW, $WMG_HMAIN)
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
	The loginusers.vdf file should be formatted as such:
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

	If Not FileExists($STEAM_CFG_PATH) Then Return SetError(1, 0, 0)

	Local $sNewConfig, $aSegments, $hFile, _
		$iTimestamp = _DateDiff('s', '1970/01/01 00:00:00', _NowCalc()), _ ; Get UNIX timestamp
		$sConfigData = FileRead($STEAM_CFG_PATH) ; Read in loginusers.vdf

	$aSegments = StringRegExp($sConfigData, '(?si)^(.*{)(.*?"AccountName"\s*"'& $sUser & '".*?)(}.*)$', 1) ; Isolate user segment for rewrite.
	If UBound($aSegments) <> 3 Then
		; Could not interpret file data
		Return SetError(2, 0, 0)
	Else
		; If Offline mode isn't specifically set, check the current offline mode.
		If $bOffline = Default Then $bOffline = StringRegExp($aSegments[1], '(?i)"WantsOfflineMode"\s*"1"')

		; If the Timestamp value is missing or set low (ie: a long time ago) the password will expire and Steam will prompt to re-enter the password.
		$sNewConfig = StringRegExpReplace($aSegments[1], '(?i)(Timestamp"\s*)".+?"', '\1"' & $iTimestamp & '"')

		; The SkipOfflineModeWarning should, as it implies, skip that prompt on launch but it seems to be inconsistent lately (can't figure out why).
		If $bOffline Then
			; Replace existing value, if replace fails add new value to segment
			$sNewConfig = StringRegExpReplace($sNewConfig, '(?i)("WantsOfflineMode"\s*)"."', '\1"1"')
			If Not @extended Then $sNewConfig &= StringFormat('\t"WantsOfflineMode"\t\t"1"\n\t')

			; Same as previous
			$sNewConfig = StringRegExpReplace($sNewConfig, '(?i)("SkipOfflineModeWarning"\s*)"."', '\1"1"')
			If Not @extended Then $sNewConfig &= StringFormat('\t"SkipOfflineModeWarning"\t\t"1"\n\t')
		Else
			; Replace existing value, if replace fails just ignore (value not necessary if not using offline mode)
			$sNewConfig = StringRegExpReplace($sNewConfig, '(?i)("WantsOfflineMode"\s*)"."', '\1"0"')
			$sNewConfig = StringRegExpReplace($sNewConfig, '(?i)("SkipOfflineModeWarning"\s*)"."', '\1"0"')
		EndIf

		; Combine new config with outer segments.
		$sNewConfig = $aSegments[0] & $sNewConfig & $aSegments[2]

		$hFile = FileOpen($STEAM_CFG_PATH, 2)
		If $hFile <> -1 Then
			FileWrite($hFile, $sNewConfig)
			FileClose($hFile)
			Return 1
		Else
			Return SetError(3, 0, 0)
		EndIf
	EndIf
EndFunc


Func _Help() ; Help dialog
	Static $hGUIHelp, $ed_Help, $sHelpFile

	If Not $hGUIHelp Then ; Create the window only once then just show/hide it
		$sHelpFile = _
			StringReplace( _
				StringReplace( _
					StringReplace(FileRead($HELP_FILE), @TAB, '    '), _
				'X:\Path\To\SteamSwitch.exe', @ScriptFullPath), _
			'%AppData%', @AppDataDir)

		$hGUIHelp = GUICreate('Help  —  v' & FileGetVersion(@ScriptFullPath), 600, 400, Default, Default, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX), Default, $WMG_HMAIN)
		$ed_Help = GUICtrlCreateEdit($sHelpFile, 0, 0, 600, 400, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
			GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	EndIf
	GUISetState(@SW_SHOW, $hGUIHelp)
	ControlSend($hGUIHelp, '', $ed_Help, '^{home}')

	Do
	Until GUIGetMsg() = $GUI_EVENT_CLOSE
	GUISetState(@SW_HIDE, $hGUIHelp)
EndFunc

Func _ManageUsers($sPrefill) ; Manage users dialog
	Static $hGUIUsers, $ed_Users, $bt_Grab, $bt_OK, $bt_Cancel
	Local $GM, $aAccel, $aRegEx, $aSplit, $aContent[2], $hFile

	If Not $hGUIUsers Then
		$hGUIUsers = GUICreate('Manage Users', 300, 265, Default, Default, $WS_CAPTION, Default, $WMG_HMAIN)
		GUISetFont(9)
		GUICtrlCreateLabel('Usernames (1 per line):', 5, 5, 140, 25)
		$ed_Users = GUICtrlCreateEdit('', 0, 25, 150, 200)
		GUICtrlCreateLabel('Use Steam ACCOUNT names not DISPLAY names.' &@LF& 'Account names are restricted to A-Z, 0-9, and underscore (_), and have a minimum length of 3 characters.', 155, 25, 140, 175)
		$bt_Grab = GUICtrlCreateButton('&Grab Usernames', 155, 195, 140, 30)
			GUICtrlSetTip(-1, 'Grab usernames from Steam config (Ctrl+G)')
		$bt_OK = GUICtrlCreateButton('OK', 5, 230, 145, 30, $BS_DEFPUSHBUTTON)
			GUICtrlSetTip(-1, 'Shortcut: Ctrl+Enter')
		$bt_Cancel = GUICtrlCreateButton('Cancel', 155, 230, 140, 30)

		Local $aAccel = [ [ '^{enter}', $bt_OK ], [ '^g', $bt_Grab ] ]
		GUISetAccelerators($aAccel)
	EndIf

	GUICtrlSetData($ed_Users, StringAddCR($sPrefill))
	_WinCenter($hGUIUsers, Default, Default, $WMG_HMAIN)
	GUISetState(@SW_SHOW, $hGUIUsers)
	ControlSend($hGUIUsers, '', $ed_Users, '^{end}') ; Put cursor at end of list

	While 1
		$GM = GUIGetMsg()
		Switch $GM
			Case $bt_Grab
				$aRegEx = StringRegExp(FileRead($STEAM_CFG_PATH), '(?i)"AccountName"\s*"(.+?)"', 3)
				$aContent[0] = StringStripWS(GUICtrlRead($ed_Users), 2)
				$aContent[1] = ''
				For $i = 0 To UBound($aRegEx)-1
					If Not StringRegExp($aContent[0], '(?i)\b\Q' & $aRegEx[$i] & '\E\b') Then $aContent[1] &= $aRegEx[$i] & @CRLF
				Next
				GUICtrlSetData($ed_Users, StringStripWS($aContent[0] & @CRLF & $aContent[1], 1))
				ControlSend($hGUIUsers, '', $ed_Users, '^{end}') ; Put cursor at end of list
			Case $bt_OK
				$aContent[0] = GUICtrlRead($ed_Users)
				$aContent[1] = ''
				$aSplit = StringSplit(StringStripWS(StringStripCR($aContent[0]), 7), @LF)
				For $i = 1 To $aSplit[0]
					If StringLen($aSplit[$i]) < 3 Or StringRegExp($aSplit[$i], '[^a-zA-Z0-9_]') Then
						$aContent[1] &= @LF & '    ' & $aSplit[$i]
					EndIf
				Next
				If $aContent[1] Then
					MsgBox(0x30, 'Notice', 'Invalid usernames:' & $aContent[1], 0, $hGUIUsers)
				Else
					$hFile = FileOpen($USERS_FILE, 2)
					If $hFile <> -1 Then
						FileWrite($hFile, $aContent[0])
						FileClose($hFile)
						; Usernames added, launch new instance and exit current
						GUIDelete($hGUIUsers)
						GUISetState(@SW_HIDE, $WMG_HMAIN)
						ShellExecute(@AutoItExe, $CmdLineRaw)
						Exit @ScriptLineNumber
					Else
						If MsgBox(0x2114, 'Error', 'Cannot write to config file:' & @LF & StringReplace($USERS_FILE, @AppDataDir, '%AppData%') & @LF & @LF & 'Navigate to file location?', 0, $hGUIUsers) = 6 Then
							ShellExecute('explorer.exe', '/select,"' &$USERS_FILE& '"')
						EndIf
					EndIf
				EndIf
			Case $bt_Cancel, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUISetState(@SW_HIDE, $hGUIUsers)
EndFunc

Func _WinGetClientOffset($hWnd) ; Get difference between window size and client size (titlebar, window borders, etc)
	Local $aPos = WinGetPos($hWnd), $aClient = WinGetClientSize($hWnd)
	Local $aReturn[2] = [ $aPos[2] - $aClient[0], $aPos[3] - $aClient[1] ]
	Return $aReturn
EndFunc

Func _WinCenter($hWnd, $iWidth = Default, $iHeight = Default, $vPosition = 'center') ; Size and center window at a location/target
	Local $aWinMove[4], $aGetPos = WinGetPos($hWnd), $aMouse = MouseGetPos()

	If $iWidth  = Default Then $iWidth  = $aGetPos[2]
	If $iHeight = Default Then $iHeight = $aGetPos[3]

	$aWinMove[2] = $iWidth
	$aWinMove[3] = $iHeight

	If IsHWnd($vPosition) Then
		$aGetPos = WinGetPos($vPosition)
		$aWinMove[0] = $aGetPos[0] + ($aGetPos[2] - $iWidth)/2
		$aWinMove[1] = $aGetPos[1] + ($aGetPos[3] - $iHeight)/2
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
	Local $sAvatar, $sAvatarName = $AVATAR_PATH & $sUsername, $aExt = [ '.jpg', '.gif', '.bmp' ]
	For $i = 0 To 2
		$sAvatar = $sAvatarName & $aExt[$i]
		If FileExists($sAvatar) Then
			If FileGetSize($sAvatar) Then Return $sAvatar
			Return $NO_AVATAR
		EndIf
	Next
	Return SetError(1, 0, $DEFAULT_AV)
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
	Local $sAvatarPath, $sAvatarURL, $sAvatarPattern = '(?i)(\Qhttps://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/\E.+?_medium\.jpg)', _
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
			$sAvatarURL = ''
			$sAvatarPath = $AVATAR_PATH & $CmdLine[$i] & '.jpg'
			$sProfilePage = BinaryToString(InetRead(StringFormat('https://steamcommunity.com/id/%s/?xml=1', $CmdLine[$i]), 1)) ; Read user profile XML page to string (will unfortunately fail if user has not set their "Custom URL")
			If $sProfilePage Then
				$aRegEx = StringRegExp($sProfilePage, $sAvatarPattern, 1) ; Look for the avatar string.
				If Not @error Then $sAvatarURL = $aRegEx[0]
			EndIf

			; If profile page not loaded, or avatar not found on page
			If Not $sAvatarURL Then ; Try the search page method...
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

			$iDownload = 0 ; Reset download state to confirm whether download was successful
			If $sAvatarURL Then $iDownload = InetGet($sAvatarURL, $sAvatarPath)

			; If nothing could be downloaded create an empty dummy file to prevent future attempts to redownload (we assume the avatar is unobtainable, so just stop trying)
			If Not $iDownload Then FileWrite($sAvatarPath, '')
		Next
	EndIf
EndFunc

Func WM_MOUSEWHEEL($hWnd, $iMsg, $wParam, $lParam) ; Handle mousewheel scroll to cycle through user page tabs
	If $hWnd = $WMG_HMAIN And BitAND(WinGetState($WMG_HMAIN), $WIN_STATE_ENABLED) Then
		If _WinAPI_HiWord($wParam) > 0 Then
			_TabSwitch(0)
		Else
			_TabSwitch(1)
		EndIf
	EndIf
EndFunc

Func _TabSwitch($bDir = 0)
	Local $iCurr = _GUICtrlTab_GetCurSel($WMG_TAB)
	Local $iLast = _GUICtrlTab_GetItemCount($WMG_TAB)-1
	If Not $bDir Then
		$iCurr -= 1
		If $iCurr < 0 Then Return
	Else
		$iCurr += 1
		If $iCurr > $iLast Then Return
	EndIf
	_GUICtrlTab_ActivateTab($WMG_TAB, $iCurr)
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
