#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=SteamSwitch.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=SteamSwitch
#AutoIt3Wrapper_Res_Description=SteamSwitch
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_Icon_Add=SteamSwitch1.ico
#AutoIt3Wrapper_Res_Icon_Add=SteamSwitch2.ico
#AutoIt3Wrapper_Res_Icon_Add=SteamSwitch3.ico
#AutoIt3Wrapper_Res_Icon_Add=SteamSwitch4.ico
#AutoIt3Wrapper_Res_Icon_Add=SteamSwitch5.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <GuiEdit.au3>


Opt('MustDeclareVars', 1)

Global Const $REG_KEY = 'HKCU\Software\Valve\Steam'
Global Const $STEAM_EXE = RegRead($REG_KEY, 'SteamExe')
Global Const $REG_USERNAME = 'AutoLoginUser'
Global Const $REG_REMPASS = 'RememberPassword'
Global Const $CFG_PATH = @AppDataDir & '\SteamSwitch\'
Global Const $CFG_FILE = $CFG_PATH & 'SteamSwitch.cfg'

Main()
Func Main()
	DirCreate($CFG_PATH)

	FileInstall('Waiting.ani', $CFG_PATH & 'Waiting.ani', 1)
	FileInstall('SteamSwitch_Default.jpg', $CFG_PATH & 'No Avatar.jpg')

	Opt('GUIResizeMode', $GUI_DOCKALL)
	Local $aUsers = FileReadToArray($CFG_FILE), $sUserCheck
	For $i = 0 To UBound($aUsers)-1
		If StringRegExp($aUsers[$i], '^\w+$') Then $sUserCheck &= ' ' & $aUsers[$i]
	Next
	$aUsers = StringSplit(StringStripWS($sUserCheck, 3), ' ', 2)
	If @error Then $aUsers = ''

	Local $GM, $iUserCnt = UBound($aUsers), $iSteamPID, $sAvatarCheck, _
		$aWinOffset, $iMeasureWidth = 0, $iMeasureHeight = 0, $aCtrlPos, _
		$hGUIMain, $hGUIWait, $aRange[2], $bt_AddMore, $lb_Wait, _
		$aUserList[$iUserCnt][4]
	Local Enum $LI_USER, $LI_GETAV, $LI_PIC, $LI_BTN

	$hGUIMain = GUICreate('Steam Switcher', 400, 400, Default, Default, $WS_CAPTION, BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST))
	$aWinOffset = _GetWinOffset($hGUIMain)
	GUISetFont(24)

	$aRange[0] = GUICtrlCreateDummy()
	For $i = 0 To $iUserCnt-1
		$aUserList[$i][$LI_USER] = $aUsers[$i]
		$sAvatarCheck = $CFG_PATH & $aUsers[$i] & '.jpg'
		If Not FileExists($sAvatarCheck) Then
			$aUserList[$i][$LI_GETAV] = True
			$sAvatarCheck = $CFG_PATH & 'No Avatar.jpg'
		EndIf
		$aUserList[$i][$LI_PIC] = GUICtrlCreatePic($sAvatarCheck, 0, $i * 64, 64, 64)
		$aUserList[$i][$LI_BTN] = GUICtrlCreateButton(' ' & $aUsers[$i] & ' ', 64, $i * 64, Default, 64, $BS_FLAT)
		$aCtrlPos = ControlGetPos($hGUIMain, '', $aUserList[$i][$LI_BTN])
		$iMeasureWidth = $iMeasureWidth > $aCtrlPos[2] ? $iMeasureWidth : $aCtrlPos[2]
	Next
	$aRange[1] = GUICtrlCreateDummy()

	For $i = 0 To $iUserCnt-1
		GUICtrlSetPos($aUserList[$i][$LI_BTN], Default, Default, $iMeasureWidth)
	Next

	If Not $iUserCnt Then $iMeasureWidth = 100

	$iMeasureWidth += 64
	$iMeasureHeight = 64 * $iUserCnt

	$bt_AddMore = GUICtrlCreateButton('&Add Users', 0, $iMeasureHeight, $iMeasureWidth, 25)
		GUICtrlSetFont(-1, 9)

	$iMeasureHeight += 25

	WinMove($hGUIMain, '', _
		0.5*(@DesktopWidth - ($iMeasureWidth + $aWinOffset[0])), _
		0.5*(@DesktopHeight - ($iMeasureHeight + $aWinOffset[1])), _
		$iMeasureWidth + $aWinOffset[0], $iMeasureHeight + $aWinOffset[1])
	GUISetState()

	$hGUIWait = GUICreate('', 200, 100, Default, Default, BitOR($WS_POPUP, $WS_BORDER), Default, $hGUIMain)
	$lb_Wait = GUICtrlCreateLabel('Closing steam...', 0, 10, 200, 30, $SS_CENTER)
	GUICtrlCreateIcon($CFG_PATH & 'Waiting.ani', 0, (200-32)/2, 40, 32, 32)

	GUICtrlSetState($bt_AddMore, $GUI_FOCUS)

	Local $iCheckAvs
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
						If RegRead($REG_KEY, $REG_USERNAME) <> $aUserList[$i][$LI_USER] Then
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
										GUISetState(@SW_HIDE, $hGUIWait)
										GUISetState(@SW_ENABLE, $hGUIMain)
										ExitLoop 2
									Else
										ContinueLoop
									EndIf
								WEnd
							EndIf
							RegWrite($REG_KEY, $REG_USERNAME, 'REG_SZ', $aUserList[$i][$LI_USER])
						EndIf
						RegWrite($REG_KEY, $REG_REMPASS, 'REG_DWORD', 1)
						Run($STEAM_EXE)
						Exit
					EndIf
				Next

			Case $bt_AddMore
				GUISetState(@SW_DISABLE, $hGUIMain)
				_AddUsers($hGUIMain, $sUserCheck)
				GUISetState(@SW_ENABLE, $hGUIMain)
				WinActivate($hGUIMain)

			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
EndFunc

Func _AddUsers($hMain, $sPrefill)
	Local $hGUI, $ed_Users, $bt_OK, $bt_Cancel, $GM

	$hGUI = GUICreate('Add Users', 200, 200, Default, Default, $WS_CAPTION, Default, $hMain)
	GUICtrlCreateLabel(' One user per line:', 0, 0, 200, 20, $SS_CENTERIMAGE)
	$ed_Users = GUICtrlCreateEdit(StringReplace(StringStripWS($sPrefill, 3), ' ', @CRLF), 0, 20, 200, 155)
	$bt_OK = GUICtrlCreateButton('&OK', 80, 175, 60, 25)
	$bt_Cancel = GUICtrlCreateButton('Cancel', 140, 175, 60, 25)
	GUISetState()

	_GUICtrlEdit_SetSel($ed_Users, _GUICtrlEdit_GetTextLen($ed_Users), _GUICtrlEdit_GetTextLen($ed_Users))

	While 1
		$GM = GUIGetMsg()
		Switch $GM
			Case $bt_OK
				Local $hFile = FileOpen($CFG_File, 2)
				If $hFile <> -1 Then
					FileWrite($hFile, GUICtrlRead($ed_Users))
					FileClose($hFile)
					GUIDelete($hGUI)
					GUISetState(@SW_HIDE, $hMain)
					Run(@AutoItExe)
					Exit
				Else
					MsgBox(0x2010, 'Error', 'Cannot write to config file:' & @LF & $CFG_FILE, 0, $hGUI)
				EndIf
				ExitLoop
			Case $bt_Cancel, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hGUI)
EndFunc

Func _GetWinOffset($hWnd)
	Local $aPos, $aClient
	$aPos = WinGetPos($hWnd)
	$aClient = WinGetClientSize($hWnd)
	Local $aReturn[2] = [ $aPos[2] - $aClient[0], $aPos[3] - $aClient[1] ]
	Return $aReturn
EndFunc

;~ Func _GetAvatar($sUsername)
;~ 	Local $sDefault = $CFG_PATH & 'No Avatar.jpg', _
;~ 		$sAvatar = $CFG_PATH & $sUsername & '.jpg'
;~ 	Local $sHTML, $sSessionID, $aRegEx, $sAvatarURL
;~ 	Local Enum $ERR_NOPROFILE = 1, $ERR_NOSEARCH, $ERR_NOSESSION

;~ 	If Not FileExists($sAvatar) Then
;~ 		$sHTML = BinaryToString(InetRead('https://steamcommunity.com/id/' & $sUsername))
;~ 		If Not $sHTML Then Return SetError($ERR_NOPROFILE, 0, $sDefault)

;~ 		$sAvatarURL = _GetAvatar_FromHTML($sHTML)
;~ 		If @error Then Return SetError(1, 0, $sDefault)
;~ #CS
;~ 			$sHTML = BinaryToString(InetRead('https://steamcommunity.com/search/users/'))
;~ 			If Not $sHTML Then Return SetError($ERR_NOSEARCH)

;~ 			$aRegEx = StringRegExp($sHTML, 'g_sessionID = "([[:xdigit:]]+)";', 1)
;~ 			If @error Then Return SetError($ERR_NOSESSION)

;~ 			$sHTML = BinaryToString(InetRead('https://steamcommunity.com/search/SearchCommunityAjax?text=' & $sUsername & '&filter=users&sessionid=' & $aRegEx[0] & '&steamid_user=false'))
;~ 			$sAvatar = _GetAvatar_FromHTML($sHTML)
;~ 			Return $sHTML
;~ 		EndIf
;~ #CE
;~ 		Return SetExtended(1, InetGet($sAvatarURL, $sAvatar, 0, 1))
;~ 	EndIf

;~ 	Return $sAvatar
;~ EndFunc

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
