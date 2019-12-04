# Welcome to Steam Switch!

This application lets you login/**switch** to different Steam accounts without having to re-enter your password. It only requires that you've logged in at least once before (and told Steam to remember your password).

This application doesn't ask for or store your passwords, it relies on Steam's password memory. Theoretically you will only have to re-enter your password if you manually sign out of Steam or it's settings get lost or changed. I have personally used the app for months without having to re-enter a password.

## Quick Start Guide:

1. Click the "Manage Users" button. You will be presented with a window with a text entry and some buttons. You can enter usernames or press the "Grab Usernames" button and try to auto grab usernames from the Steam config files.
2. When you press OK the program will reopen with the users listed with their avatars (they may take a few moments to download).
3. Now you can just click on whichever user you want to log in as.
	- You can also right-click a user for a menu with online/offline start options.

## Usage Notes:

#### If Steam is running on launch:
A button will appear at the top of the switcher window showing which user is currently active and if Steam is in offline mode. Clicking this will show a menu with some options (open/close Steam, restart on/offline).

- If you click the same user that Steam is already running as, the Steam window will just open.

- If you click a different user, Steam will close and relaunch as the chosen user. The close dialog will retry closing Steam every 10 seconds. If Steam refuses to close you can click the "Force Close" button.

#### Extra Options:
You can have the Extra Options revealed on launch by using the "/extra" command line parameter.

You can specify the connection mode (default, online, offline) for when you click on a user. The default selection can be changed with a command line parameter (/offline, /online).

You can reload all the avatars (deletes all stored files and re-downloads), or open the avatar storage folder.

#### Note on avatars:
The application looks for avatars at the default profile URL (https://steamcommunity.com/id/USERNAME). If this page is inaccessible a username search is performed and the first resulting avatar is downloaded. If no avatar can be found at all, a 0 byte file is stored in place of the normal avatar (to prevent future fruitless searches) and a generic avatar will be displayed.

If you want to reload an individual user's avatar, right click their name and select "Reload Avatar".

If you want to manually set an avatar, open the storage folder (Click the "Open Avatar Folder" button under "Extra Options" or navigate Explorer to "%appdata%\therkSoft\SteamSwitch\avatars") and replace the user's avatar with whatever jpg, gif, or bmp image you want. It just has to be named as USERNAME.EXT (EXT can be BMP, JPG, or GIF).

#### Command line parameters:
- /al, /AutoLogin=USERNAME -- Auto logs in the user, useful for shortcuts.
- /as, /AvatarSize=## -- Sets the size of the avatars displayed (default 64).
- /of, /Offline -- Sets connection mode to Offline by default.
- /on, /Online -- Sets connection mode to Online by default.
- /dn, /DoNumbers -- Add prefixed shortcut numbers on each username (this setting replaced the old NoNumbers param. Now by default there are no numbers).
- /am, /AtMouse -- Starts UI centered on mouse position.
- /in, /Indicator -- Size of the offline/online indicator (red/green underline of each username; default 2; set to 0 to hide).
- /ex, /Extra -- Starts UI with Extra Options panel revealed.

Any other command line parameters will be passed on to Steam itself. Some handy options are:
* -silent -- Suppresses the dialog box that opens when you start steam.
* -tenfoot -- Start Steam in Big Picture Mode.
* -noverifyfiles -- Prevents the client from checking files integrity.

For a full list of Steam parameters read here: https://developer.valvesoftware.com/wiki/Command_Line_Options#Steam_.28Windows.29

So for example, if you wanted to create a shortcut that started Steam as "FunFrank" in offline and Big Picture mode, you would create a shortcut to this target:
```
"X:\Path\To\SteamSwitch.exe" /autoLogin=FunFrank /offline -tenfoot
```
or:
```
"X:\Path\To\SteamSwitch.exe" /al=FunFrank /of -tenfoot
```

#### Uninstall:
Any and all data stored by the application is in an AppData subfolder, so if you want to uninstall then just delete the program and this folder:
```
%AppData%\therkSoft\SteamSwitch\
```

------------------------------------------------------------

### Change log:

##### v1.5.1:

- Forgot to test the deferred pic creation with tabs, doesn't work properly, so just removed it.
- Added config migration (whoops, forgot to include with v1.5).
- Changed "Add/Edit Users" to "Manage Users".
- Change unfocused auto-close. Was getting too many erroneous exits. Now waits 100ms before closing.
- Changed all child GUI handles to static vars and hide/show instead of deleting/creating every time.
- Added some online/offline indicators for each user (so can tell right away how it will log in). Customize size with parameter (/indicator=#, /in=#).
- Detect and reveal when the "Steam - Offline Mode" window is hidden, which prevents Steam from launching normally. This happens when you click the [x] instead of one of the buttons.
- Added function to detect if 'steam.exe' process matches file path of Steam acquired from registry.
- Different waiting animation for SteamClose window.
- Added detection for other avatar file types (jpg, gif, bmp) if users want to customize avatars.
- Added "Grab Usernames" button to Manage users dialog. This will check the Steam loginusers.vdf file for any AccountNames and add them to the list.
- Dropped extra icons from compiled version.

##### v1.5:

- Added context menu for user buttons (start offline/online, reload avatar).
- Added tab pages when user buttons take up too much space (scrollwheel changes tabs).
- Updated images used for default (downloading) and missing avatars.
- Redesigned Add Users dialog.
- Added method to search for avatar if user doesn't have Custom URL set in their profile.
- Changed avatar downloading procedure.
- Added individual avatar reload capability, also changed the procedure for avatar reload.
- Show banner with context menu at top of window when Steam is running.
- Moved Steam shutdown code out of _SteamLogin into new function (_SteamClose).
- Enforced max window dimensions (about 80% width, 70% height).
- Changed config folder structure. Put avatars in their own subfolder (easier to clear/reload), changed userlist filename.
- Renamed some variables, moved some into global scope (needed for outside functions).
- Changed _SteamConfig function. Now using StringRegExpReplace to adjust values rather than discarding/rewriting sections of the config.
- Run _SteamConfig on every launch to ensure Timestamp value is always current (theoretically preventing password expiration).
- Warn if _SteamConfig fails (could not find user in file, or could not write to file: loginusers.vdf).
- Added lots of commentary.
