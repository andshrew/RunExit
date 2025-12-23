program Runexit;

{$D-,I-,L-,R-,S-,Y-}

uses
  Forms, ShellApi, SysUtils, WinProcs, WinTypes, ToolHelp;

var
  h: Word;
  reParam, reValue: String;
  pathName: String;
  fileName: String;
  params: String;
  errorMsg: String;
  i, num, pathIdx, nCmdShow: Integer;
  delaySeconds: Integer;
  ticks: LongInt;
  logEnabled: Boolean;
  logPath: String;
  logFile: Text;
  version: String;
  exitEnabled, moduleFound: Boolean;
  module: TModuleEntry;
  moduleName, modulePath, originalPath: String;
  specificModule: String;
  specificMatchEnabled, broadMatchEnabled: Boolean;
  isDriveRoot: Boolean;

procedure WriteLog(const msg: string);
begin
  if logEnabled then begin
    Append(logFile);
    Writeln(logFile, msg);
    CloseFile(logFile);
  end;
end;

begin
  { Set defaults }
  nCmdShow := SW_SHOWNORMAL;
  delaySeconds := 0;
  version := '{{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}';
  logPath := '\runexit.log';
  logEnabled := False;
  exitEnabled := False;
  specificMatchEnabled := False;
  broadMatchEnabled := False;
  isDriveRoot := False;

  { Look for slash-options before the path param and handle them }
  pathIdx := 1;
  while ((pathIdx < paramCount) and (ParamStr(pathIdx)[1] = '/')) do
  begin
    { Split slash opts at equal sign }
    i := Pos ('=', ParamStr(pathIdx));
    if (i = 0) then i := Length(ParamStr(pathIdx)) + 1;
    reParam := UpperCase(Copy(ParamStr(pathIdx), 2, i - 2));
    reValue := Copy(ParamStr(pathIdx), i + 1, Length(ParamStr(pathIdx)) - i);

    { Test each option type and extract its value }
    if (reParam = 'SHOW') then
    begin
      num := StrToIntDef(reValue, -1);
      if ((num >= 0) and (num <= 11)) then nCmdShow := num;
    end
    else if (reParam = 'DELAY') then
    begin
      num := StrToIntDef(reValue, 0);
      if ((num >= 0) and (num <= 30)) then delaySeconds := num;
    end
    else if (reParam = 'PWD') then
    begin
      pathName := reValue;
      { Ensure path doesn't end with a backslash }
      { Unless we're at the root ie. C:\ }
      if (Length(pathName) > 3) and (pathName[Length(pathName)] = '\') then
        Delete(pathName, Length(pathName), 1);
    end
    else if (reParam = 'LOG') then
    begin
      Assign(logFile, logPath);
      Rewrite(logFile);
      if IOResult = 0 then
      begin
        logEnabled := True;
        CloseFile(logFile);
        WriteLog(Format('RunExit version: %s', [version]));
        WriteLog('https://github.com/andshrew/RunExit');
        if pathIdx <> 1 then
          WriteLog('/log should be the first parameter if you want to capture all output');
        WriteLog('Command line parameters:')
      end else begin
        errorMsg := Format(
          'Unable to create log file:' + #13#10 + '%s', [logPath]);
        MessageBox(0, @errorMsg [1], 'Log Error', MB_OK);
      end;
    end
    else if (reParam = 'MODULE') then
    begin
      if Length(reValue) > 0 then begin
        specificModule := UpperCase(reValue);
        specificMatchEnabled := True;
      end;
    end
    else if (reParam = 'MATCHALL') then
    begin
      broadMatchEnabled := True;
    end
    else if (reParam = 'LEGACY') then
    begin
      { Module matching disabled }
      exitEnabled := True;
    end;
    WriteLog(Format('   Parameter %d: %s Value: %s', [pathIdx, reParam, reValue]));

    Inc(pathIdx);
  end;

  if specificMatchEnabled then begin
    WriteLog('Specific module matching enabled');
    WriteLog(Format('Will only match with module %s once the original application has ended', [specificModule]));
  end;

  { Add delay if requested }
  if delaySeconds > 0 then
  begin
    { Calculate the end time }
    ticks := GetTickCount + (delaySeconds * 1000);
    WriteLog(Format('Application start delayed by %d second(s)', [delaySeconds]));
    repeat
      Application.ProcessMessages;
    until GetTickCount >= ticks;
  end;

  { Split first parameter into path and filename }
  i := Pos ('\', ParamStr (pathIdx));
  if (i > 0) and (pathName = '') then
  begin
    { Make it a path, find last occurrence of directory separator }
    pathName := ParamStr (pathIdx);
    i := (StrRScan (@pathName [1], '\') - @pathName [1]) + 1;
    fileName := Copy (pathName, i + 1, Length (pathName) - i);
    { Remove the trailing directory separator from path }
    { Unless we're at the root ie. C:\ }
    if pathName [i - 1] <> ':' then begin i := i - 1 end;
    pathName := Copy (pathName, 1, i);
  end else begin
    fileName := ParamStr (pathIdx);
  end;
  WriteLog(Format('Application executable: %s', [fileName]));
  WriteLog(Format('Application path: %s', [pathName]));

  { Concatenate any remaining parameters }
  WriteLog('Application parameters:');
  Inc(pathIdx);
  num := ParamCount;
  for i := pathIdx to num do
  begin
    if (i > pathIdx) then params := params + ' ';
    params := params + ParamStr (i);
    WriteLog(Format('   %s', [ParamStr(i)]));
  end;

  { Add trailing NUL bytes }
  fileName := fileName + #0;
  originalPath := UpperCase(pathName);
  pathName := pathName + #0;
  params := params + #0;

  { Execute the command }
  h := ShellExecute (0, nil, @fileName [1], @params [1], @pathName [1], nCmdShow);
  if (h <= 32) then
  begin
    { A return value less than or equal to 32 specifies an error }
    errorMsg := Format(
      'Unable to start application' + #13#10 + 'ShellExecute error code: %d', [h]);
    MessageBox(0, @errorMsg [1], 'Windows API Error', MB_OK);
  end;
  if (h > 32) then
  begin
    { Wait for it to complete }
    WriteLog('Application has started');
    repeat
      repeat
        Application.ProcessMessages;
      until GetModuleUsage (h) = 0;
      if exitEnabled then break;
      { Handle count is now 0 }
      WriteLog(Format('Handle count is now zero indicating it is longer active, searching for related modules', [h]));
      if originalPath[Length(originalPath) - 1] = ':' then begin
        if (not broadMatchEnabled) and (not specificMatchEnabled) then begin
          isDriveRoot := True;
          WriteLog('Module matching from the drive root is not supported');
          WriteLog('A list of currently loaded modules will follow');
          WriteLog('Either re-run using parameter /module module-name to match a specific module');
          WriteLog('or re-run using parameter /matchall to match all non-System modules');
        end;
      end;
      FillChar(module, SizeOf(module), 0);
      module.dwSize := SizeOf(module);
      if ModuleFirst(@module) then begin
        moduleFound := False;
        WriteLog('Loaded modules:');
        WriteLog('   System modules and RunExit are excluded from this list');
        repeat
          { Iterate through all loaded modules to try
            and identify any that may be related to the
            application }
          moduleName := '';
          modulePath := '';
          try
            moduleName := StrPas(module.szModule);
          except
            moduleName := '(Unknown)';
          end;
          try
            modulePath := StrPas(module.szExePath);
          except
            modulePath := '';
          end;

          { Check for '/' instead of '\' in the path }
          if Pos('/', modulePath) > 0 then begin
            for i := 1 to Length(modulePath) do
            begin
              if modulePath[i] = '/' then
                modulePath[i] := '\';
            end;
          end;

          if specificMatchEnabled then begin
            if Pos(specificModule, moduleName) > 0 then begin
              { This module has matched via the /module command line parameter }
              WriteLog('Found related module from command line /module:');
              moduleFound := True;
              break;
            end;
            { If no match then continue to the next module }
            continue;
          end;

          if moduleName = 'RUNEXIT' then continue;
          if moduleName = 'PROGMAN' then continue;
          if Pos('\WINDOWS\', modulePath) > 0 then continue;

          WriteLog(Format('   Name: %s Count: %d Path: %s', [moduleName, GetModuleUsage(module.hModule), modulePath]));

          if isDriveRoot then continue;

          if Pos(originalPath, modulePath) > 0 then begin
            { This module is likely related to the application as the path matches }
            WriteLog('Found related module:');
            moduleFound := True;
            break;
          end;

          if broadMatchEnabled then begin
            { Match any module which isn't a system application }
            WriteLog('Found alternative module via broad match from command line /matchall:');
            moduleFound := True;
            break;
          end;
        until not ModuleNext(@module);
      end else begin
        WriteLog('Unable to access loaded modules');
        exitEnabled := True;
      end;
      if moduleFound then begin
        h := module.hModule;
        WriteLog(Format('   Module: %s' , [moduleName]));
        WriteLog(Format('   Handle: %d Path: %s', [h, modulePath]));
      end else begin
        WriteLog('No related module found');
        exitEnabled := True;
      end;
    until exitEnabled;
    WriteLog('Application has ended');
    { And shut down Windows }
    { But sometimes Windows does not successfully exit first try... }
    { This repeats the request for ~10 seconds before giving up }
    ticks := GetTickCount + 10000;
    repeat
      Application.ProcessMessages;
      ExitWindows (0, 0);
    until GetTickCount > ticks;
    WriteLog('Unable to exit Windows within time limit');
    MessageBox(0, 'Unable to Exit Windows', 'RunExit Error', MB_OK);
  end;
end.
