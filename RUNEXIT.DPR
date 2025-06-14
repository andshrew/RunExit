program Runexit;

{$D-,I-,L-,R-,S-,Y-}

uses
  Forms, ShellApi, SysUtils, WinProcs, WinTypes;

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

begin
  { Set defaults }
  nCmdShow := SW_SHOWNORMAL;
  delaySeconds := 0;

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
    end;

    Inc(pathIdx);
  end;

  { Add delay if requested }
  if delaySeconds > 0 then
  begin
    { Calculate the end time }
    ticks := GetTickCount + (delaySeconds * 1000);
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

  { Concatenate any remaining parameters }
  Inc(pathIdx);
  num := ParamCount;
  for i := pathIdx to num do
  begin
    if (i > pathIdx) then params := params + ' ';
    params := params + ParamStr (i);
  end;

  { Add trailing NUL bytes }
  fileName := fileName + #0;
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
    repeat
      Application.ProcessMessages;
    until GetModuleUsage (h) = 0;
    { And shut down Windows }
    { But sometimes Windows does not successfully exit first try... }
    { This repeats the request for ~10 seconds before giving up }
    ticks := GetTickCount + 10000;
    repeat
      Application.ProcessMessages;
      ExitWindows (0, 0);
    until GetTickCount > ticks;
    MessageBox(0, 'Unable to Exit Windows', 'RunExit Error', MB_OK);
  end;
end.
