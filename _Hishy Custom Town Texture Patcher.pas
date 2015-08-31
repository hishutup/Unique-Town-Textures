{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

uses mteFunctions;

const
	//Debug Infos
	doDebug=false;
	doDebugStrings=false;
	doDebugRecords=false;
	doDebugStatics=false;
	doDebugReplacement=false;
	
	//Files
	cMasterFile='Better Towns Textures.esp';
	cIniFile='_Hishy Custom Town Texture Patcher.ini';
	
	//Keywords
	cDawnstarKeyword='Dawn';
	cFalkreathKeyword='Falk';
	cMorthalKeyword='Mort';
	cWinterholdKeyword='Winter';
	

var
	slDawnstarExteriorCells, slDawnstarInteriorCells, slFalkreathExteriorCells, slFalkreathInteriorCells, slMorthalExteriorCells, slMorthalInteriorCells, slWinterholdExteriorCells, slWinterholdInteriorCells, slIgnoreCells, slDawnstarStatics, slFalkreathStatics, slMorthalStatics, slWinterholdStatics, slDawnstarStaticName, slFalkreathStaticName, slMorthalStaticName, slWinterholdStaticName: TStringList;
	
	sDawnstarLocation, sFalkreathLocation, sMorthalLocation, sWinterholdLocation: string;
	
	iPatchFile: IInterface;
	
	bKillScript, bRegenInteriorCells, bRegenCompatibleStatics, bDoInteriors, doLocationRefs: Boolean;

//
//Debugging Stuff
//
procedure DebugMessage(s: string);
begin
	if doDebug then AddMessage(s);
end;

procedure DebugStrings(s: string);
begin
	if doDebug and doDebugStrings then AddMessage(s);
end;

procedure DebugRecords(s: string);
begin
	if doDebug and doDebugRecords then AddMessage(s);
end;

procedure DebugStatics(s: string);
begin
	if doDebug and doDebugStatics then AddMessage(s);
end;

procedure DebugReplacement(s: string);
begin
	if doDebug and doDebugReplacement then AddMessage(s);
end;
	
//Function to extract the first word in a string or geev.
procedure AddStrIfNotAssigned(s: string; sl: TStringList);
begin
	if sl.IndexOf(s) = -1 then begin
		sl.Add(s);
		DebugStrings('      '+s+' is added to Interior StringLists.');
	end;
end;

//Function to extract the first word in a string or geev.
function ExtractFirstWord(s, delimiter: string): string;
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
	
//
//Initialize Settings
//
procedure CreatePatchFile;
begin
	DebugMessage('Asking to create a file');
	iPatchFile := Fileselect('Please create a new patch file');
	AddMasterIfMissing(iPatchFile,cMasterFile);
end;

procedure CreateStrings;
begin
	DebugStrings('Creating Strings');
	slDawnstarExteriorCells := TStringList.Create;
	slDawnstarInteriorCells := TStringList.Create;
	slFalkreathExteriorCells := TStringList.Create;
	slFalkreathInteriorCells := TStringList.Create;
	slMorthalExteriorCells := TStringList.Create;
	slMorthalInteriorCells := TStringList.Create;
	slWinterholdExteriorCells := TStringList.Create;
	slWinterholdInteriorCells := TStringList.Create;
	slIgnoreCells := TStringList.Create;
	slDawnstarStatics := TStringList.Create;
	slFalkreathStatics := TStringList.Create;
	slMorthalStatics := TStringList.Create;
	slWinterholdStatics := TStringList.Create;
	slDawnstarStaticName := TStringList.Create;
	slFalkreathStaticName := TStringList.Create;
	slMorthalStaticName := TStringList.Create;
	slWinterholdStaticName := TStringList.Create;
	
end;


//Fill StringLists
procedure FillStringLists;
var
	f,g,e: IInterface;
	iFileIndex, iRecordIndex: Integer;
	ini: TMemIniFile;
	EDID, Path: string;
begin
	//Fill Cell StringLists
	//Exterior Cells
	
	Path := FileSearch(cIniFile, ScriptsPath);
	if (Path = '') then begin
		bKillScript := true;
		exit;
	end;
	ini := TMemIniFile.Create(ScriptsPath + cIniFile);
	AddMessage('Loading StringLists from ' + cIniFile);
	//ExteriorLists
	slDawnstarExteriorCells.CommaText := ini.ReadString('Exterior Cells', 'DawnstarCells', '');
	slFalkreathExteriorCells.CommaText := ini.ReadString('Exterior Cells', 'FalkreathCells', '');
	slMorthalExteriorCells.CommaText := ini.ReadString('Exterior Cells', 'MorthalCells', '');
	slWinterholdExteriorCells.CommaText := ini.ReadString('Exterior Cells', 'WinterholdCells', '');
	//InteriorLists
	if not bRegenInteriorCells then begin
		AddMessage('Loading Interior Cells from '+cIniFile);
		slDawnstarInteriorCells.CommaText := ini.ReadString('Saved Interior Cells', 'DawnstarInteriorCells', '');
		slFalkreathInteriorCells.CommaText := ini.ReadString('Saved Interior Cells', 'FalkreathInteriorCells', '');
		slMorthalInteriorCells.CommaText := ini.ReadString('Saved Interior Cells', 'MorthalInteriorCells', '');
		slWinterholdInteriorCells.CommaText := ini.ReadString('Saved Interior Cells', 'WinterholdInteriorCells', '');
	end;
	//Ignore list
	slIgnoreCells.CommaText := ini.ReadString('Ignored', 'IngoreCells', '');
	
	if ((slDawnstarInteriorCells.Text <> '') AND (slFalkreathInteriorCells.Text <> '')) AND ((slMorthalInteriorCells.Text <> '') AND (slWinterholdInteriorCells.Text <> '')) then exit;
	AddMessage('Generating Interior Cells Lists');
	//Interior Cells
	for iFileIndex := 0 to GetLoadOrder(iPatchFile) do begin
		f := FileByIndex(iFileIndex);
		if not HasGroup(f, 'CELL') then continue;
		DebugRecords('  Current File is '+GetFileName(f));
		for iRecordIndex := 0 to Pred(RecordCount(f)) do begin
			e := RecordByIndex(f,iRecordIndex);
			if Signature(e) <> 'CELL' then continue;
			//DebugRecords('    '+Name(e));
			EDID := geev(e,'EDID');
			if slIgnoreCells.IndexOf(EDID) <> -1 then continue
			else if Pos('Dawnstar', EDID) <> 0 then begin
				//AddMessage(EDID+' is part of Dawnstar');
				if slDawnstarExteriorCells.IndexOf(EDID) = -1 then AddStrIfNotAssigned(EDID,slDawnstarInteriorCells)
				else DebugStrings('      '+EDID+' is already assigned or is an exterior cell.');
			end
			else if Pos('Falkreath', EDID) <> 0 then begin
				//AddMessage(EDID+' is part of Falkreath');
				if slFalkreathExteriorCells.IndexOf(EDID) = -1 then AddStrIfNotAssigned(EDID,slFalkreathInteriorCells)
				else DebugStrings('      '+EDID+' is already assigned or is an exterior cell.');
			end
			else if Pos('Morthal', EDID) <> 0 then begin
				//AddMessage(EDID+' is part of Morthal');
				if slMorthalExteriorCells.IndexOf(EDID) = -1 then AddStrIfNotAssigned(EDID,slMorthalInteriorCells)
				else DebugStrings('      '+EDID+' is already assigned or is an exterior cell.');
			end
			else if Pos('Winterhold', EDID) <> 0 then begin
				//AddMessage(EDID+' is part of Winterhold');
				if slWinterholdExteriorCells.IndexOf(EDID) = -1 then AddStrIfNotAssigned(EDID,slWinterholdInteriorCells)
				else DebugStrings('      '+EDID+' is already assigned or is an exterior cell.');
			end;
		end;
	end;
	AddMessage('Saving Recorded Interior Cells');
	ini.WriteString('Saved Interior Cells', 'DawnstarInteriorCells', slDawnstarInteriorCells.CommaText);
	ini.WriteString('Saved Interior Cells', 'FalkreathInteriorCells', slFalkreathInteriorCells.CommaText);
	ini.WriteString('Saved Interior Cells', 'MorthalInteriorCells', slMorthalInteriorCells.CommaText);
	ini.WriteString('Saved Interior Cells', 'WinterholdInteriorCells', slWinterholdInteriorCells.CommaText);
	ini.UpdateFile;
end;

//Find Location Data
procedure FindLocations;
var
	f,g,e:IInterface;
	i: Integer;
	EDID: string;
begin
	f := FileByName('Skyrim.esm');
	g := GroupBySignature(f, 'LCTN');
	for i := 0 to Pred(ElementCount(g)) do begin
		e := ElementByIndex(g,i);
		EDID := geev(e, 'EDID');
		if EDID = 'DawnstarLocation' then sDawnstarLocation := geev(e, 'Record Header\FormID');
		if EDID = 'FalkreathLocation' then sFalkreathLocation := geev(e, 'Record Header\FormID');
		if EDID = 'MorthalLocation' then sMorthalLocation := geev(e, 'Record Header\FormID');
		if EDID = 'WinterholdLocation' then sWinterholdLocation := geev(e, 'Record Header\FormID');
	end;
end;


//
//Debugging Lists.
//
procedure ReadExteriorLists;
var
	i: Int;
begin
	AddMessage('Reading Dawnstar Exterior Lists');
	for i := 0 to Pred(slDawnstarExteriorCells.Count) do begin
		AddMessage('    '+slDawnstarExteriorCells[i]);
	end;
	AddMessage('Reading Falkreath Interior Lists');
	for i := 0 to Pred(slFalkreathExteriorCells.Count) do begin
		AddMessage('    '+slFalkreathExteriorCells[i]);
	end;
	AddMessage('Reading Morthal Interior Lists');
	for i := 0 to Pred(slMorthalExteriorCells.Count) do begin
		AddMessage('    '+slMorthalExteriorCells[i]);
	end;
	AddMessage('Reading Winterhold Interior Lists');
	for i := 0 to Pred(slWinterholdExteriorCells.Count) do begin
		AddMessage('    '+slWinterholdExteriorCells[i]);
	end;
end;

procedure ReadInteriorLists;
var
	i: int;
begin
	AddMessage('Reading Ignored Cells');
	for i := 0 to Pred(slIgnoreCells.Count) do begin
		AddMessage('    '+slIgnoreCells[i]);
	end;
	AddMessage('Reading Dawnstar Interior Lists');
	for i := 0 to Pred(slDawnstarInteriorCells.Count) do begin
		AddMessage('    '+slDawnstarInteriorCells[i]);
	end;
	AddMessage('Reading Falkreath Interior Lists');
	for i := 0 to Pred(slFalkreathInteriorCells.Count) do begin
		AddMessage('    '+slFalkreathInteriorCells[i]);
	end;
	AddMessage('Reading Morthal Interior Lists');
	for i := 0 to Pred(slMorthalInteriorCells.Count) do begin
		AddMessage('    '+slMorthalInteriorCells[i]);
	end;
	AddMessage('Reading Winterhold Interior Lists');
	for i := 0 to Pred(slWinterholdInteriorCells.Count) do begin
		AddMessage('    '+slWinterholdInteriorCells[i]);
	end;
end;

procedure ReadStaticsLists;
var
	i: Integer;
begin
	
	AddMessage('  Reading Dawstar''s statics lists');
	for i := 0 to Pred(slDawnstarStatics.Count) do begin
		AddMessage('    '+slDawnstarStatics[i]+' that is linked to '+slDawnstarStaticName[i]);
	end;
	AddMessage('  Reading Falkreath''s statics lists');
	for i := 0 to Pred(slFalkreathStatics.Count) do begin
		AddMessage('    '+slFalkreathStatics[i]+' that is linked to '+slFalkreathStaticName[i]);
	end;
	AddMessage('  Reading Morthal''s statics lists');
	for i := 0 to Pred(slMorthalStatics.Count) do begin
		AddMessage('    '+slMorthalStatics[i]+' that is linked to '+slMorthalStaticName[i]);
	end;
	AddMessage('  Reading Winterhold''s statics lists');
	for i := 0 to Pred(slWinterholdStatics.Count) do begin
		AddMessage('    '+slWinterholdStatics[i]+' that is linked to '+slWinterholdStaticName[i]);
	end;
end;

procedure ScanCompatibleStatics;
var
	g,e: IInterface;
	i: Integer;
	ini: TMemIniFile;
	EDID, Name, Path: string;
begin
	Path := FileSearch(cIniFile, ScriptsPath);
	if (Path = '') then begin
		bKillScript := true;
		exit;
	end;
	
	
	ini := TMemIniFile.Create(ScriptsPath + cIniFile);
	AddMessage('Loading StringLists from ' + cIniFile);
	//Load Statics
	if not bRegenCompatibleStatics then begin
		slDawnstarStatics.CommaText := ini.ReadString('Saved Available Statics', 'DawnstarStatics', '');
		slFalkreathStatics.CommaText := ini.ReadString('Saved Available Statics', 'FalkreathStatics', '');
		slMorthalStatics.CommaText := ini.ReadString('Saved Available Statics', 'MorthalStatics', '');
		slWinterholdStatics.CommaText := ini.ReadString('Saved Available Statics', 'WinterholdStatics', '');
		slDawnstarStaticName.CommaText := ini.ReadString('Saved Available Statics', 'DawnstarStaticName', '');
		slFalkreathStaticName.CommaText := ini.ReadString('Saved Available Statics', 'FalkreathStaticName', '');
		slMorthalStaticName.CommaText := ini.ReadString('Saved Available Statics', 'MorthalStaticName', '');
		slWinterholdStaticName.CommaText := ini.ReadString('Saved Available Statics', 'WinterholdStaticName', '');
	end;
	
	if slDawnstarStatics.Count <> slDawnstarStaticName.Count then begin
		AddMessage('  Dawnstar Statics list''s length do not match, regenerating...');
		slDawnstarStatics.Clear;
		slDawnstarStaticName.Clear;
	end;
	if slFalkreathStatics.Count <> slFalkreathStaticName.Count then begin
		AddMessage('  Falkreath Statics list''s length do not match, regenerating...');
		slFalkreathStatics.Clear;
		slFalkreathStaticName.Clear;
	end;
	if slMorthalStatics.Count <> slMorthalStaticName.Count then begin
		AddMessage('  Winterhold Statics list''s length do not match, regenerating...');
		slMorthalStatics.Clear;
		slMorthalStaticName.Clear;
	end;
	if slWinterholdStatics.Count <> slWinterholdStaticName.Count then begin
		AddMessage('  Winterhold Statics list''s length do not match, regenerating...');
		slWinterholdStatics.Clear;
		slWinterholdStaticName.Clear;
	end;
	
	if ((slDawnstarStatics.Text <> '') AND (slFalkreathStatics.Text <> '')) AND ((slMorthalStatics.Text <> '') AND (slWinterholdStatics.Text <> '')) then exit;
	
	AddMessage('Searching for Statics');
	g := GroupBySignature(FileByName(cMasterFile), 'STAT');
	for i := 0 to Pred(ElementCount(g)) do begin
		e := ElementByIndex(g,i);
		EDID := geev(e, 'EDID');
		Name := geev(e, 'Record Header\FormID');
		if StrEndsWith(EDID,cDawnstarKeyword) then begin
			EDID := Copy(EDID,0,Pred(Pos(cDawnstarKeyword,EDID)));
			DebugStatics(EDID);
			if (slDawnstarStatics.IndexOf(EDID) = -1) then begin
				AddStrIfNotAssigned(EDID,slDawnstarStatics);
				if (slDawnstarStaticName.IndexOf(Name) = -1) then AddStrIfNotAssigned(Name,slDawnstarStaticName);
			end;
		end
		else if StrEndsWith(EDID,cFalkreathKeyword) then begin
			EDID := Copy(EDID,0,Pred(Pos(cFalkreathKeyword,Name)));
			DebugStatics(EDID);
			if slFalkreathStatics.IndexOf(EDID) = -1 then begin 
				AddStrIfNotAssigned(EDID,slFalkreathStatics);
				if slFalkreathStaticName.IndexOf(Name) = -1 then AddStrIfNotAssigned(Name,slFalkreathStaticName);
			end;
		end
		else if StrEndsWith(EDID,cMorthalKeyword) then begin
			EDID := Copy(EDID,0,Pred(Pos(cMorthalKeyword,EDID)));
			DebugStatics(EDID);
			if slMorthalStatics.IndexOf(EDID) = -1 then begin
				AddStrIfNotAssigned(EDID,slMorthalStatics);
				if slMorthalStaticName.IndexOf(Name) = -1 then AddStrIfNotAssigned(Name,slMorthalStaticName);
			end;
		end
		else if StrEndsWith(EDID,cWinterholdKeyword) then begin
			EDID := Copy(EDID,0,Pred(Pos(cWinterholdKeyword,EDID)));
			DebugStatics(EDID);
			if slWinterholdStatics.IndexOf(EDID) = -1 then begin
				AddStrIfNotAssigned(EDID,slWinterholdStatics);
				if slWinterholdStaticName.IndexOf(Name) = -1 then AddStrIfNotAssigned(Name,slWinterholdStaticName);
			end;
		end
		else AddMessage('    '+Name+' is unused for some reason.');
			
		
	end;
	
	AddMessage('Saving Recorded Statics');
	ini.WriteString('Saved Available Statics', 'DawnstarStatics', slDawnstarStatics.CommaText);
	ini.WriteString('Saved Available Statics', 'FalkreathStatics', slFalkreathStatics.CommaText);
	ini.WriteString('Saved Available Statics', 'MorthalStatics', slMorthalStatics.CommaText);
	ini.WriteString('Saved Available Statics', 'WinterholdStatics', slWinterholdStatics.CommaText);
	ini.WriteString('Saved Available Statics', 'DawnstarStaticName', slDawnstarStaticName.CommaText);
	ini.WriteString('Saved Available Statics', 'FalkreathStaticName', slFalkreathStaticName.CommaText);
	ini.WriteString('Saved Available Statics', 'MorthalStaticName', slMorthalStaticName.CommaText);
	ini.WriteString('Saved Available Statics', 'WinterholdStaticName', slWinterholdStaticName.CommaText);
	ini.UpdateFile;
	
	
	if slDawnstarStatics.Count <> slDawnstarStaticName.Count then begin
		AddMessage('  Dawnstar Statics list''s length do not match, exiting...');
		bKillScript := true;
	end;
	if slFalkreathStatics.Count <> slFalkreathStaticName.Count then begin
		AddMessage('  Falkreath Statics list''s length do not match, exiting...');
		bKillScript := true;
	end;
	if slMorthalStatics.Count <> slMorthalStaticName.Count then begin
		AddMessage('  Winterhold Statics list''s length do not match, exiting...');
		bKillScript := true;
	end;
	if slWinterholdStatics.Count <> slWinterholdStaticName.Count then begin
		AddMessage('  Winterhold Statics list''s length do not match, exiting...');
		bKillScript := true;
	end;
	
end;

//
//Do Work
//
procedure ReplaceObjects(f,iCurrentCell: IInterface; slStaticsList,slStaticNameList: TSrtingList; sKeyword, sLocation: string);
var
	g,e,rec: IInterface;
	EDID, sName: string;
	i, iStaticIndex: Integer;
begin
	EDID := ExtractFirstWord(geev(iCurrentCell,'NAME'), ' ');
	iStaticIndex := slStaticsList.IndexOf(EDID);
	if iStaticIndex <> -1 then begin
		sName := slStaticNameList[iStaticIndex];
		AddMessage('      Replacing '+geev(iCurrentCell,'NAME')+' with '+sName+' using the index of '+IntToStr(iStaticIndex));
		try
			AddRequiredElementMasters(iCurrentCell,iPatchFile,false);
			rec := wbCopyElementToFile(iCurrentCell,iPatchFile,false,true);
			seev(rec,'NAME',sName);
			if doLocationRefs then seev(rec, 'XLRL', sLocation);
		except
			on x: exception do begin
				AddMessage('Something went wrong, I dont really know what... but take this:');
				AddMessage(x.Message);
			end;
		end
	end;
end;

procedure FindAndReplaceRecords;
var
	f,e: IInterface;
	i, iCurrentIndex: Cardinal;
	sObjectName, sCurrentCell: string;
begin
	AddMessage('Searching for Cells');
	for iCurrentIndex := GetLoadOrder(iPatchFile) downto 0 do begin
		f := FileByIndex(iCurrentIndex);
		if GetFileName(f) = cMasterFile then continue;
		AddMessage('  Currently on '+GetFileName(f));
		for i := 0 to RecordCount(f) do begin
			if ((i mod 10000) = 0) OR (i = RecordCount(f)) then AddMessage(IntToStr(i)+' out of '+ IntToStr(RecordCount(f))+' from '+GetFileName(f)+' are done.');
			e := RecordByIndex(f, i);
			if Signature(e) <> 'REFR' then continue;
			sCurrentCell := ExtractFirstWord(geev(e, 'CELL'), ' ');
			//DebugReplacement(sCurrentCell+' is the current cell for '+geev(e,'NAME'));
			//Check Exteriors
			if slDawnstarExteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Dawn Exterior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slDawnstarStatics,slDawnstarStaticName,cDawnstarKeyword,sDawnstarLocation);
			end
			else if slFalkreathExteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Falk Exterior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slFalkreathStatics,slFalkreathStaticName,cFalkreathKeyword,sFalkreathLocation);
			end
			else if slMorthalExteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Morthal Exterior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slMorthalStatics,slMorthalStaticName,cMorthalKeyword,sMorthalLocation);
			end
			else if slWinterholdExteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Winterhold Exterior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slWinterholdStatics,slWinterholdStaticName,cWinterholdKeyword,sWinterholdLocation);
			end
			else if geev(e,'CELL') = '[CELL:00000D74] (in Tamriel "Skyrim" [WRLD:0000003C])' then begin
				AddMessage('Ran into persistant records, currently unsuported');
			end
			else if not bDoInteriors then continue
			//Interior Stuff
			else if  slDawnstarInteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Dawn Interior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slDawnstarStatics,slDawnstarStaticName,cDawnstarKeyword,sDawnstarLocation);
			end
			else if slFalkreathInteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Falk Interior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slFalkreathStatics,slFalkreathStaticName,cFalkreathKeyword,sFalkreathLocation);
			end
			else if slMorthalInteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Morthal Interior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slMorthalStatics,slMorthalStaticName,cMorthalKeyword,sMorthalLocation);
			end
			else if slWinterholdInteriorCells.IndexOf(sCurrentCell) <> -1 then begin
				//DebugReplacement('    Winterhold Interior, Currently Working on '+sCurrentCell);
				ReplaceObjects(f,e,slWinterholdStatics,slWinterholdStaticName,cWinterholdKeyword,sWinterholdLocation);
			end;
		end;
	end;
end;



//
//HouseKeeping
//
procedure FreeStrings;
begin
	DebugStrings('Freeing Strings');
	slDawnstarExteriorCells.Free;
	slDawnstarInteriorCells.Free;
	slFalkreathExteriorCells.Free;
	slFalkreathInteriorCells.Free;
	slMorthalExteriorCells.Free;
	slMorthalInteriorCells.Free;
	slWinterholdExteriorCells.Free;
	slWinterholdInteriorCells.Free;
	slIgnoreCells.Free;
	slDawnstarStatics.Free;
	slFalkreathStatics.Free;
	slMorthalStatics.Free;
	slWinterholdStatics.Free;
	slDawnstarStaticName.Free;
	slFalkreathStaticName.Free;
	slMorthalStaticName.Free;
	slWinterholdStaticName.Free;
end;
	
function Initialize: integer;
begin
	CreatePatchFile;
	if not Assigned(iPatchFile) then begin
		AddMessage('Please relaunch the script and enter a valid patch name');
		exit;
	end;
	//Replace with GUI
	bRegenInteriorCells := true;
	bRegenCompatibleStatics := true;
	bDoInteriors := true;
	doLocationRefs := true;
	CreateStrings;
	FillStringLists;
	if bKillScript then begin
		FreeStrings;
		exit;
	end;
	if doDebugStrings then begin
		ReadExteriorLists;
		ReadInteriorLists;
	end;
	if doLocationRefs then begin 
		AddMessage('Looking for Location Data');
		FindLocations;
	end;
	DebugMessage('Running ScanCompatibleStatics');
	ScanCompatibleStatics;
	if doDebugStatics then begin
		AddMessage('Reading Statics and staticName lists');
		ReadStaticsLists;
	end;
	if bKillScript then begin
		FreeStrings;
		exit;
	end;
	DebugMessage('Running FindAndReplaceRecords');
	FindAndReplaceRecords;
	
	FreeStrings;
end;


function Finalize: integer;
begin
	
end;

end.