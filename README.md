# RunExit
`RUNEXIT.EXE` is a simple 16-bit Windows utility intended to run a single application and immediately exit Windows after that application quits.

It is ideal for use with emulation systems like DOSBox, where you may want to be able to launch a Windows game (or application) and have it automatically start and then exit once the program has finished.

This has been tested with DOSBox 0.74 and DOSBox-X 2024.03.01 using their native DOS implementations, with Windows 3.1.

# Origins
This is a fork of version 1.1 of the application (26th May 2013), written by [Steven Henk Don](https://www.shdon.com/about).

https://www.shdon.com/software/tools  

https://www.shdon.com/files/runexit.zip

This [tag](https://github.com/andshrew/RunExit/releases/tag/v1.1) contains [the original source code of version 1.1](https://www.shdon.com/files/runexit.src.zip) along with a build of the release. The original source is redistributed with the permission of Steven, and subsequent changes within this fork of the code are released under the MIT License.

# Changes from original version

* **The trailing `\` is removed from the application directory path**  
When parsing the application path to determine what the working directory should be set to, the original version would include the trailing `\` within the path and pass that through to ShellExecute.  
eg. `C:\MPS\GPM\GPM.EXE` would set the working directory as `C:\MPS\GPM\`  
This version sets the working directory without the trailing `\`:  
`C:\MPS\GPM\GPM.EXE` now sets the working directory as `C:\MPS\GPM`  

* **Exit Windows will keep retrying for ~10 seconds**  
Depending on the application being launched, sometimes the exit from Windows after the application had finished would intermittently (but consistently) fail.  
This version of the application will keep trying to exit Windows for ~10 seconds after the application has finished. If it still cannot exit Windows then it will prompt the user that it has failed.

* **ShellExecute error codes are now displayed**  
If ShellExecute fails to run the application, then a message box is displayed along with the error code. A list of error codes are [here](#error-codes).

* **Application startup behavior can be changed**  
The default application startup `SW_SHOWNORMAL` can be overridden to a different value by passing a `/show=[number]` parameter to `RUNEXIT.EXE`, before the application path. This allows starting the application minimized, maximized, or in the "background" (not activated). A list of valid values are [here](#valid-ncmdshow-values).

# Usage

Download `RUNEXIT.EXE` from the releases page and copy it to your system; these examples will assume that you save it to `C:\RUNEXIT\RUNEXIT.EXE` and that `win` is in your `PATH`.

## Basic Usage

`win C:\runexit\runexit.exe [optional runexit parameters] [path to application] [optional application parameters]`

## Example 1
Run application `C:\MPS\GPM\GPM.EXE` with no additional parameters.

`win C:\runexit\runexit.exe c:\mps\gpm\gpm.exe`

## Example 2
Run application `C:\GAMES\MYGAME\GAME.EXE` with parameter `/cheatmode`

`win C:\runexit\runexit.exe c:\games\mygame\game.exe /cheatmode`

## Example 3
Run application `C:\WEP\JEZZBALL.EXE` in a maximized window.

`win C:\runexit\runexit.exe /show=3 c:\wep\jezzball.exe`

## Example 4
DOSBox AUTOEXEC to run application `C:\MPS\GPM\GPM.EXE` with no additional parameters.  
On running DOSBox this would load Windows and run the application. Once the application is closed Windows will then exit, and DOSBox will close.

```ini
mount C "data/drive_c"
PATH C:\WINDOWS;
SET TEMP=C:\WINDOWS\TEMP
C:
win C:\runexit\runexit.exe c:\mps\gpm\gpm.exe
exit
```

# Building from Source

1. Use a Windows 3.1 system
2. [Install Borland Delphi 1.00](https://winworldpc.com/download/c2b3c3be-c38a-e280-b00b-c38711c3a5ef)
3. Open project `RUNEXIT.DPR` with the Delphi application  
or  
Build from the command line `C:\delphi\bin\dcc.exe c:\runexit\runexit.dpr`

# Technical Quick Reference

## Windows API ShellExecute

`ShellExecute (0, nil, @fileName [1], @params [1], @pathName [1], nCmdShow);`

| Parameter  | Description                                                                 |
|------------|-----------------------------------------------------------------------------|
| `0`        | Handle to the parent window. `0` for no parent                              |
| `nil`      | The operation to perform<br/>A `null` value will use the default of `open`. |
| `fileName` | Application name eg. `GPM.EXE`                                              |
| `params`   | Application parameters eg. `/cheatmode`                                     |
| `pathName` | Application path eg. `C:\MPS\GPM`                                           |
| `nCmdShow` | State the application window is set to on launch                            |

## Valid `nCmdShow` values
| Value | Name                                 | Meaning                                                                                                                                                                                                                               |
|:-----:|--------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0     | `SW_HIDE`                            | Hides the window and activates another window.                                                                                                                                                                                        |
| 1     | `SW_SHOWNORMAL`<br/>`SW_NORMAL`      | Activates and displays a window. If the window is minimized, maximized, or arranged, the system restores it to its original size and position. An application should specify this flag when displaying the window for the first time. |
| 2     | `SW_SHOWMINIMIZED`                   | Activates the window and displays it as a minimized window.                                                                                                                                                                           |
| 3     | `SW_SHOWMAXIMIZED`<br/>`SW_MAXIMIZE` | Activates the window and displays it as a maximized window.                                                                                                                                                                           |
| 4     | `SW_SHOWNOACTIVATE`                  | Displays a window in its most recent size and position. This value is similar to `SW_SHOWNORMAL`, except that the window is not activated.                                                                                            |
| 5     | `SW_SHOW`                            | Activates the window and displays it in its current size and position.                                                                                                                                                                |
| 6     | `SW_MINIMIZE`                        | Minimizes the specified window and activates the next top-level window in the Z order.                                                                                                                                                |
| 7     | `SW_SHOWMINNOACTIVE`                 | Displays the window as a minimized window. This value is similar to `SW_SHOWMINIMIZED`, except the window is not activated.                                                                                                           |
| 8     | `SW_SHOWNA`                          | Displays the window in its current size and position. This value is similar to `SW_SHOW`, except that the window is not activated.                                                                                                    |
| 9     | `SW_RESTORE`                         | Activates and displays the window. If the window is minimized, maximized, or arranged, the system restores it to its original size and position. An application should specify this flag when restoring a minimized window.           |
| 10    | `SW_SHOWDEFAULT`                     | Sets the show state based on the `SW_` value specified in the `STARTUPINFO` structure passed to the `CreateProcess` function by the program that started the application.                                                             |
| 11    | `SW_FORCEMINIMIZE`                   | Minimizes a window, even if the thread that owns the window is not responding. This flag should only be used when minimizing windows from a different thread.                                                                         |

_Taken from [Microsoft documentation for `ShowWindow()` in the Windows API](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow#parameters)_

## Error Codes

| Value | Meaning                                                                                                                             |
|:-----:|-------------------------------------------------------------------------------------------------------------------------------------|
|   0   | System was out of memory, executable file was corrupt, or relocations were invalid.                                                 |
|   2   | File was not found.                                                                                                                 |
|   3   | Path was not found.                                                                                                                 |
|   5   | Attempt was made to dynamically link to a task, or there was a sharing or network-protection error.                                 |
|   6   | Library required separate data segments for each task.                                                                              |
|   8   | There was insufficient memory to start the application.                                                                             |
|   10  | Windows version was incorrect.                                                                                                      |
|   11  | Executable file was invalid. Either it was not a Windows application or there was an error in the .EXE image.                       |
|   12  | Application was designed for a different operating system.                                                                          |
|   13  | Application was designed for MS-DOS 4.0.                                                                                            |
|   14  | Type of executable file was unknown.                                                                                                |
|   15  | Attempt was made to load a real-mode application (developed for an earlier version of Windows).                                     |
|   16  | Attempt was made to load a second instance of an executable file containing multiple data segments that were not marked read-only.  |
|   19  | Attempt was made to load a compressed executable file. The file must be decompressed before it can be loaded.                       |
|   20  | Dynamic-link library (DLL) file was invalid. One of the DLLs required to run this application was corrupt.                          |
|   21  | Application requires Microsoft Windows 32-bit extensions.                                                                           |
|   31  | No association for the specified file type or if there is no association for the specified action within the file type.             |

_API references from the Borland Windows API Windows 3.1 Reference Guide Volume 3 1992_
