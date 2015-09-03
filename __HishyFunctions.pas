unit HishyFunctions;
uses mteFunctions;

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
function GetStrBeginsWith(s, delimiter: string): string;
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

function Inden(i: Integer): String;
begin
  Result := StringOfChar('  ',i);
end;

procedure CreateDirectories(sFile: string);
var
  sPath: string;
  i: integer;
begin
  for i := Length(sFile) downto 0 do 
    if (Copy(sFile,i,1) = '\') then begin
      sPath := Copy(sFile, 1, i);
      break;
    end;
  try
    ForceDirectories(sPath)
  except
    //Nothing
  end;
end;

end.