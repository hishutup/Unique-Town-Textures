unit GUI;
uses mteFunctions;
uses 'UTT\lib\FileHandling';
{
Delete ini and save fresh
}
const
  cDebugParam='doDebugGUI';
  
var
  slDebug, slOptions: TStringList;
  bDoDebug, bBusy: Boolean;
  sTextureAssetsList: String;
  picGear, picFolder, picUndo, picError, picCheck, picReset: TPicture;
  iniAssetPaths, iniEnabledLocations: TMemIniFile;
  
  slWorldSpace: TStringList;//List of worldspaces
  arrayTownLocations: Array[0..255] of TStringList;//Hold the towns for each WorldSpace
  arrayTownPaths: Array[0..255,0..255] of string;
  
  //frm.Locations
  pnlMasterWorld: Array[0..255] of TPanel;
  cbMasterLocations: Array[0..255,0..255] of TCheckBox;
  lblMasterLocations: Array[0..255,0..255] of TLabel;
  cbMasterWorld: Array[0..255] of TCheckBox;
  
  

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
      AddMessage(Inden(6)+GetLastFolder(arrayTownPaths[i,j]));
      if DirContainsFiles(arrayTownPaths[i,j], cRecuriveDepth) then AddMessage(Inden(6)+'Contains files.');
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
  picUndo := TPicture.Create;
  picError := TPicture.Create;
  picCheck := TPicture.Create;
  picReset := TPicture.Create;
 
  iniAssetPaths := TMemIniFile.Create(cTexturePathsFile);
  iniEnabledLocations := TMemIniFile.Create(cEnabledLocationsFile);
  
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
  picUndo.LoadFromFile(cWorkingPath+'Assets\Undo.png');
  picError.LoadFromFile(cWorkingPath+'Assets\Error.png');
  picCheck.LoadFromFile(cWorkingPath+'Assets\Check.png');
  picReset.LoadFromFile(cWorkingPath+'Assets\Reset.png');
  
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
begin
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
      iniAssetPaths.WriteString(slWorldSpace[iWorldSpaceIndex], arrayTownLocations[iWorldSpaceIndex].Strings[iLocationIndex], arrayTownPaths[iWorldSpaceIndex, iLocationIndex]);
  end;
  iniAssetPaths.UpdateFile;
  if bDoDebug then Debug_ReadTownPaths;
end;

procedure ofrm.CheckStatus(sender: TObject);
var
  i, j: int;
begin
  if DirContainsFiles(sender.Owner.Components[1].Caption,cRecuriveDepth) then
    sender.Owner.Components[4].Picture := picCheck
  else
    sender.Owner.Components[4].Picture := picError;
end;

procedure ofrm.Undo(sender: TObject);
var
  sCurrentPath, sWorld, sLocation, sRecordedPath, sDefaultPath: string;
  i, j: int;
begin
  sCurrentPath := sender.Owner.Components[1].Caption;
  sWorld := sender.Owner.Owner.Components[0].Caption;
  sLocation := Copy(sender.Owner.Components[0].Caption,1,Pos(':',sender.Owner.Components[0].Caption)-1);
  i := slWorldSpace.IndexOf(sWorld);
  if i = -1 then 
    raise Exception.Create(lang.Values['sGUIErrorFindWorld']);
  j := arrayTownLocations[i].IndexOf(sLocation);
  if j = -1 then
    raise Exception.Create(lang.Values['sGUIErrorFindLocation']);
  sRecordedPath := arrayTownPaths[i,j];
  sDefaultPath := cTexturesPath+sLocation+'\';
  if (sCurrentPath = sRecordedPath) then
    sender.Owner.Components[1].Caption := sDefaultPath
  else if not (sCurrentPath = sDefaultPath) then 
    sender.Owner.Components[1].Caption := sRecordedPath;
  
  if DirContainsFiles(sender.Owner.Components[1].Caption,cRecuriveDepth) then
    sender.Owner.Components[4].Picture := picCheck
  else
    sender.Owner.Components[4].Picture := picError;
end;

procedure ofrm.ShowAssetsWindow(sender: TOject);
var
  sTemp: string;
  i: int;
begin
  sTemp := sender.Owner.Components[0].Caption;
  sTemp := SelectDirectory(Lang.Values['sSelectDir'], cTexturesPath, sTemp, nil);
  if sTemp = '' then exit;
  sTemp := AppendIfMissing(sTemp,'\');
  if DirContainsFiles(sTemp,cRecuriveDepth) then
  begin
    sender.Owner.Components[1].Caption := sTemp;
    sender.Owner.Components[4].Picture := picCheck;
  end
  else
    AddMessage(Lang.Values['sInvalidPath']);
end;

procedure ofrm.RevertAllPaths(sender: TObject);
var
  i,j,x: int;
begin
  AddMessage(Inden(2)+'Reverting');
  for i := 0 to Pred(sender.Owner.ComponentCount) do
  begin
    if not (sender.Owner.Components[i].ClassName = 'TPanel') then continue;
    for j := 0 to Pred(sender.Owner.Components[i].ComponentCount) do
    begin
      if not (sender.Owner.Components[i].Components[j].ClassName = 'TPanel') then continue;
      for x := 0 to Pred(sender.Owner.Components[i].Components[j].ComponentCount) do
      begin
        if not (sender.Owner.Components[i].Components[j].Components[x].ClassName = 'TLabel') then continue;
        AddMessage(sender.Owner.Components[i].Components[j].Components[x+1].Caption);
        sender.Owner.Components[i].Components[j].Components[x+1].Caption := cTexturesPath+Copy(sender.Owner.Components[i].Components[j].Components[x].Caption,1,Pos(':',sender.Owner.Components[i].Components[j].Components[x].Caption)-1)+'\';
        if DirContainsFiles(sender.Owner.Components[i].Components[j].Components[x+1].Caption,cRecuriveDepth) then
          sender.Owner.Components[i].Components[j].Components[x+4].Picture := picCheck
        else
          sender.Owner.Components[i].Components[j].Components[x+4].Picture := picError;
        break;
      end;
    end;
  end;
end;

procedure OptionsMenu(sender: TObject);
var
  i, j: int;
  ofrm: TForm;
  gbWindow, gbLocations: TGroupBox;
  sbLocations: TScrollBox;
  btnSave, btnDiscard, btnRevert: TButton;
  bVisible: Boolean;
  
  pnlWorld: Array[0..255] of TPanel;
  lblWorld: Array[0..255] of TLabel;
  pnlLocation: Array[0..255,0..255] of TPanel;
  lblLocation: Array[0..255,0..255] of TLabel;
  lblLocationPath: Array[0..255,0..255] of TLabel;
  imgStatus: Array[0..255,0..255] of TImage;
  imgUndo: Array[0..255,0..255] of TImage;
  imgFolder: Array[0..255,0..255] of TImage;
  
  
begin
  AddMessage('Running Options GUI');
  ofrm := TForm.Create(nil);
    ofrm.BorderStyle := bsDialog;
    ofrm.Caption := 'Options';
    ofrm.Width := 700;
    ofrm.Position := poScreenCenter;
    ofrm.Height := 350;
    
    
    //MainWindow
    gbWindow := cGroup(ofrm, ofrm, 0, 0, ofrm.height, ofrm.Width+9, '', '');
    
    gbLocations := TGroupBox.Create(ofrm);
      gbLocations.Parent := gbWindow;
      gbLocations.Top := 15;
      gbLocations.Left := 5;
      gbLocations.Height := gbWindow.Height-(gbLocations.Top+45);
      gbLocations.Width := gbWindow.Width-25;
      gbLocations.Caption := Lang.Values['sSelectLocationsToAffect'];
      
    sbLocations := TScrollBox.Create(gbLocations);
      sbLocations.Parent := gbLocations;
      sbLocations.Top := 0;
      sbLocations.Left := 0;
      sbLocations.Height := gbLocations.Height;
      sbLocations.Width := gbLocations.Width;
      sbLocations.HorzScrollBar.Visible := False;
      sbLocations.VertScrollBar.Tracking := True;
    
    for i := 0 to Pred(slWorldSpace.Count) do
    begin
      pnlWorld[i] := TPanel.Create(sbLocations);
        pnlWorld[i].Parent := sbLocations;
      if i = 0 then 
        pnlWorld[i].Top := 0
      else 
        pnlWorld[i].Top := 23+pnlWorld[i-1].Top+(20*arrayTownLocations[i-1].Count);
        pnlWorld[i].Left := 0;
        pnlWorld[i].Height := 23+(20*arrayTownLocations[i].Count);
        pnlWorld[i].Width := sbLocations.Width;
        
      lblWorld[i] := TLabel.Create(pnlWorld[i]);
        lblWorld[i].Parent := pnlWorld[i];
        lblWorld[i].Top := 5;
        lblWorld[i].Left := 5;
        lblWorld[i].Height := (20*(arrayTownLocations[i].Count+1))+25;
        lblWorld[i].Width := pnlWorld[i].Width;
        lblWorld[i].Caption := slWorldSpace[i];  
      for j := 0 to Pred(arrayTownLocations[i].Count)do
      begin
        pnlLocation[i,j] := TPanel.Create(pnlWorld[i]);
          pnlLocation[i,j].Parent := pnlWorld[i];
        if j = 0 then
          pnlLocation[i,j].Top := lblWorld[i].Top+lblWorld[i].Height+5
        else
          pnlLocation[i,j].Top := pnlLocation[i,j-1].Top+pnlLocation[i,j-1].Height;
          pnlLocation[i,j].Left := 0;
          pnlLocation[i,j].Height := 20;
          pnlLocation[i,j].Width := pnlWorld[i].Width;
          
        lblLocation[i,j] := TLabel.Create(pnlLocation[i,j]);
          lblLocation[i,j].Parent := pnlLocation[i,j];
          lblLocation[i,j].Top := 2;
          lblLocation[i,j].Left := 20;
          lblLocation[i,j].Height := 15;
          lblLocation[i,j].Width := 90;
          lblLocation[i,j].Caption := arrayTownLocations[i].Strings[j]+': ';
          
        lblLocationPath[i,j] := TLabel.Create(pnlLocation[i,j]);
          lblLocationPath[i,j].Parent := pnlLocation[i,j];
          lblLocationPath[i,j].Top := 2;
          lblLocationPath[i,j].Left := lblLocation[i,j].Left+100;
          lblLocationPath[i,j].Height := 15;
          lblLocationPath[i,j].Width := pnlLocation[i,j].Width -lblLocationPath[i,j].Left;
          lblLocationPath[i,j].Caption := arrayTownPaths[i,j];
          
        imgFolder[i,j] := TImage.Create(pnlLocation[i,j]);
          imgFolder[i,j].Parent := pnlLocation[i,j];
          imgFolder[i,j].Top := -5;
        if sbLocations.VertScrollBar.Visible then
          imgFolder[i,j].Left := pnlLocation[i,j].Width-50
        else
          imgFolder[i,j].Left := pnlLocation[i,j].Width-30;
          imgFolder[i,j].Height := 20;
          imgFolder[i,j].Width := 20;
          imgFolder[i,j].Picture := picFolder;
          imgFolder[i,j].OnClick := ShowAssetsWindow;
          
        imgUndo[i,j] := TImage.Create(pnlLocation[i,j]);
          imgUndo[i,j].Parent := pnlLocation[i,j];
          imgUndo[i,j].Top := 3;
          imgUndo[i,j].Left := imgFolder[i,j].Left-20;
          imgUndo[i,j].Height := 20;
          imgUndo[i,j].Width := 20;
          imgUndo[i,j].Picture := picUndo;
          imgUndo[i,j].OnClick := Undo;
          
        imgStatus[i,j] := TImage.Create(pnlLocation[i,j]);
          imgStatus[i,j].Parent := pnlLocation[i,j];
          imgStatus[i,j].Top := 3;
          imgStatus[i,j].Left := imgUndo[i,j].Left-20;
          imgStatus[i,j].Height := 20;
          imgStatus[i,j].Width := 20;
          imgStatus[i,j].OnClick := CheckStatus;
        if DirContainsFiles(lblLocationPath[i,j].Caption,cRecuriveDepth) then
          imgStatus[i,j].Picture := picCheck
        else
          imgStatus[i,j].Picture := picError;
          
      end;
    end;
    
  btnSave := TButton.Create(sbLocations);
    btnSave.Parent := gbWindow;
    btnSave.Caption := Lang.Values['sSave'];
    btnSave.ModalResult := mrOk;
    btnSave.Left := gbWindow.Width-(btnSave.Width+200);
    btnSave.Top := gbWindow.Height-(btnSave.Height+20);

  btnDiscard := TButton.Create(sbLocations);
    btnDiscard.Parent := gbWindow;
    btnDiscard.Caption := Lang.Values['sDiscard'];
    btnDiscard.ModalResult := mrCancel;
    btnDiscard.Left := btnSave.Left + btnSave.Width + 15;
    btnDiscard.Top := btnSave.Top;
    
  btnRevert := TButton.Create(sbLocations);
    btnRevert.Parent := gbWindow;
    btnRevert.Caption := Lang.Values['sRevertAll'];
    btnRevert.OnClick := RevertAllPaths;
    btnRevert.Left := btnDiscard.Left + btnDiscard.Width+15;
    btnRevert.Top := btnSave.Top;
    
  ofrm.ShowModal;
  //Update everything
  
  if ofrm.ModalResult = mrOk then
  begin
    for i := 0 to Pred(slWorldSpace.Count) do
    begin
      for j := 0 to Pred(arrayTownLocations[i].Count)do
      begin
        if imgStatus[i,j].Picture = picError then continue;
        arrayTownPaths[i,j] := lblLocationPath[i,j].Caption;
      end;
    end;
    
    for i := 0 to Pred(slWorldSpace.Count) do
    begin
      for j := 0 to Pred(arrayTownLocations[i].Count) do
      begin
        arrayTownPaths[i,j] := lblLocationPath[i,j].Caption;
        lblMasterLocations[i,j].Caption := '\UTT'+GetLastFolder(arrayTownPaths[i,j]);
        cbMasterLocations[i,j].Enabled := DirContainsFiles(arrayTownPaths[i,j],cRecuriveDepth);
        bVisible := cbMasterLocations[i,j].Enabled OR bVisible;
      end;
      
      pnlMasterWorld[i].Visible := bVisible;
      bVisible := False;
    end;
    
    SetMasterWorldPanelSpacing;
  end;
  
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

procedure WorldOnCLick(sender: TObject);
var
  i: int;
begin
  if bBusy then exit;
  bBusy := True;
  for i := 0 to Pred(sender.Owner.Components[1].ComponentCount) do
  begin
    if sender.Owner.Components[1].Components[i].ClassName = 'TLabel' then continue;
    if sender.Checked then
      sender.Owner.Components[1].Components[i].Checked := True AND sender.Owner.Components[1].Components[i].Enabled
    else
      sender.Owner.Components[1].Components[i].Checked := False;
    sender.Owner.Components[0].AllowGrayed := False
  end;
  bBusy := False;
end;

procedure SetMasterWorldPanelSpacing;
var
  bFirst: Boolean;
  i, iScrollTemp: int;
  cSpacing: Cardinal;
begin
  bFirst := True;
  for i := 0 to Pred(Length(pnlMasterWorld)) do
  begin
    if not Assigned(pnlMasterWorld[i]) then continue;
    if not pnlMasterWorld[i].Visible then continue;
    
    iScrollTemp := pnlMasterWorld[i].Owner.VertScrollBar.Position;
    pnlMasterWorld[i].Owner.VertScrollBar.Position := 0;
    
    if bFirst then
    begin
      pnlMasterWorld[i].Top := 0;
      cSpacing := pnlMasterWorld[i].Height;
      bFirst := False;
    end
    else
    begin
      pnlMasterWorld[i].Top := cSpacing;
      cSpacing := cSpacing + pnlMasterWorld[i].Height;
    end;
    
    if iScrollTemp <= cSpacing then 
      pnlMasterWorld[i].Owner.VertScrollBar.Position := iScrollTemp
    else
      pnlMasterWorld[i].Owner.VertScrollBar.Position := 0;
  end;
end;

procedure ofrm.UpdateCheckBoxStatus;
var
  iPanel, iCompon, iWorldButton, i, j: int;
  bAll, bOne: Boolean;
begin
  if bBusy then exit;
  bBusy := True;
  for iPanel := 0 to Pred(slWorldSpace.Count) do
  begin
    bAll := True;
    bOne := False;
    for iCompon := 0 to Pred(pnlMasterWorld[iPanel].ComponentCount) do
    begin
      if pnlMasterWorld[iPanel].Components[iCompon].ClassName = 'TCheckBox' then
      begin
        if pnlMasterWorld[iPanel].Components[iCompon+1].ClassName = 'TPanel' then
        begin
          for i := 0 to Pred(pnlMasterWorld[iPanel].Components[iCompon+1].ComponentCount) do
          begin
            if pnlMasterWorld[iPanel].Components[iCompon+1].Components[i].ClassName = 'TCheckBox' then
            begin
              if not pnlMasterWorld[iPanel].Components[iCompon+1].Components[i].Enabled then continue;
              if pnlMasterWorld[iPanel].Components[iCompon+1].Components[i].Checked then
                bOne := True
              else
                bAll := False;
            end;
          end;
        end;
        if bAll then
        begin 
          pnlMasterWorld[iPanel].Components[iCompon].AllowGrayed := False;
          pnlMasterWorld[iPanel].Components[iCompon].State := cbChecked;
        end
        else if bOne then
        begin
          pnlMasterWorld[iPanel].Components[iCompon].AllowGrayed := True;
          pnlMasterWorld[iPanel].Components[iCompon].State := cbGrayed;
        end
        else
        begin
          pnlMasterWorld[iPanel].Components[iCompon].AllowGrayed := False;
          pnlMasterWorld[iPanel].Components[iCompon].State := cbUnchecked;
        end;
      end;
    end;
    
  end;
  bBusy := False;
end;

procedure LocationInfo(sb: TScrollBox);
var
  bTemp, bVisible: Boolean;
  i, j, iSpacing: int;
  
  lblWorldSpace: Array[0..255] of TLabel;
  pnlLocation: Array[0..255] of TPanel;
begin
  
  for i := 0 to Pred(slWorldSpace.Count) do
  begin
    pnlMasterWorld[i] := TPanel.Create(sb);
      pnlMasterWorld[i].Parent := sb;
      pnlMasterWorld[i].Top := 0;//Will set later via SetMasterWorldPanelSpacing;
      pnlMasterWorld[i].Left := 0;
      pnlMasterWorld[i].Height := (20*(arrayTownLocations[i].Count+1))+5;
      pnlMasterWorld[i].Width := sb.Width;
    
    cbMasterWorld[i] := TCheckBox.Create(pnlMasterWorld[i]);
      cbMasterWorld[i].Parent := pnlMasterWorld[i];
      cbMasterWorld[i].Top := 0;
      cbMasterWorld[i].Left := 5;
      cbMasterWorld[i].Height := 15;
      cbMasterWorld[i].Width := 140;
      cbMasterWorld[i].Caption := slWorldSpace[i];
      cbMasterWorld[i].OnClick := WorldOnClick;
    
    pnlLocation[i] := TPanel.Create(pnlMasterWorld[i]);
      pnlLocation[i].Parent := pnlMasterWorld[i];
      pnlLocation[i].Top := 20;
      pnlLocation[i].Left := 0;
      pnlLocation[i].Height := (20*arrayTownLocations[i].Count)+10;
      pnlLocation[i].Width := pnlMasterWorld[i].Width-pnlLocation[i].Left;
      
    
    
    for j := 0 to Pred(arrayTownLocations[i].Count) do
    begin
      bTemp := StrToBool(iniEnabledLocations.ReadString(slWorldSpace[i],arrayTownLocations[i].Strings[j],'False'));
      cbMasterLocations[i,j] := cCheckBox(pnlLocation[i], pnlLocation[i], (20*j)+5, 25, 90, arrayTownLocations[i].Strings[j], bTemp, '');
      cbMasterLocations[i,j].Enabled := DirContainsFiles(arrayTownPaths[i,j], cRecuriveDepth);
      cbMasterLocations[i,j].OnClick := UpdateCheckBoxStatus;
      lblMasterLocations[i, j] := cLabel(pnlLocation[i], pnlLocation[i], cbMasterLocations[i,j].Top, cbMasterLocations[i,j].Left+cbMasterLocations[i,j].Width+15, 0, 120, '\UTT'+GetLastFolder(arrayTownPaths[i,j]), '');
      
      
      bVisible := cbMasterLocations[i,j].Enabled OR bVisible;
    end;
    
    //No reason to show the panel if it unusable
    pnlMasterWorld[i].Visible := bVisible;
    bVisible := False;
  end;
  UpdateCheckBoxStatus;
  SetMasterWorldPanelSpacing;
end;

procedure frm.CheckAll(sender: TObject);
var 
  i, j: int;
begin
  for i := 0 to Pred(sender.Owner.ComponentCount) do
    if sender.Owner.Components[i].ClassName = 'TPanel' then
      for j := 0 to Pred(sender.Owner.Components[i].ComponentCount) do
        if sender.Owner.Components[i].Components[j].ClassName = 'TCheckBox' then
          sender.Owner.Components[i].Components[j].Checked := True ;
end;
procedure frm.UncheckAll(sender: TObject);
var 
  i, j: int;
begin
  for i := 0 to Pred(sender.Owner.ComponentCount) do
    if sender.Owner.Components[i].ClassName = 'TPanel' then
      for j := 0 to Pred(sender.Owner.Components[i].ComponentCount) do
        if sender.Owner.Components[i].Components[j].ClassName = 'TCheckBox' then
          sender.Owner.Components[i].Components[j].Checked := False;
end;
procedure frm.DebugUpdate(sender: TObject);
var
  i: int;
begin
  for i := 0 to Pred(sender.Owner.ComponentCount) do
    if (i <> sender.ComponentIndex) AND (sender.Owner.Components[i].ClassName = 'TCheckBox') then
    begin
      sender.Owner.Components[i].Enabled := sender.Checked;
      sender.Owner.Components[i].Checked := sender.Owner.Components[i].Checked AND sender.Checked;
    end;
end;

procedure CreateGUI;
var
  i,j: int;
  
  frm: TForm;
  gbWindow, gbDetails, gbLocations, gbOptions, gbDebug: TGroupBox;
  lblTitle, lblDebug: TLabel;
  sbLocations: TScrollBox;
  btnRun, btnCancel, btnCheckAll, btnUncheckAll: TButton;
  imgOptions: TImage;
  
  cbOptions: Array[0..255] of TCheckBox;
  
  cbDebug: Array[0..255] of TCheckBox;
begin
  AddMessage(Lang.Values['sDisplayGUI']);
  frm := TForm.Create(nil);
    frm.Caption := Lang.Values['sTitle'];
    frm.Width := 700;
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
    
    gbLocations := TGroupBox.Create(gbWindow);
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
      sbLocations.HorzScrollBar.Visible := False;
      sbLocations.VertScrollBar.Tracking := True;
      
    LocationInfo(sbLocations);
    
    //Options box
    gbOptions := cGroup(frm, gbWindow, gbLocations.Top-5, (gbLocations.Width+20), (20*(slOptions.Count))+45, gbLocations.Width, 'Options', '');
    for i := 0 to Pred(slOptions.Count) do 
      cbOptions[i] := cCheckBox(gbOptions, gbOptions, (i*20)+20, 20, 150, slOptions.Names[i], StrToBool(slOptions.ValueFromIndex[i]), '');
    
    //Debug box
    gbDebug := cGroup(frm, gbWindow, gbOptions.Top+gbOptions.Height+35, gbOptions.Left, (20*(slDebug.Count))+60, gbLocations.Width, Lang.Values['sDebugOptions'], '');
    lblDebug := cLabel(gbDebug, gbDebug, 20, 5, 15, gbDebug.Width-30, Lang.Values['sSomeDebugRunOnStart'], '');
    for i := 0 to Pred(slDebug.Count) do
    begin
      cbDebug[i] := cCheckBox(gbDebug, gbDebug,(i*20)+5+lblDebug.Height+lblDebug.Top,20,150,slDebug.Names[i],StrToBool(slDebug.ValueFromIndex[i]), '');
      if i > 0 then
      begin
        cbDebug[i].Enabled := cbDebug[0].Checked;
        cbDebug[i].Checked := cbDebug[i].Checked AND cbDebug[0].Checked;
      end;
    end;
    cbDebug[0].OnClick := DebugUpdate;
    
    //Modal Buttons
    btnCancel := cButton(frm, gbWindow, gbWindow.Height-70, (gbDetails.Left+gbDetails.Width)+155, 40, 85, 'Cancel');
      btnCancel.ModalResult := mrCancel;
    btnRun := cButton(frm, gbWindow, btnCancel.Top, btnCancel.Left-100, btnCancel.Height, btnCancel.Width, 'Run');
      btnRun.ModalResult := mrOk;
    
    btnCheckAll := cButton(sbLocations, gbWindow, gbLocations.Top+gbLocations.Height+5, gbLocations.Left+40, 25, 75, 'Check All');
      btnCheckAll.OnClick := CheckAll;
    btnUncheckAll := cButton(sbLocations, gbWindow, btnCheckAll.Top, btnCheckAll.Left+btnCheckAll.Width+50, 25, 75, 'Uncheck All');
      btnUncheckAll.OnClick := UncheckAll;

    imgOptions := cImage(gbWindow, gbWindow, gbWindow.Height-55, gbWindow.Width-45, 35, 35, picGear, '');
      imgOptions.OnClick := OptionsMenu;
    
    
    frm.ShowModal;
    
    if frm.ModalResult = mrOk then
    begin
      for i := 0 to Pred(slWorldSpace.Count) do
      begin
        for j := 0 to Pred(arrayTownLocations[i].Count) do
        begin
          iniAssetPaths.WriteString(slWorldSpace[i], arrayTownLocations[i].Strings[j], arrayTownPaths[i,j]);
          iniEnabledLocations.WriteString(slWorldSpace[i], arrayTownLocations[i].Strings[j], BoolToStr(cbMasterLocations[i,j].Checked));
        end;
      end;
      
      //Debug
      for i := 0 to Pred(slDebug.Count) do
        iniSettings.WriteString('Debug', slDebug.Names[i], BoolToStr(cbDebug[i].Checked));
        
      //Options
      for i := 0 to Pred(slOptions.Count) do
        iniSettings.WriteString('Options', slOptions.Names[i], BoolToStr(cbOptions[i].Checked));
      
      iniAssetPaths.UpdateFile;
      iniSettings.UpdateFile;
      iniEnabledLocations.UpdateFile;
    end;
  frm.Free;  
end;

procedure FreeMemory;
var
  i: int;
begin
  picFolder.Free;
  picGear.Free;
  picUndo.Free;
  picError.Free;
  picCheck.Free;
  picReset.Free;
  slDebug.Free;
  slWorldSpace.Free;
  iniAssetPaths.Free;
  iniEnabledLocations.Free;

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