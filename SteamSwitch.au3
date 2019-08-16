#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=SteamSwitch.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=SteamSwitch
#AutoIt3Wrapper_Res_Description=SteamSwitch
#AutoIt3Wrapper_Res_Fileversion=1.4.0.2
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
#include <Date.au3>

Opt('MustDeclareVars', 1)

Global Const $REG_KEY = 'HKCU\Software\Valve\Steam'
Global Const $STEAM_EXE = RegRead($REG_KEY, 'SteamExe')
Global Const $STEAM_PATH = RegRead($REG_KEY, 'SteamPath')
Global Const $STEAM_CFG_PATH = $STEAM_PATH & '\config\loginusers.vdf'
Global Const $REG_USERNAME = 'AutoLoginUser'
Global Const $REG_REMPASS = 'RememberPassword'
Global Const $CFG_PATH = @AppDataDir & '\therkSoft\SteamSwitch\'
Global Const $CFG_FILE = $CFG_PATH & 'SteamSwitch.cfg'

Main()

Func Main()
	Local Enum $LI_USER, $LI_GETAV, $LI_PIC, $LI_BTN
	Local $aUsers, $sUserCheck, $iUserCnt, $aUserList[1][4], $iSteamPID, $sAvatarCheck, $iCheckAvs, $sCmdPassthru, $bNoNumbers = False, $sAutoLogin, _
		$aWinOffset, $iAvatarSize = 64, $iMeasureWidth = 210, $iMeasureHeight = 0, $iExpandedSize, $aCtrlPos, $sButtonText, $iOfflineMode = 0, $bAutoExpand = False, _
		$hGUIParent, $hGUIMain, $aRange[2], $bt_AddMore, $bt_Extra, $aExtraCtrls[2], $ra_OfflineDef, $ra_OfflineNo, $ra_OfflineYes, $bt_ReloadAvatars, $lb_Help, $aAccel, _
		$hGUIWait, $lb_Wait, $GM

	If Not $STEAM_EXE Then
		Exit MsgBox(0x30, 'SteamSwitch', 'Could not find Steam registry key.' & @LF & 'Please ensure Steam has been installed and started at least once before using this program.')
	EndIf

	If Not FileExists($CFG_PATH) Then DirCreate($CFG_PATH)

	FileInstall('Waiting.ani', $CFG_PATH & 'Waiting.ani', 1)
	FileInstall('SteamSwitch_Default.jpg', $CFG_PATH & 'No Avatar.jpg')

	#cs
	SteamSwitch CmdLine switches:
		/avatarsize=##
		/autologin=username
		/nonumbers
		/offline
		/online
		/extra
	#ce

	If $CmdLine[0] Then
		For $i = 1 To $CmdLine[0]
			If StringRegExp($CmdLine[$i], '/avatarsize=') = 1 Then
				$iAvatarSize = Int(StringSplit($CmdLine[$i], '=')[2])
			ElseIf StringInStr($CmdLine[$i], '/autologin=') = 1 Then
				$sAutoLogin = StringSplit($CmdLine[$i], '=')[2]
			ElseIf $CmdLine[$i] = '/nonumbers' Then
				$bNoNumbers = True
			ElseIf $CmdLine[$i] = '/online' Then
				$iOfflineMode = 1
			ElseIf $CmdLine[$i] = '/offline' Then
				$iOfflineMode = 2
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

	If $sAutoLogin Then
		_SteamLogin(0, $sAutoLogin, $iOfflineMode, $sCmdPassthru)
		Exit
	EndIf

	Opt('GUIResizeMode', $GUI_DOCKALL)
	$aUsers = FileReadToArray($CFG_FILE)
	For $i = 0 To UBound($aUsers)-1
		If StringRegExp($aUsers[$i], '^\w+$') Then $sUserCheck &= ' ' & $aUsers[$i]
	Next
	$aUsers = StringSplit(StringStripWS($sUserCheck, 3), ' ', 2)
	If @error Then $aUsers = ''
	$iUserCnt = UBound($aUsers)
	ReDim $aUserList[$iUserCnt][4]

	; =============================
	; =============================
	#region - Build main GUI

	$hGUIParent = GUICreate('')
	$hGUIMain = GUICreate('Steam Switcher -- F1 for help', 400, 400, Default, Default, $WS_SYSMENU, $WS_EX_TOPMOST, $hGUIParent)
	$aWinOffset = _GetWinOffset($hGUIMain)
	GUISetFont($iAvatarSize * 0.375)

	$aRange[0] = GUICtrlCreateDummy()
	For $i = 0 To $iUserCnt-1
		$aUserList[$i][$LI_USER] = $aUsers[$i]
		$sAvatarCheck = $CFG_PATH & $aUsers[$i] & '.jpg'
		If Not FileExists($sAvatarCheck) Then
			$aUserList[$i][$LI_GETAV] = True
			$sAvatarCheck = $CFG_PATH & 'No Avatar.jpg'
		EndIf
		$aUserList[$i][$LI_PIC] = GUICtrlCreatePic($sAvatarCheck, 0, $i * $iAvatarSize, $iAvatarSize, $iAvatarSize)
		If $bNoNumbers Then
			$sButtonText = ' ' & $aUsers[$i] & ' '
		Else
			$sButtonText = ($i < 9 ? ' &' & $i+1 : ($i = 9 ? ' 1&0' : ' ' & $i+1)) & ': ' & $aUsers[$i] & ' '
		EndIf
		$aUserList[$i][$LI_BTN] = GUICtrlCreateButton($sButtonText, $iAvatarSize, $i * $iAvatarSize, Default, $iAvatarSize, $BS_FLAT+$BS_LEFT)
		$aCtrlPos = ControlGetPos($hGUIMain, '', $aUserList[$i][$LI_BTN])
		$iMeasureWidth = $iMeasureWidth < $aCtrlPos[2]+$iAvatarSize ? $aCtrlPos[2]+$iAvatarSize : $iMeasureWidth
	Next
	$aRange[1] = GUICtrlCreateDummy()

	For $i = 0 To $iUserCnt-1
		GUICtrlSetPos($aUserList[$i][$LI_BTN], Default, Default, $iMeasureWidth - $iAvatarSize)
	Next

	$iMeasureHeight = $iAvatarSize * $iUserCnt

	GUISetFont(9)

	$bt_AddMore = GUICtrlCreateButton('&Add/Edit Users', 0, $iMeasureHeight, $iMeasureWidth, 25)
	$bt_Extra = GUICtrlCreateButton('E&xtra options', 0, $iMeasureHeight+25, $iMeasureWidth, 20)
	GUICtrlSetFont(-1, 8)
	$iMeasureHeight += 25

	$aExtraCtrls[0] = GUICtrlCreateDummy()
		GUICtrlCreateGroup('Connection Mode:', 5, $iMeasureHeight+5, $iMeasureWidth-10, 45)
		$ra_OfflineDef = GUICtrlCreateRadio('&Default', 10, $iMeasureHeight+25, 60, 15)
			GUICtrlSetTip(-1, 'Uses last login connection mode')
		$ra_OfflineNo = GUICtrlCreateRadio('O&nline', 75, $iMeasureHeight+25, 60, 15)
			GUICtrlSetTip(-1, 'Start in online mode')
		$ra_OfflineYes = GUICtrlCreateRadio('O&ffline', 140, $iMeasureHeight+25, 60, 15)
			GUICtrlSetTip(-1, 'Start in offline mode')

		GUICtrlSetState($ra_OfflineDef + $iOfflineMode, $GUI_CHECKED)

		$bt_ReloadAvatars = GUICtrlCreateButton('&Reload Avatars', 5, $iMeasureHeight+55, $iMeasureWidth-10, 25)

		$lb_Help = GUICtrlCreateLabel('Version: ' & FileGetVersion(@ScriptFullPath), 0, $iMeasureHeight+80, $iMeasureWidth, 10, $SS_CENTER)
			GUICtrlSetFont(-1, 6)
			GUICtrlSetCursor(-1, 4)

		$iExpandedSize = $iMeasureHeight+90
	$aExtraCtrls[1] = GUICtrlCreateDummy()

	For $i = $aExtraCtrls[0] To $aExtraCtrls[1]
		GUICtrlSetState($i, $GUI_HIDE)
	Next

	$iMeasureHeight += 20

	WinMove($hGUIMain, '', _
		0.5*(@DesktopWidth - ($iMeasureWidth + $aWinOffset[0])), _
		0.5*(@DesktopHeight - ($iMeasureHeight + $aWinOffset[1])), _
		$iMeasureWidth + $aWinOffset[0], _
		$iMeasureHeight + $aWinOffset[1])

	Local $aAccel = [ [ '{f1}', $lb_Help ] ]
	GUISetAccelerators($aAccel)

	#endregion
	; =============================
	; =============================

	$hGUIWait = GUICreate('', 200, 100, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hGUIMain)
	$lb_Wait = GUICtrlCreateLabel('Closing steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($CFG_PATH & 'Waiting.ani', 0, (200-32)/2, 40, 32, 32)

	GUICtrlSetState($bt_AddMore, $GUI_FOCUS)

	If $bAutoExpand Then
		$bAutoExpand = False
		GUICtrlSetState($bt_Extra, $GUI_HIDE)
		For $i = $aExtraCtrls[0] To $aExtraCtrls[1]
			GUICtrlSetState($i, $GUI_SHOW)
		Next
		WinMove($hGUIMain, '', Default, Default, Default, $iExpandedSize + $aWinOffset[1])
	EndIf

	GUISetState(@SW_SHOWNORMAL, $hGUIMain)

	While WinActive($hGUIMain)
		; Fill out missing avatars after list load
		If $iCheckAvs < $iUserCnt Then
			If $aUserList[$iCheckAvs][$LI_GETAV] Then
				$aUserList[$iCheckAvs][$LI_GETAV] = False
				GUICtrlSetImage($aUserList[$iCheckAvs][$LI_PIC], _GetAvatar($aUsers[$iCheckAvs]))
			EndIf
			$iCheckAvs += 1
		EndIf

		$GM = GUIGetMsg()
		Switch $GM
			Case $aRange[0] To $aRange[1]
				For $i = 0 To $iUserCnt-1
					If $GM = $aUserList[$i][$LI_PIC] Or $GM = $aUserList[$i][$LI_BTN] Then

						Switch true
							Case BitAND(GUICtrlRead($ra_OfflineDef), $GUI_CHECKED)
								$iOfflineMode = 0
							Case BitAND(GUICtrlRead($ra_OfflineNo), $GUI_CHECKED)
								$iOfflineMode = 1
							Case BitAND(GUICtrlRead($ra_OfflineYes), $GUI_CHECKED)
								$iOfflineMode = 2
						EndSwitch

						_SteamLogin($hGUIMain, $aUserList[$i][$LI_USER], $iOfflineMode, $sCmdPassthru)
					EndIf
				Next

			Case $bt_AddMore
				GUISetState(@SW_DISABLE, $hGUIMain)
				_AddUsers($hGUIMain, $sUserCheck)
				GUISetState(@SW_ENABLE, $hGUIMain)
				WinActivate($hGUIMain)

			Case $bt_Extra
				GUICtrlSetState($bt_Extra, $GUI_HIDE)
				For $i = $aExtraCtrls[0] To $aExtraCtrls[1]
					GUICtrlSetState($i, $GUI_SHOW)
				Next
				WinMove($hGUIMain, '', Default, Default, Default, $iExpandedSize + $aWinOffset[1])

			Case $lb_Help
				GUISetState(@SW_DISABLE, $hGUIMain)
				_Help($hGUIMain)
				GUISetState(@SW_ENABLE, $hGUIMain)
				WinActivate($hGUIMain)

			Case $bt_ReloadAvatars
				_ClearAvatars()
				GUIDelete($hGUIMain)
				Run(@AutoItExe & ' ' & $CmdLineRaw)

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
EndFunc

Func _SteamLogin($hGUIMain, $sUsername, $iOfflineMode, $sCmdPassthru)
	Local $hGUIWait, $lb_Wait, $iSteamPID

	$hGUIWait = GUICreate('', 200, 100, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hGUIMain)
	$lb_Wait = GUICtrlCreateLabel('Closing steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($CFG_PATH & 'Waiting.ani', 0, (200-32)/2, 40, 32, 32)

	If RegRead($REG_KEY, $REG_USERNAME) <> $sUsername Or $iOfflineMode <> 0 Then
		$iSteamPID = ProcessExists('steam.exe')
		If $iSteamPID Then
			GUISetState(@SW_DISABLE, $hGUIMain)
			GUISetState(@SW_SHOW, $hGUIWait)
			While ProcessExists($iSteamPID)
				GUICtrlSetData($lb_Wait, 'Closing steam...')
				Run($STEAM_EXE & ' -shutdown')

				For $iWait = 15 to 0 Step -1
					If ProcessWaitClose($iSteamPID, 1) Then
						ExitLoop 2 ; Exit For & While loops
					ElseIf $iWait <= 10 Then
						GUICtrlSetData($lb_Wait, 'Closing steam...' & @LF & '(timeout ' & $iWait & ' seconds)')
					EndIf
				Next

				If MsgBox(0x2015, 'Error', 'Steam is still running. Failed to close.' & @LF & 'Steam must be closed first to switch users.', 0, $hGUIMain) = 2 Then
					GUIDelete($hGUIWait)
					GUISetState(@SW_ENABLE, $hGUIMain)
					ExitLoop 2
				Else
					ContinueLoop
				EndIf
			WEnd
		EndIf
		RegWrite($REG_KEY, $REG_USERNAME, 'REG_SZ', $sUsername)
	EndIf
	RegWrite($REG_KEY, $REG_REMPASS, 'REG_DWORD', 1)

	Switch $iOfflineMode
		Case 1
			_SteamConfig($STEAM_CFG_PATH, $sUsername, False)
		Case 2
			_SteamConfig($STEAM_CFG_PATH, $sUsername, True)
	EndSwitch

	Run($STEAM_EXE & $sCmdPassthru)
	Exit
EndFunc

Func _ClearAvatars()
	Local $hSearch = FileFindFirstFile($CFG_PATH & '\*.jpg'), $sFile
	While 1
		$sFile = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		FileDelete($CFG_PATH & $sFile)
	WEnd
	FileClose($hSearch)
EndFunc

Func _SteamConfig($sConfigPath, $sUser, $bOffline)
	Local $sConfigData, $sNewConfig, $aSegments, $aSplitLines, $hFile

	$sConfigData = StringRegExpReplace(FileRead($sConfigPath), '("mostrecent"\h+)"1"', '\1"0"') ; Set all users "mostrecent" to "0"

	$aSegments = StringRegExp($sConfigData, '(?ms)^(.+{)(.*?"AccountName"\h*"'& $sUser & '".*?)(}.+)$', 1)
	If UBound($aSegments) = 3 Then
		$sNewConfig = $aSegments[0]

		$aSplitLines = StringSplit($aSegments[1], @LF)
		For $i = 1 To $aSplitLines[0]
			If Not (StringInStr($aSplitLines[$i], '"AccountName"') Or _
				StringInStr($aSplitLines[$i], '"PersonaName"')) Then ContinueLoop
			$sNewConfig &= $aSplitLines[$i] & @LF
		Next

		$sNewConfig &= StringFormat('\t\t"mostrecent"\t\t"1"\n\t\t"RememberPassword"\t\t"1"\n\t\t"Timestamp"\t\t"%d"\n', _DateDiff('s', '1970/01/01 00:00:00', _NowCalc()))

		If $bOffline Then $sNewConfig &= StringFormat('\t\t"WantsOfflineMode"\t\t"1"\n\t\t"SkipOfflineModeWarning"\t\t"1"\n')

		$sNewConfig &= $aSegments[2]

		$hFile = FileOpen($sConfigPath, 2)
		If $hFile <> -1 Then
			FileWrite($hFile, $sNewConfig)
			FileClose($hFile)
			Return 1
		Else
			Return 0
		EndIf
	Else
		Return 0
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
		'    /NoNumbers -- Removes the prefixed shortcut numbers on each username.' & @CRLF & _
		'    /AvatarSize=## -- Sets the size of the avatars displayed (Also adjusts username text size; default is 64).' & @CRLF & _
		'    /AutoLogin=USERNAME -- Auto logs in the user, kind of defeats the purpose of the application but could be useful for some.' & @CRLF & _
		'    /Offline -- Sets connection mode to Offline by default.' & @CRLF & _
		'    /Online -- Sets connection mode to Online by default.' & @CRLF & _
		'    /Extra -- Start UI with extra options revealed.' & @CRLF & _
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

	$hGUIAdd = GUICreate('Add Users', 200, 200, Default, Default, $WS_CAPTION, Default, $hMain)
	GUICtrlCreateLabel(' One user per line:', 0, 0, 200, 20, $SS_CENTERIMAGE)
	$ed_Users = GUICtrlCreateEdit(StringReplace(StringStripWS($sPrefill, 3), ' ', @CRLF), 0, 20, 200, 155)
	$bt_OK = GUICtrlCreateButton('&OK', 80, 175, 60, 25)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 140, 175, 60, 25)
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
					$hFile = FileOpen($CFG_File, 2)
					If $hFile <> -1 Then
						FileWrite($hFile, $aContent[0])
						FileClose($hFile)
						GUIDelete($hGUIAdd)
						GUISetState(@SW_HIDE, $hMain)
						Run(@AutoItExe & ' ' & $CmdLineRaw)
						Exit
					Else
						MsgBox(0x2010, 'Error', 'Cannot write to config file:' & @LF & $CFG_FILE, 0, $hGUIAdd)
					EndIf
					ExitLoop
				EndIf
			Case $bt_Cancel, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hGUIAdd)
EndFunc

Func _GetWinOffset($hWnd)
	Local $aPos, $aClient
	$aPos = WinGetPos($hWnd)
	$aClient = WinGetClientSize($hWnd)
	Local $aReturn[2] = [ $aPos[2] - $aClient[0], $aPos[3] - $aClient[1] ]
	Return $aReturn
EndFunc

Func _GetAvatar($sUsername)
	Local $sDefault = $CFG_PATH & 'No Avatar.jpg', _
		$sAvatar = $CFG_PATH & $sUsername & '.jpg', _
		$sHTML, $sSessionID, $aRegEx, $sAvatarURL
	Local Enum $ERR_NOPROFILE = 1, $ERR_NOSEARCH, $ERR_NOSESSION

	If Not FileExists($sAvatar) Then
		$sHTML = BinaryToString(InetRead('https://steamcommunity.com/id/' & $sUsername))
		If Not $sHTML Then Return SetError($ERR_NOPROFILE, 0, $sDefault)

		$sAvatarURL = _GetAvatar_FromHTML($sHTML)
		If @error Then Return SetError(1, 0, $sDefault)
		InetGet($sAvatarURL, $sAvatar)
	EndIf

	Return $sAvatar
EndFunc

Func _GetAvatar_FromHTML(ByRef $sHTML)
	Local $aAvRange[2]
	$aAvRange[0] = StringInStr($sHTML, 'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/')
	If $aAvRange[0] Then
		$aAvRange[1] = StringInStr($sHTML, '_full.jpg', 0, 1, $aAvRange[0])-$aAvRange[0]
		If $aAvRange[1] Then Return StringMid($sHTML, $aAvRange[0], $aAvRange[1]) & '_medium.jpg'
	EndIf
	Return SetError(1)
EndFunc

#CS
Func _GetAvatar($sUsername)
	Local $sDefault = $CFG_PATH & 'No Avatar.jpg', _
		$sAvatar = $CFG_PATH & $sUsername & '.jpg'
	Local $sHTML, $sSessionID, $aRegEx, $sAvatarURL
	Local Enum $ERR_NOPROFILE = 1, $ERR_NOSEARCH, $ERR_NOSESSION

	If Not FileExists($sAvatar) Then
		$sHTML = BinaryToString(InetRead('https://steamcommunity.com/id/' & $sUsername))
		If Not $sHTML Then Return SetError($ERR_NOPROFILE, 0, $sDefault)

		$sAvatarURL = _GetAvatar_FromHTML($sHTML)
		If @error Then Return SetError(1, 0, $sDefault)
			$sHTML = BinaryToString(InetRead('https://steamcommunity.com/search/users/'))
			If Not $sHTML Then Return SetError($ERR_NOSEARCH)

			$aRegEx = StringRegExp($sHTML, 'g_sessionID = "([[:xdigit:]]+)";', 1)
			If @error Then Return SetError($ERR_NOSESSION)

			$sHTML = BinaryToString(InetRead('https://steamcommunity.com/search/SearchCommunityAjax?text=' & $sUsername & '&filter=users&sessionid=' & $aRegEx[0] & '&steamid_user=false'))
			$sAvatar = _GetAvatar_FromHTML($sHTML)
			Return $sHTML
		EndIf
		Return SetExtended(1, InetGet($sAvatarURL, $sAvatar, 0, 1))
	EndIf

	Return $sAvatar
EndFunc
#CE
