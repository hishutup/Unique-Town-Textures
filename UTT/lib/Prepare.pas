unit UTTPrepare;

const
  cDebugParam='doDebugPrepare';
  
var
  iniFormIDs: TMemIniFile; 
  bDoDebug: Boolean; 

procedure StartupPrepare;
begin
  bDoDebug := StrToBool(iniSettings.ReadString('Debug', cDebugParam, 'False'));
  iniFormIDs := TMemIniFile.Create(cCacheFormIDsFile);
end;

function CheckCheckMatches: Boolean;
var
  slOldChecksum, slNewChecksum: TStringList;
  sFileName, sNewChecksum: string;
  i, iIndex: int;
begin
  Result := True;
  slOldChecksum := TStringList.Create;
  slNewChecksum := TStringList.Create;
  slOldChecksum.LoadFromFile(cCacheCheckSumFile);
  
  for i := 0 to Pred(FileCount) do 
  begin
    sFileName := GetFileName(FileByIndex(i));
    sNewChecksum := IntToStr(wbCRC32File(DataPath+sFileName));
    iIndex := slOldChecksum.IndexOfName(sFileName);
    if iIndex <> i then
    begin
      Result := False;//If LO changes
    end
    else if slOldChecksum.ValueFromIndex[iIndex] <> sNewChecksum then
    begin
      Result := False;//If Checksum is different
    end;
   
    slNewChecksum.Add(sFileName+'='+sNewChecksum);
  end;
  
  //Save 
  slNewChecksum.SaveToFile(cCacheCheckSumFile);
  AddMessage(slOldChecksum.Text);
  AddMessage(slNewChecksum.Text);
  
  slOldChecksum.Free;
  slNewChecksum.Free;
end;

procedure FreeMemoryPrepare;
begin
  iniFormIDs.Free;
end;
  
procedure GatherRecords;
begin
  StartupPrepare;
  if not CheckCheckMatches then
  begin
    AddMessage('DoWork');
  end;
  FreeMemoryPrepare;
end;

end.