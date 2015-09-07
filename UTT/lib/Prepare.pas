unit UTTPrepare;
  
{
Generates FormID cache dumps.

Looks at every plugin starting from 00 -> FF and checks to see if the current FormID cache is vaild.
If the FormID cache is invalid or nonexistant, FormIDs are regenerated for that plugin and then cached.

Adding FormIDs to StringLists is very expensive for some reason.
Most of the core logic that the elements are compared to are light in comparison, unless there is something else at play


Checksum Logic - FormIDs are LO sensitive making this necessary.
cache\<plugin name>.txt  -----(CRC32)-----> FormIDsCacheChecksums.txt -----(CRC32)-----> General

Data\<loaded files> -----(CRC32)-----> FileChecksums.txt -----(CRC32)-----> General
}
  
var
  bDoDebugPrepare, bForced: Boolean; 
  arrFilesToProcess: Array[0..255] OF String;

procedure DebugMessage(s: string);
begin
  if bDoDebugPrepare then AddMessage(s);
end;

procedure Debug_ReadArray;
var
  i: int;
  sl: TStringList;
begin
  if not bDoDebugPrepare then exit;
  sl := TStringList.Create;
  
  for i := 0 to Pred(Min(Length(arrFilesToProcess), FileCount)) do
  begin
    sl.Append(arrFilesToProcess[i]);
  end;
  AddMessage(sl.CommaText);
  sl.Free;
end;
  
procedure StartupPrepare;
var
  i: int;
begin
  bDoDebugPrepare := StrToBool(iniSettings.ReadString('Debug', 'doDebugPrepare', 'False'));
  bForced := StrToBool(iniSettings.ReadString('Forced', 'ForceFormIDsCache', 'False'));
  
  for i := 0 to Pred(Length(arrFilesToProcess)) do
    arrFilesToProcess[i] := 'True';
  Debug_ReadArray;
end;

procedure ClearBools;
var
  i: int;
begin
  for i := 0 to Pred(Length(arrFilesToProcess)) do
    arrFilesToProcess[i] := 'False';
end;

procedure FindMismatchedCaches;
var
  slNewChecksum, slOldChecksum: TStringList;
  i, iIndex: int;
  sFileName, sNewChecksum, sFileChecksum: string;
begin
  
  slOldChecksum := TStringList.Create;
  slNewChecksum := TStringList.Create;
  slOldChecksum.LoadFromFile(cPluginChecksumsFile);
  for i := 0 to Pred(FileCount) do 
  begin
    sFileName := GetFileName(FileByIndex(i));
    sNewChecksum := IntToStr(wbCRC32File(DataPath+sFileName));
    iIndex := slOldChecksum.IndexOfName(sFileName);
    if iIndex = -1 then
    begin
      arrFilesToProcess[i] := 'False';
    end
    else if slOldChecksum.ValueFromIndex[iIndex] <> sNewChecksum then
    begin
      arrFilesToProcess[i] := 'False';
    end;
    slNewChecksum.Add(sFileName+'='+sNewChecksum);
  end;  
  Debug_ReadArray;
    
  if bForced then
    ClearBools;
    
  if iniSettings.ReadString('Checksums', FileFromPath(cPluginChecksumsFile), '') <> IntToStr(wbCRC32File(cPluginChecksumsFile)) then
  begin
    AddMessage(FileFromPath(cPluginChecksumsFile) + Lang.Values['sFileIsComprimised']);
    ClearBools;
  end;
    
  //Save 
  slNewChecksum.SaveToFile(cPluginChecksumsFile);
  iniSettings.WriteString('Checksums', FileFromPath(cPluginChecksumsFile), IntToStr(wbCRC32File(cPluginChecksumsFile)));
  iniSettings.UpdateFile;
  
  DebugMessage(slOldChecksum.Text);
  DebugMessage(slNewChecksum.Text);
  slOldChecksum.Free;
  slNewChecksum.Free;
end;

procedure CheckFormIDFile;
var
  i: int;
  sFileName, sFilePath: string;
  slFormIDCacheChecksums: TStringList;
begin
  if iniSettings.ReadString('Checksums', FileFromPath(cFormIDsChecksumsFile), '') <> IntToStr(wbCRC32File(cFormIDsChecksumsFile)) then 
  begin
    AddMessage('Checksum from general ini did not match.');
    ClearBools;
    exit;
  end;
    
  slFormIDCacheChecksums := TStringList.Create;
  slFormIDCacheChecksums.LoadFromFile(cFormIDsChecksumsFile);
  
  for i := 0 to Pred(FileCount) do
  begin
    sFileName := GetFileName(FileByIndex(i));
    sFilePath := cCacheFormIDsPath+sFileName+'.txt';
    if not FileExists(sFilePath) then
    begin
      DebugMessage(sFilePath+' does not exist.');
      arrFilesToProcess[i] := 'False';
      Continue;
    end;
    
    //CRC of cache file
    if IntToStr(wbCRC32File(sFilePath)) <> slFormIDCacheChecksums.Values[sFileName] then
    begin
      DebugMessage('Recorded checksum is different from the actual checksum');
      arrFilesToProcess[i] := 'False';
      continue;
    end;
  end;
  
  slFormIDCacheChecksums.Free;
end;

procedure GetProcessingIndex;
begin
  FindMismatchedCaches;
  DebugMessage('Plugin checksums report: ');
  Debug_ReadArray;//Check plugins for edits
  
  CheckFormIDFile;
  DebugMessage('FormID file checksums report');
  Debug_ReadArray;//Check FormID Cache dumps for edits
end;

procedure ProcessFormID;
var
  iFileIndex, iMaxRecords, iRecordIndex: int;
  f, e: IInterface;
  sFileName, sSig, sEdid: string;
  slFormIDs: TStringList;
begin
  slFormIDs := TStringList.Create;
  
  for iFileIndex := 0 to Pred(FileCount) do
  begin
    if StrToBool(arrFilesToProcess[iFileIndex]) then continue;
    f := FileByIndex(iFileIndex);
    sFileName := GetFileName(f);
    iMaxRecords := Pred(RecordCount(f));
    AddMessage(Inden(2)+sFileName);
    
    for iRecordIndex := 0 to iMaxRecords do
    begin
      e := RecordByIndex(f, iRecordIndex);
      if (iRecordIndex mod 10000) = 0 then 
        AddMessage(Inden(4)+IntToStr(iRecordIndex)+' out of '+ IntToStr(iMaxRecords)+' are done.');
        
      if not IsMaster(e) then continue;
      sSig := Signature(e);
      if sSig = 'REFR' then
      begin
        if GetIsPersistent(e) then
        begin
          if Assigned(GetElementEditValues(e,'XTEL\Door')) then
          begin
            slFormIDs.Add(IntToHex(FileFormID(e),6)+'='+'DOOR');
            continue;
          end;
        end
        else
        begin
          slFormIDs.Append(IntToHex(FileFormID(e),6)+'='+'REFR');
          continue;
        end;
      end;
      if sSig = 'CELL' then
      begin
        sEdid := EditorID(e);
        if not Assigned(sEdid) then Continue;
        slFormIDs.Append(IntToHex(FileFormID(e),6)+'='+sEdid);
        continue;
      end;
    end;
    //Done looping through all the records
    CreateFileIfMissing(cCacheFormIDsPath+sFileName+'.txt');
    slFormIDs.SaveToFile(cCacheFormIDsPath+sFileName+'.txt');
    slFormIDs.Clear;
  end;
  slFormIDs.Free;
end;

procedure CalculateFormIDChecksums;
var
  slFormIDFiles, slOldFormIDFileChecksums, slNewFormIDFileChecksums: TStringList;
  sChecksum, sFileName: string;
  i: int;
begin
  slFormIDFiles := TStringList.Create;
  FindFiles(cCacheFormIDsPath, 1, slFormIDFiles);
  slNewFormIDFileChecksums := TStringList.Create;
  slOldFormIDFileChecksums := TStringList.Create;
  slOldFormIDFileChecksums.LoadFromFile(cFormIDsChecksumsFile);
  for i := 0 to Pred(slFormIDFiles.Count) do
  begin
    sChecksum := wbCRC32File(slFormIDFiles[i]);
    sFileName := FileFromPath(slFormIDFiles[i]);
    slNewFormIDFileChecksums.Append(RemoveFromEnd(sFileName,'.txt')+'='+sChecksum);
  end;
  slNewFormIDFileChecksums.SaveToFile(cFormIDsChecksumsFile);
  slFormIDFiles.Free;
  slOldFormIDFileChecksums.Free;
  slNewFormIDFileChecksums.Free;
end;

procedure ProcessFiles;
begin
  //Generate FormID lists, save
  ProcessFormID;
  CalculateFormIDChecksums;
  
  //Create Checksum for checksum file.
  iniSettings.WriteString('Checksums', FileFromPath(cFormIDsChecksumsFile), IntToStr(wbCRC32File(cFormIDsChecksumsFile)));
  iniSettings.UpdateFile;
end;
  
procedure GatherRecords;
begin
  StartupPrepare;
  GetProcessingIndex;
  Debug_ReadArray;
  ProcessFiles;
end;

end.