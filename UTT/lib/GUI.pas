unit GUI;
{
Delete ini and save fresh
}
const
  cDebugParam='doDebugGUI';
  
var
  slDebug, slOptions: TStringList;
  bDoDebug: Boolean;
  sTextureAssetsList: String;
  picGear, picFolder: TPicture;
  
  slWorldSpace: TStringList;//List of worldspaces
  arrayTownLocations: Array[0..255] of TStringList;//Hold the towns for each WorldSpace
  arrayTownPaths: Array[0..255,0..255] of string;
  

procedure Debug_Message(s: string);
begin
  if bDoDebug then AddMessage(s);
end;

procedure Debug_DebugData(sLabel: string; sl: TStringList);
var
  i: int;
begin
  if not bDoDebug then exit;
  AddMessage('Reading '+sLabel+' data');
  for i := 0 to Pred(sl.Count) do
    AddMessage(Inden(2)+sl[i]);
end;

procedure Debug_ReadTownData;
var
  i,j: int;
begin
  AddMessage('Reading off town data.');
  for i := 0 to Pred(slWorldSpace.Count) do
  begin
    AddMessage(Inden(2)+slWorldSpace[i]);
    for j := 0 to Pred(arrayTownLocations[i].Count) do begin
      AddMessage(Inden(4)+arrayTownLocations[i].Strings[j]);
    end;
  end;
end;

procedure Debug_ReadTownPaths;
var
  i, j: int;
begin
  AddMessage('Reading Town Texture Paths.');
  for i := 0 to Pred(slWorldSpace.Count) do
  begin
    AddMessage(Inden(2)+slWorldSpace[i]);
    for j := 0 to Pred(arrayTownLocations[i].Count) do
    begin
      AddMessage(Inden(4)+arrayTownPaths[i,j]);
    end;
  end;
end;
  
procedure Startup;
var
  i: int;
begin
  if not FileExists(cTextureCacheFile) then 
  begin
    CreateDirectories(cTextureCacheFile);
    FileClose(FileCreate(cTextureCacheFile));
  end;
  
  if not FileExists(cTexturePathsFile) then
    FileClose(FileCreate(cTexturePathsFile));
  
  if not FileExists(cEnabledLocationsFile) then 
    FileClose(FileCreate(cEnabledLocationsFile));
    
    
  slDebug := TStringList.Create;
  slOptions := TStringList.Create;
  picGear := TPicture.Create;
  picFolder := TPicture.Create;
  slWorldSpace := TStringList.Create;
  for i := 0 to Pred(Length(arrayTownLocations)) do
    arrayTownLocations[i] := TStringList.Create;
end;

procedure LoadSettings;
begin
  bDoDebug := StrToBool(iniSettings.ReadString('Debug', cDebugParam, 'False'));
  iniSettings.ReadSectionValues('Debug',slDebug);
  iniSettings.ReadSectionValues('Options',slOptions);
  
  //Load Assets
  picGear.LoadFromFile(cWorkingPath+'Assets\Gear.png');
  picFolder.LoadFromFile(cWorkingPath+'Assets\Folder.png');
  
  Debug_DebugData('Debug', slDebug);//Read Debug List
  Debug_DebugData('Options', slOptions);//Read Options List
end;

procedure FillTownData;
var
  iFileIndex, iSectionIndex, iWorldSpaceIndex, iLocationIndex: int;
  slSections, slLocations: TStringList;
  iniCurrentFile: TMemIniFile;
  sFileName, sCurrentSection, sLocation: string;
begin
  for iFileIndex := 0 to Pred(FileCount) do 
  begin
    sFileName := GetFileName(FileByIndex(iFileIndex));
    if not FileExists(cCellRulesPath+sFileName+'.ini') then continue;
    iniCurrentFile := TMemIniFile.Create(cCellRulesPath+sFileName+'.ini');
    slSections := TStringList.Create;
    iniCurrentFile.ReadSections(slSections);
    //Section/WorldSpace Level
    for iSectionIndex := 0 to Pred(slSections.Count) do 
    begin
      sCurrentSection := slSections[iSectionIndex];
      iWorldSpaceIndex := slWorldSpace.IndexOf(sCurrentSection);
      if iWorldSpaceIndex = -1 then iWorldSpaceIndex := slWorldSpace.Add(sCurrentSection);
      slLocations := TStringList.Create;
      iniCurrentFile.ReadSection(sCurrentSection, slLocations);
      //Location/Parameter Level
      for iLocationIndex := 0 to Pred(slLocations.Count) do begin
        sLocation := slLocations[iLocationIndex];
        if arrayTownLocations[0].IndexOf(sLocation) = -1 then
          arrayTownLocations[iWorldSpaceIndex].Add(sLocation);
      end;
      slLocations.Free;
    end;
  iniCurrentFile.Free;
  slSections.Free;
  end;

  if bDoDebug then Debug_ReadTownData;
end;

procedure FillTownPaths;
var
  iWorldSpaceIndex, iLocationIndex, i: int;
  sCurrentWorldSpace, sCurrentLocation, sPath, sDefaultPath: string;
  iniAssetPaths: TMemIniFile;
begin
  iniAssetPaths := TMemIniFile.Create(cTexturePathsFile);
  for iWorldSpaceIndex := 0 to Pred(slWorldSpace.Count) do 
  begin
    sCurrentWorldSpace : = slWorldSpace[iWorldSpaceIndex];
    for iLocationIndex := 0 to Pred(arrayTownLocations[iWorldSpaceIndex].Count) do
    begin
      sCurrentLocation := arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex];
      sDefaultPath := cTexturesPath+sCurrentLocation+'\';
      sPath := iniAssetPaths.ReadString(sCurrentWorldSpace, sCurrentLocation, sDefaultPath);
      if not DirectoryExists(sPath) then
        sPath := sDefaultPath;
      arrayTownPaths[iWorldSpaceIndex,iLocationIndex] := sPath;
    end;
  end;
  iniAssetPaths.Free;
  
  //Erase INI
  try
    DeleteFile(cTexturePathsFile);
    FileClose(FileCreate(cTexturePathsFile));
  except
    raise Exception.Create(lang.Values['sFailedOnRefeshINI']+cTexturePathsFile);
  end;
  
  //Write Data
  iniAssetPaths := TMemIniFile.Create(cTexturePathsFile);
  for iWorldSpaceIndex := 0 to Pred(slWorldSpace.Count) do
  begin
    for iLocationIndex := 0 to Pred(arrayTownLocations[iWorldSpaceIndex].Count) do 
    begin
      iniAssetPaths.WriteString(slWorldSpace[iWorldSpaceIndex], arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex], arrayTownPaths[iWorldSpaceIndex, iLocationIndex]);
      AddMessage(slWorldSpace[iWorldSpaceIndex]+arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex]+arrayTownPaths[iWorldSpaceIndex, iLocationIndex]);
    end;
  end;
  iniAssetPaths.UpdateFile;
  iniAssetPaths.Free;
  if bDoDebug then Debug_ReadTownPaths;
end;

procedure OptionsMenu;
var
  ofrm: TForm;
begin
  AddMessage('Running Options GUI');
  ofrm := TForm.Create(nil);
    ofrm.BorderStyle := bsDialog;
    ofrm.Caption := 'Options';
    ofrm.Width := 600;
    ofrm.Position := poScreenCenter;
    ofrm.Height := 650;
    
  ofrm.ShowModal;
  
  ofrm.Free;
end;

procedure DetailedInfo(gb: TGroupBox);
var
  lblPluginFile, lblWorkingDir, lblVerScript, lblIniVer: TLabel;
begin
  lblPluginFile := cLabel(gb, gb, 15, 5, 15, gb.Width, Lang.Values['sCurrentPluginFile']+cPatchFile, '');
  lblWorkingDir := cLabel(gb, gb, 30, 5, 15, gb.Width, Lang.Values['sCurrentWorkingDirectiory']+'"'+cWorkingPath+'"', '');
  lblVerScript := cLabel(gb, gb, 45, 5, 15, gb.Width, lang.Values['sScriptVer']+cVer, '');
  lblIniVer := cLabel(gb, gb, 60, 5, 15, gb.Width, lang.Values['sIniVer']+iniSettings.ReadString('General','IniVer', 'Invalid'), '');
end;

procedure LocationInfo(sb: TScrollBox);
var
  bTemp: Boolean;
  iWorldSpaceIndex, iLocationIndex: int;
  iniEnabledLocations: TMemIniFile;
  recTemp: TSearchrec;
  
  lblWorldSpace: Array[0..255] of TLabel;
  cbLocations: Array[0..255,0..255] of TCheckBox;
  lblLocations: Array[0..255,0..255] of TLabel;
begin
  iniEnabledLocations := TMemIniFile.Create(cEnabledLocationsFile);
  
  for iWorldSpaceIndex := 0 to Pred(slWorldSpace.Count) do
  begin
    if iWorldSpaceIndex = 0 then
      lblWorldSpace[iWorldSpaceIndex] := cLabel(sb, sb, 5, 5, 0, 0, slWorldSpace[iWorldSpaceIndex], '')
    else
      lblWorldSpace[iWorldSpaceIndex] := cLabel(sb, sb, 15+lblWorldSpace[iWorldSpaceIndex-1].Top+(20*(arrayTownLocations[iWorldSpaceIndex-1].Count)), 5, 0, 0, slWorldSpace[iWorldSpaceIndex], '');
    
    for iLocationIndex := 0 to Pred(arrayTownLocations[iWorldSpaceIndex].Count) do
    begin
      bTemp := StrToBool(iniEnabledLocations.ReadString(slWorldSpace[iWorldSpaceIndex],arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex],'False'));
      cbLocations[iWorldSpaceIndex,iLocationIndex] := cCheckBox(sb, sb, (lblWorldSpace[iWorldSpaceIndex].Top+15)+(20*iLocationIndex), 25, 75, arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex], bTemp, '');
      cbLocations[iWorldSpaceIndex,iLocationIndex].Enabled := FindFirst(arrayTownPaths[iWorldSpaceIndex,iLocationIndex], faAnyFile AND faDirectory, recTemp) = 0;
      FileClose(recTemp);
      lblLocations[iWorldSpaceIndex, iLocationIndex] := cLabel(sb, sb, cbLocations[iWorldSpaceIndex,iLocationIndex].Top, cbLocations[iWorldSpaceIndex,iLocationIndex].Left+cbLocations[iWorldSpaceIndex,iLocationIndex].Width+15, 0, 140, 'Test', '');
    end;
  end;
  iniEnabledLocations.Free;
end;

procedure frm.CheckAll(sender: TObject);
var 
  i: int;
begin
  for i := 0 to Pred(sender.Owner.ComponentCount) do
    if sender.Owner.Components[i].ClassName = 'TCheckBox' then
      sender.Owner.Components[i].Checked := True;
end;
procedure frm.UncheckAll(sender: TObject);
var 
  i: int;
begin
  for i := 0 to Pred(sender.Owner.ComponentCount) do
    if sender.Owner.Components[i].ClassName = 'TCheckBox' then
      sender.Owner.Components[i].Checked := False;
end;

procedure CreateGUI;
var
  i: int;
  
  frm: TForm;
  gbWindow, gbDetails, gbLocations, gbOptions, gbDebug: TGroupBox;
  lblTitle, lblDebug: TLabel;
  sbLocations: TScrollBox;
  btnRun, btnCancel, btnCheckAll, btnUncheckAll: TButton;
  imgOptions: TImage;
  
  cbOptions: Array[0..255] of TCheckBox;
  
  cbDebug: Array[0..255] of TCheckBox;
begin
  AddMessage(Lang.Values['DisplayGUI']);
  frm := TForm.Create(nil);
    frm.Caption := Lang.Values['sTitle'];
    frm.Width := 650;
    frm.Height := 700;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
  
    //MainWindow
    gbWindow := cGroup(frm, frm, 0, 0, frm.height, frm.Width+9, '', '');
    
    //Title
    lblTitle := cLabel(gbWindow, gbWindow, 5, (gbWindow.Width-380)/2, 50, 380, frm.Caption, '');
    lblTitle.Font.Size := 28;
    
    gbDetails := TGroupBox.Create(frm);
      gbDetails.Parent := gbWindow;
      gbDetails.Top := gbWindow.Height-110;
      gbDetails.Left := 10;
      gbDetails.Height := gbWindow.Height-(gbDetails.Top+30);
      gbDetails.Width := 350;
      gbDetails.Caption := Lang.Values['sDetails'];
    
    DetailedInfo(gbDetails);
    
    gbLocations := TGroupBox.Create(frm);
      gbLocations.Parent := gbWindow;
      gbLocations.Top := lblTitle.Top+lblTitle.Height+15;
      gbLocations.Left := 5;
      gbLocations.Height := gbWindow.Height-(gbLocations.Top+(gbWindow.Height-gbDetails.Top)+45);
      gbLocations.Width := (gbWindow.Width/2)-5;
      gbLocations.Caption := Lang.Values['sSelectLocationsToAffect'];
    sbLocations := TScrollBox.Create(gbLocations);
      sbLocations.Parent := gbLocations;
      sbLocations.Top := 0;
      sbLocations.Left := 0;
      sbLocations.Height := gbLocations.Height;
      sbLocations.Width := gbLocations.Width;
      
    LocationInfo(sbLocations);
    
    //Options box
    gbOptions := cGroup(frm, gbWindow, gbLocations.Top-5, (gbLocations.Width+20), (20*(slOptions.Count))+45, gbLocations.Width, 'Options', '');
    for i := 0 to Pred(slOptions.Count) do
      cbOptions[i] := cCheckBox(gbOptions, gbOptions, (i*20)+20, 20, 150, slOptions.Names[i], StrToBool(slOptions.ValueFromIndex[i]), '');
    
    //Debug box
    gbDebug := cGroup(frm, gbWindow, gbOptions.Top+gbOptions.Height+35, gbOptions.Left, (20*(slDebug.Count))+60, gbLocations.Width, Lang.Values['sDebugOptions'], '');
    lblDebug := cLabel(gbDebug, gbDebug, 20, 5, 15, gbDebug.Width-30, Lang.Values['sSomeDebugRunOnStart'], '');
    for i := 0 to Pred(slDebug.Count) do
      cbDebug[i] := cCheckBox(gbDebug, gbDebug,(i*20)+5+lblDebug.Height+lblDebug.Top,20,150,slDebug.Names[i],StrToBool(slDebug.ValueFromIndex[i]), '');
    
    //Modal Buttons
    btnCancel := cButton(frm, gbWindow, gbWindow.Height-70, (gbDetails.Left+gbDetails.Width)+135, 40, 85, 'Cancel');
      btnCancel.ModalResult := mrCancel;
    btnRun := cButton(frm, gbWindow, btnCancel.Top, btnCancel.Left-100, btnCancel.Height, btnCancel.Width, 'Run');
      btnRun.ModalResult := mrOk;
    
    btnCheckAll := cButton(sbLocations, gbWindow, gbLocations.Top+gbLocations.Height+5, gbLocations.Left+40, 25, 75, 'Check All');
      btnCheckAll.OnClick := CheckAll;
    btnUncheckAll := cButton(sbLocations, gbWindow, btnCheckAll.Top, btnCheckAll.Left+btnCheckAll.Width+50, 25, 75, 'Uncheck All');
      btnUncheckAll.OnClick := UncheckAll;

    imgOptions := cImage(gbWindow, gbWindow, gbWindow.Height-62, gbWindow.Width-43, 30, 30, picGear, '');
      imgOptions.OnClick := OptionsMenu;
    
    frm.ShowModal;
  frm.Free;  
end;

procedure FreeMemory;
var
  i: int;
begin
  picFolder.Free;
  picGear.Free;
  slDebug.Free;
  slWorldSpace.Free;

  for i := 0 to Pred(Length(arrayTownLocations)) do
    arrayTownLocations[i].Free;
    
end;

procedure StartGUI;
begin
  AddMessage(Lang.Values['sIntroGUI']);
  Startup;
  LoadSettings;
  FillTownData;
  FillTownPaths;
  CreateGUI;
  
  
  //SaveSettings;
  FreeMemory;
end;

end.