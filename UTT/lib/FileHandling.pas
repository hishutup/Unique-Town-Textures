unit UTTFileHandling;

procedure CreateFileIfMissing(sFilePath: string);
begin
  try
    if not FileExists(sFilePath) then
    begin
      CreateDirectories(sFilePath);
      FileClose(FileCreate(sFilePath));
    end;
  except
    on x: exception do
      raise Excption.Create(X.Message);
  end;
end;

function FileFromPath(sFilePath: string): string;
var
  i: int;
begin
  for i := Length(sFilePath) downto 0 do
  begin
    if Copy(sFilePath, i , 1) = '\' then
    begin
      Result := Copy(sFilePath, i+1, Length(sFilePath));
      break;
    end;
  end;
end;

procedure UpdateSettingsBool(var ini: TMemIniFile; sSec, sValue: String);
var
  slNew, slOld: TStringList;
  i: Int;
  sTemp: String;
begin
  slNew :=TStringList.Create;
  slOld := TStringList.Create;
  slNew.CommaText := sValue;
  ini.ReadSectionValues(sSec, slOld); 
  ini.EraseSection(sSec);
  for i := 0 to Pred(slNew.Count) do begin
    if Lowercase(slOld.Values[slNew[i]]) = 'true' then 
      sTemp := 'True'
    else
      sTemp := false;
    ini.WriteString(sSec, slNew[i], sTemp);
  end;
  slNew.Free;
  slOld.Free;
  ini.UpdateFile;
end;

procedure FindFiles(sPath: string; maxDepth: Int; var sl: TStringList);
var
  searchResult: TSearchRec;
  asPath: string;
begin
  if maxDepth <= 0 then exit;
  if Copy(sPath,Length(sPath),1) <> '\' then
    sPath := sPath+'\';
  asPath := sPath+'*';
  if FindFirst(asPath, faAnyFile, searchResult) = 0 then
  begin
    repeat
      if not ((searchResult.Name = '.') OR (searchResult.Name = '..')) then
        if (searchResult.attr and faDirectory) = faDirectory then 
          FindFiles(sPath+searchResult.Name, maxDepth-1, sl)
        else
          sl.Append(sPath+searchResult.Name);
    until FindNext(searchResult) <> 0;
  end;
  FindClose(searchResult);
end;

function DirContainsFiles(sPath: string; iDepth: int): Boolean;
var
  i: int;
  searchResult: TSearchRec;
  asPath: string;
begin
  Result := False;
  if iDepth <= 0 then exit;
  if Copy(sPath,Length(sPath),1) <> '\' then
    sPath := sPath+'\';
  asPath := sPath+'*';
  if FindFirst(asPath, faAnyFile, searchResult) = 0 then
  begin
    repeat
      if not ((searchResult.Name = '.') OR (searchResult.Name = '..')) then
        if (searchResult.attr and faDirectory) = faDirectory then
        begin
          if DirContainsFiles(sPath+searchResult.Name, iDepth-1) then
          begin
            Result := True;
            FindClose(searchResult);
            exit;
          end;
        end
        else
        begin
          Result := True;
          FindClose(searchResult);
          exit;
        end;
    until FindNext(searchResult) <> 0;
  end;
  FindClose(searchResult);
end;

function GetLastFolder(sPath: string): string;
var
  i, iLast, iFirst: int;
begin
  if not (Copy(sPath,Length(sPath),1) = '\') then sPath := sPath+'\';
  for i := 1 to Length(sPath) do begin
    if Copy(sPath,i,1) <> '\' then continue;
    iFirst := iLast;
    iLast := i;
  end;
  if (iFirst >= iLast) OR
  (iFirst = 0) then
    Result := ''
  else
    Result := Copy(sPath,iFirst,iLast-iFirst);
end;
  
end.