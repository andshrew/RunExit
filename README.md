# RunExit
`RUNEXIT.EXE` is a simple 16-bit Windows utility intended to run a single application and immediately exit Windows after that application quits.

It is ideal for use with emulation systems like DOSBox, where you may want to be able to launch a Windows game (or application) and have it automatically start and then exit once the program has finished.

This has been tested with DOSBox 0.74 and DOSBox-X 2024.03.01 using their native DOS implementations, with Windows 3.1.

# Origins
This is a fork of version 1.1 of the application (26th May 2013), written by [Steven Henk Don](https://www.shdon.com/about).

https://www.shdon.com/software/tools  

https://www.shdon.com/files/runexit.zip

This [tag](https://github.com/andshrew/RunExit/releases/tag/v1.1) contains [the original source code of version 1.1](https://www.shdon.com/files/runexit.src.zip) along with a build of the release. The original source is redistributed with the permission of Steven, and subsequent changes within this fork of the code are released under the MIT License.

# Table of Contents

* [Changes from original version](#changes-from-original-version)
* [Usage](#usage)
  * [Basic Usage](#basic-usage)
  * [Command Line Parameters](#command-line-parameters)
  * [Related Module Matching](#related-module-matching)
* [Building from Source](#building-from-source)
* [Technical Quick Reference](#technical-quick-reference)

# Changes from original version

* **Support for identifying when an application switches execution to another process**  
RunExit [v1.5](https://github.com/andshrew/RunExit/releases/tag/v1.5) and prior would launch an application and then exit Windows once the system reported that the application was no longer loaded.  
There are [some applications](https://github.com/andshrew/RunExit/issues/5) that subsequently launch another executable, or perform some other action, which results in the originally launched application being detected as longer being loaded; and so RunExit would attempt exit Windows while that application was still actually running.   
Now when the launched application is reported as no longer being loaded, [RunExit will iterate through all currently loaded modules](#related-module-matching) to try and find any related modules that are loaded. If a related module is found then it will only exit Windows once all related modules are unloaded.  
This change should fix compatibility with a majority of [such applications](https://github.com/andshrew/RunExit/issues/5).  
See [Related Module Matching](#related-module-matching) for additional information.  
_To disable this feature use parameter `/legacy` which reverts application exit behaviour to that of [v1.5](https://github.com/andshrew/RunExit/releases/tag/v1.5) (and prior), see [Disabling Related Module Matching](#disabling-related-module-matching)_. 


* **The trailing `\` is removed from the application directory path**  
When parsing the application path to determine what the working directory should be set to, the original version would include the trailing `\` within the path and pass that through to ShellExecute.  
eg. `C:\MPS\GPM\GPM.EXE` would set the working directory as `C:\MPS\GPM\`  
This version sets the working directory without the trailing `\`:  
`C:\MPS\GPM\GPM.EXE` now sets the working directory as `C:\MPS\GPM`
You can override the path of the working directory if the application needs to run in a different directory than the executable by passing a `/pwd=[path]` parameter to `RUNEXIT.EXE`, before the application path.

* **Exit Windows will keep retrying for ~10 seconds**  
Depending on the application being launched, sometimes the exit from Windows after the application had finished would intermittently (but consistently) fail.  
This version of the application will keep trying to exit Windows for ~10 seconds after the application has finished. If it still cannot exit Windows then it will prompt the user that it has failed.

* **ShellExecute error codes are now displayed**  
If ShellExecute fails to run the application, then a message box is displayed along with the error code. A list of error codes are [here](#error-codes).

* **Application startup behavior can be changed**  
The default application startup `SW_SHOWNORMAL` can be overridden to a different value by passing a `/show=[number]` parameter to `RUNEXIT.EXE`, before the application path. This allows starting the application minimized, maximized, or in the "background" (not activated). A list of valid values are [here](#valid-ncmdshow-values).

* **Optional delay before launching the application**  
A delay (in seconds) can be specified before launching the application by passing a `/delay=[seconds]` parameter to `RUNEXIT.EXE`, before the application path. This is useful if you need to ensure Windows and its drivers are fully initialized before starting the application. The delay can be a maximum of 30 seconds.  
Example: `/delay=5` will wait 5 seconds before launching the application.

* **Optional log file creation**  
To assist with troubleshooting, a log file can be generated by passing a `/log` parameter to `RUNEXIT.EXE` before the application path. This will create `runexit.log` at the root of the default drive (eg. `C:\runexit.log`). If the file already exists then it is overwritten. In order to capture the most amount of detail in the log file, this should be the first parameter that is supplied to `RUNEXIT.EXE`.  
Example: `win C:\runexit\runexit.exe /log c:\mps\gpm\gpm.exe`

# Usage

Download `RUNEXIT.EXE` from the releases page and copy it to your system; these examples will assume that you save it to `C:\RUNEXIT\RUNEXIT.EXE` and that `win` is in your `PATH`.

## Basic Usage

`win C:\runexit\runexit.exe [optional runexit parameters] [path to application] [optional application parameters]`

## Command Line Parameters

| Parameter        | Description | Example |
|------------------|-------------|---------|
| /delay=_[seconds]_                   | Delay launching the application by up to 30 seconds             | [Example](#example-4)         |
| /legacy | Disable related module matching, launched application exit behaviour restored to that of [v1.5](https://github.com/andshrew/RunExit/releases/tag/v1.5) and prior<br>_See [Related Module Matching](#related-module-matching) and [Disabling Related Module Matching](#disabling-related-module-matching)_ | [Example](#disabling-related-module-matching)
| /log | Create `runexit.log` at the root of the default drive (eg. `c:\runexit.log`)<br>_This should be the first parameter set to capture all output_ | [Example](#example-6)
| /matchall | Set the related module matching behaviour to match any loaded module<br>_See [Related Module Matching](#related-module-matching) and [Match Any Loaded Module](#match-any-loaded-module)_ | [Example](#match-any-loaded-module)
| /module=_[name]_ | Set the related module matching  behaviour to only match a specific module<br>_See [Related Module Matching](#related-module-matching) and [Match a Specific Module Name](#match-a-specific-module-name)_ | [Example](#match-a-specific-module-name)
| /pwd=_[path]_ | Set the working directory for the application | [Example](#example-5)
| /show=_[number]_ | Set the initial state of the application window (ie. minimized, maximized)<br>_See [valid nCmdShow values](#valid-ncmdshow-values)_              | [Example](#example-3)         |

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
Run application `C:\CASTLE\CASTLE.EXE` with a 5 second delay before launch.

`win C:\runexit\runexit.exe /delay=5 c:\castle\castle.exe`

## Example 5
Run application `D:\WIN31\RBJR.EXE` with the working directory as `D:\RESOURCE`.

`win C:\runexit\runexit.exe /pwd=D:\resource D:\win31\rbjr.EXE`

## Example 6
Run application `C:\MPS\GPM\GPM.EXE` with parameter `/log`

`win C:\runexit\runexit.exe /log c:\mps\gpm\gpm.exe`

## Example 7
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

## Related Module Matching

When the launched application is reported as being unloaded, RunExit will attempt to find any related modules that may still be running before exiting Windows. If one is found then it is assumed that the launched application is in fact still running, and RunExit will continue to wait until all related modules have ended before finally exiting Windows.  

Modules are matched based on their path, so for example if you launch `C:\SC2K4WIN\SC2000W.EXE` then RunExit will search for loaded modules with `C:\SC2K4WIN` contained within the path.

Matching is disabled when the launched application is located on the root of the drive (ie. `C:\MYGAME.EXE`) because it may match too broadly (ie. false positives). Additionally, any module with `\WINDOWS\` in the path is automatically ignored.

### Changing Matching Behaviour

The default configuration will work for the majority of applications, but there are additional customisation options which can be used to further extend support for specific applications. For example, if a launched application switches execution to a module running from a CDROM the default matching behaviour would not detect this because the paths will not match.

#### Match Any Loaded Module

Using the parameter `/matchall` will prevent RunExit from exiting Windows until all non-system modules have ended (ie. anything that does not contain `\WINDOWS\` in the path).  

Since RunExit and the launched application should be the only programs that are running, this option should work with applications that switch execution to a CDROM or another path. However if this results in RunExit not exiting Windows when you expect, you can use the `/log` parameter to determine which module is still running and try switching to using the [Match a Specific Module Name](#match-a-specific-module-name) method.  

`win C:\runexit\runexit.exe /log /matchall C:\SC2K4WIN\SC2000W.EXE`

#### Match a Specific Module Name

Using the parameter `/module=[name]` instructs RunExit to **only** match to a module named `[name]` once the originally launched application is reported as no longer being loaded. When the named module is also unloaded then it will exit Windows. This option supersedes both the default matching behaviour (ie. path based) and the `/matchall` parameter if that is set. Consequently this means it can match named modules that have a path containing `\WINDOWS\`.

To determine module names, you should first run your application with the `/log` parameter. This will generate a list of all of the loaded modules while your application is running.

`win C:\runexit\runexit.exe /log C:\SC2K4WIN\SC2000W.EXE`

The log will contain output like this:

```
Loaded modules:
   System modules and RunExit are excluded from this list
   Name: SIMCITY Count: 1 Path: C:\SC2K4WIN\SC2000W.WAD
```

The values against `Name:` can be used with the `/module=[name]` parameter to instruct RunExit on which specific module to watch for; in this example `SIMCITY`

`win C:\runexit\runexit.exe /module=SIMCITY C:\SC2K4WIN\SC2000W.EXE`

#### Disabling Related Module Matching

Using the parameter `/legacy` will disable the related module matching feature, and restore application exit behaviour to as it was in version [v1.5](https://github.com/andshrew/RunExit/releases/tag/v1.5) and prior.

Once the launched application is reported as being unloaded, RunExit will immediately exit Windows.

# Building from Source

1. Use a Windows 3.1 system
2. [Install Borland Delphi 1.00](https://winworldpc.com/download/c2b3c3be-c38a-e280-b00b-c38711c3a5ef)
3. Open project `RUNEXIT.DPR` with the Delphi application  
or  
Build from the command line `C:\delphi\bin\dcc.exe c:\runexit\runexit.dpr`

## Set the version variable
The RunExit log file will print the application version, but this needs to be set manually in `RUNEXIT.DPR` by editing line `version := '{{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}';` before compiling the application. Example commands for generating this:

### Set via Bash and sed
```bash
sed -i "s+{{GIT_TAG_NAME}}+$(git describe --tags --exact-match || git symbolic-ref --short HEAD)+g" RUNEXIT.DPR
sed -i "s+{{GIT_COMMIT_REF}}+$(git rev-parse --short HEAD)+g" RUNEXIT.DPR
```

### Set via PowerShell 7
```powershell
(Get-Content RUNEXIT.DPR -Raw) -replace '{{GIT_TAG_NAME}}',$($(git describe --tags --exact-match) ?? $(git symbolic-ref --short HEAD)) | Set-Content RUNEXIT.DPR -NoNewline
(Get-Content RUNEXIT.DPR -Raw) -replace '{{GIT_COMMIT_REF}}',$(git rev-parse --short HEAD) | Set-Content RUNEXIT.DPR -NoNewline
```
### Example output:  
```
version := 'v1.5/cc450de';
```
_These commands prefer to include the current Git tag, but will fall back to the current branch when no tag is available_

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
