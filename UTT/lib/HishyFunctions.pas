unit HishyFunctions;
uses mteFunctions;

{
*StrToBool(InputString: string)
  +Returns Boolean
*StrBeginsWith(InputString, Delimiter: string)
  +Returns String  

*CheckINI(FileLocation, FileName: string)
  +Returns Boolean
*LoadINI(FileLocation, FileName, Category, Parameter, DefaultValue: string)
  +Returns String
*SaveINI(FileLocation, FileName, Category, Parameter, Value: string)
*LoadINICat(FileLocation, FileName, Category, DefaultValue: string)
  +Returns String (delimited text)
*SaveINICat(FileLocation, FileName, Category: string; slDelimitedText: TStringList)
*GetValueFromSL(slDelimitedText: TStringList; NameOfValue: string)
  +Returns string
*SaveValueToSL(slDelimitedText: TStringList; NameOfValue, Value: string);
}
//LinksTo(ElementByPath(e, 'XTEL\Door'));

//
//Generic Functions
//=============================================================================================================
{
  Converts a case-insensive string to a bool.
  true = 'TrUe'
  true = '1'
  If incorrect Input string then false is returned
}
function StrToBool(s: string): Boolean;
begin
  result := (LowerCase(s) = 'true') OR (s = '1'); 
end;
{
  Returns the string that was before the delimiter.
}
function StrBeginsWith(s, delimiter: string): string;
var
	sTempString: string;
	iCharCount: int;
begin
	iCharCount := Pred(Pos(delimiter, s));
	if iCharCount <> 0 then begin
		sTempString := Copy(s,0,iCharCount);
	end;
	Result := sTempString;
end;

{
  Returns the X,Y of an object if it exists in a worldspace otherwise return ''
}
function GetCoordinates(e: IInterface): string;
var
  sName, sGrid: string;
  iWrldPos: Integer;
begin
  sName := Name(e);
  iWrldPos := Pos('[WRLD:', sName);
  if iWrldPos <> 0 then sGrid := Copy(sName, iWrldPos+Length('[WRLD:00000000] at ')+1, Length(sName)-(iWrldPos+Length('[WRLD:00000000] at ')+1));
  Result := sGrid;
end;

//Return True if the BASE Name is a Static Object
function IsStatic(e: IInterface): Boolean;
begin
  Result := (Pos('STAT:',Name(e)) <> 0);

end;

function GetStrEndsWith(s, delimiter: String):String;
begin
Result := Copy(s, rPos(Delimiter, s) + 1, Length(s))
end;


//
//INI Handling
//=============================================================================================================
{
  Checks to see if a File exists
}
function CheckINI(sPath, sFile: string): Boolean;
var
  sFullPath: string;
begin
  sFullPath := FileSearch(sFile, ScriptsPath + sPath);
  Result := sFullPath <> '';
end;

{
  Loads an ini file and returns the value at a given section and param
}
function LoadIniValues(sPath, sFile, sSec, sParam, sDefault: string): string;
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  Result := ini.ReadString(sSec, sParam, sDefault);
  ini.Free;
end;

{
  Saves an ini file and writes the value at a given section and param
}
procedure SaveIniValues(sPath, sFile, sSec, sParam, sValue: string);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  ini.WriteString(sSec, sParam, sValue);
  ini.UpdateFile;
  ini.Free;
end;

{
  Loads all Parameter Names from a section in an ini and loads it into a StringList.
}
procedure LoadIniParamNames(sPath, sFile, sSec: string; sl: TStringList);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  ini.ReadSection(sSec, sl);
  ini.Free;
end;
{
  Loads all Parameter Names and their values from a section in an ini and loads it into a StringList.
}
procedure LoadIniParams(sPath, sFile, sSec: string; sl: TStringList);
var
  ini: TMemIniFile;
  i: Int;
  slTemp: TStringList;
begin
  slTemp := TStringList.Create;
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  ini.ReadSection(sSec, slTemp);
  for i := 0 to Pred(slTemp.Count) do
    sl.Add(slTemp[i]+'='+ini.ReadString(sSec, slTemp[i], 'False'));
  ini.Free;
  slTemp.Free;
end;

{
  Deletes all the parameters that are in a Section.
}
procedure EraseIniParams(sPath, sFile, sSection: String);
var
  ini: TMemIniFile;
  sl: TStringList;
  i: Integer;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  sl := TStringList.Create;
  ini.ReadSection(sSec, sl);
  for i := 0 to Pred(sl.Count) do
    ini.DeleteKey(sSec, sl[i]);

  sl.Free;
  ini.UpdateFile;
  ini.Free;
end;

{
  Deletes all the parameters that are in every Section.
}
procedure EraseIniSections(sPath, sFile: String);
var
  ini: TMemIniFile;
  sl: TStringList;
  i: Integer;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  sl := TStringList.Create;
  ini.ReadSections(sl);
  for i := 0 to Pred(sl.Count) do
    ini.EraseSection(sl[i]);

  sl.Free;
  ini.UpdateFile;
  ini.Free;
end;

{
  Loads all Section Names from an ini and loads it into a StringList.
}
procedure LoadIniSections(sPath, sFile: string; sl: TStringList);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ScriptsPath + sPath + sFile);
  ini.ReadSections(sl);
  ini.Free;
end;

{
  Gets the value string from a stringlist name that is a Name Value Pair
}
function GetValueFromSL(sl: TStringList; sName: string): string;
begin
  Result := sl.ValueFromIndex[sl.IndexOfName(sName)];
end;

{
  Save the value string from a stringlist name that is a Name Value Pair
}
procedure SaveValueToSL(sl: TStringList; sName, sValue: string);
begin
  sl.ValueFromIndex[sl.IndexOfName(sName)] := sValue;
end;

{
  Read a list of Name\Value stringlists with index
  
}
procedure ReadSLWithIndex(sl: TStringList; idx: Int);
var
  sSpace:string;
  i: int;
begin
  for i := 0 to idx do sSpace := sSpace + ' ';
  for i := 0 to Pred(sl.Count) do AddMessage(sSpace+sl.Names[i]+'='+sl.Values[i]);
end;


end.