unit UTTFunctions;

function CheckForFile(sPath, sFile: String): Boolean;
begin
  if not FileExists(sPath+sFile) then begin
    sScriptFailedReason := 'You are missing '+sPath+sFile+'. Please reinstall the "Edit Scripts" folder, terminating script.';
  end;
  Result := sScriptFailedReason = '';
end;

procedure SaveIniValues(sPath, sFile, sSec, sParam, sValue: string);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  ini.WriteString(sSec, sParam, sValue);
  ini.UpdateFile;
  ini.Free;
end;
function LoadIniValues(sPath, sFile, sSec, sParam, sDefault: string): string;
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  Result := ini.ReadString(sSec, sParam, sDefault);
  ini.Free;
end;

end.