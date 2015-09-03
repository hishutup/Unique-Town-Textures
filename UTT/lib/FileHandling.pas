unit UTTFileHandling;

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

end.