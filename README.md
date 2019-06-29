# SteamSwitch
Profile switching utility for Steam client

This application lets you switch Steam profiles/logins without having to retype your password all the time, so long as you've normally logged in at least once before.
The application doesn't store your passwords anywhere and never asks for them. Instead it relies on Steam's built in password memory. The only data it actually stores is the list of usernames that you provide and the publicly available avatars of said users.
Theoretically you will only have to re-enter your password if Steam's settings get lost or changed. I personally used the app for months without having to re-enter my password.

To get started, click the Add/Edit Users button.
You will be presented with a text box. Type in the usernames you want to be able to switch between, one on each line, and hit OK. The program will close and reopen with all your chosen usernames and their avatars listed (they may take a few seconds to download).
Now click on the user you want to log in as.
If Steam is already running as that user it will simply open/refocus the Steam window. If Steam is running as another user, it will be closed gracefully and relaunched as the chosen user (if for some reason Steam will not close within 15 seconds you will be prompted to wait longer or to cancel).
If you want Steam to start in offline mode (or conversely online mode if it was last run in offline mode) then you can click the Extra Options button at the bottom of the window to see those options. This setting will restart Steam regardless of whether the chosen user is already logged in.
There is also a button in the Extra Options to reload avatars. This simply deletes all the stored avatars then relaunches the application which then re-downloads them.

Command line parameters:
* /NoNumbers -- Removes the prefixed shortcut numbers on each username.
* /AvatarSize=## -- Sets the size of the avatars displayed (Also adjusts username text size; default is 64).
* /AutoLogin=USERNAME -- Auto logs in the user, kind of defeats the purpose of the application but could be useful for some.
* /Offline -- Sets connection mode to Offline by default.
* /Online -- Sets connection mode to Online by default.

Any other command line parameters will be passed on to Steam itself. Some handy options are:
* -silent -- Suppresses the dialog box that opens when you start steam.
* -tenfoot -- Start Steam in Big Picture Mode.
* -noverifyfiles -- Prevents the client from checking files integrity.
* For a full list of parameters read here: https://developer.valvesoftware.com/wiki/Command_Line_Options#Steam_.28Windows.29

So for example, if you wanted to create a shortcut that started Steam as "FunFrank" in offline and Big Picture mode, you would create a shortcut to this target:
	"x:\path_to_application\SteamSwitch.exe" /autoLogin=FunFrank /offline -tenfoot

Any and all data stored by the application is in AppData, so if you want to "uninstall" then just delete SteamSwitch.exe and any files in the following folder:
	%appdata%\therkSoft\SteamSwitch\
