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

begin
  { Set defaults }
  nCmdShow := SW_SHOWNORMAL;

  { Look for slash-options before the path param and handle them }
  pathIdx := 1;
  while ((pathIdx < paramCount) and (ParamStr(pathIdx)[1] = '/')) do
  begin
    { Split slash opts at equal sign }
    i := Pos ('=', ParamStr(pathIdx));
    if (i = 0) then i := Length(ParamStr(pathIdx)) + 1;
    reParam := UpperCase(Copy(ParamStr(pathIdx), 2, i - 2));
    reValue := Copy(ParamStr(pathIdx), i + 1, Length(ParamStr(pathIdx)) - i);

    { Test each option type and extract its value - only one for now }
    if (reParam = 'SHOW') then
    begin
      num := StrToIntDef(reValue, -1);
      if ((num >= 0) and (num <= 11)) then nCmdShow := num;
    end;

    Inc(pathIdx);
  end;

  { Split first parameter into path and filename }
  i := Pos ('\', ParamStr (PathIdx));
  if (i > 0) then
  begin
    { Make it a path, find last occurrence of directory separator }
    pathName := ParamStr (PathIdx);
    i := (StrRScan (@pathName [1], '\') - @pathName [1]) + 1;
    fileName := Copy (pathName, i + 1, Length (pathName) - i);
    { Remove the trailing directory separator from path }
    { Unless we're at the root ie. C:\ }
    if pathName [i - 1] <> ':' then begin i := i - 1 end;
    pathName := Copy (pathName, 1, i);
  end else begin
    fileName := ParamStr (PathIdx);
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
    h := GetTickCount;
    repeat
      Application.ProcessMessages;
      ExitWindows (0, 0);
    until GetTickCount > h + 10000;
    MessageBox(0, 'Unable to Exit Windows', 'RunExit Error', MB_OK);
    { Try one final time... }
    ExitWindows (0, 0);
  end;
end.
