{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit UTT_CreateGUI;
uses mteFunctions,'UTT\lib\HishyFunctions';

const
  cWorkingDir='UTT\';
  cSettings='Settings.ini';
  cCellEnable='EnabledLocations.ini';
  cTextureIni='TexturePath.ini';
  
  cMissingDir='Textures Folder Not Found';
var
  slDebugData, slOptionsData, slWorld: TStringList;
  sScriptFailedReason, sAssetPath: String;
  aCity: Array[0..255] of TStringList;
  bDoDebug: Boolean;
  
	
  cbAreas: Array[0..255,0..255] of TCheckBox;
  cbDebug: Array[0..255] of TCheckBox;
  cbOptions: Array[0..255] of TCheckBox;
  lblWorld: Array[0..255] of TLabel;
  lblDisabledAreas: Array[0..255,0..255] of TLabel;
  //Options
  lblTexture: Array[0..255,0..255] of TLabel;
  picGear, picFolder: TPicture;

//
//Inital Setup
//============================================================================================================= 
procedure InitalSetup;
begin
  if not CheckINI(cWorkingDir, cSettings) then begin
    sScriptFailedReason := 'You are missing "'+cWorkingDir+cSettings+'". Please reinstall the "Edit Scripts" folder.';
    exit;
  end;
  if not CheckINI(cWorkingDir, cCellEnable) then FileCreate(cWorkingDir+cCellEnable);
  if not CheckINI(cWorkingDir, cTextureIni) then FileCreate(cWorkingDir+cTextureIni);
  
  bDoDebug := StrToBool(LoadIniValues(cWorkingDir, cSettings, 'Debug', 'doDebugGUI', 'True'));
  if bDoDebug then begin
    SaveIniValues(cWorkingDir, cSettings, 'Debug', 'doDebugGUI', 'True');
    SaveIniValues(cWorkingDir, cSettings, 'Debug', 'doDebug', 'True');
  end;
  
  sAssetPath := LoadIniValues(cWorkingDir, cSettings, 'General', 'AssetPath', '');
  
  //Setup Assets
  picGear := TPicture.Create;
  picGear.LoadFromFile(ScriptsPath+cWorkingDir+'Assets\Gear.png');
  picFolder := TPicture.Create;
  picFolder.LoadFromFile(ScriptsPath+cWorkingDir+'Assets\Folder.png');
end;



  
//
//Debugging 
//=============================================================================================================
procedure DebugReadWorlds;
var
  i, j: Integer;
begin
  for i := 0 to Pred(slWorld.Count) do begin
    AddMessage('  '+slWorld[i]);
    for j := 0 to Pred(aCity[i].Count) do begin
      if aCity[i] = '' then continue;
      AddMessage('    '+aCity[i].Strings[j]);
    end;
  end;
end;

//
//Basic Functions
//=============================================================================================================
procedure CreateStringLists;
var
  i: Integer;
begin
  slDebugData := TStringList.Create;
  slOptionsData := TStringList.Create;
  slWorld := TStringList.Create;
  for i := 0 to Pred(Length(aCity)) do begin
    aCity[i] := TStringList.Create;
  end;
end;

procedure FreeMemory;
var
  i: Integer;
begin
  slDebugData.Free;
  slOptionsData.Free;
  slWorld.Free;
  for i := 0 to Pred(Length(aCity)) do begin
    aCity[i].Free;
  end;
  //Assets
  picGear.Free;
  picFolder.Free;
end;

//
//Data Handling
//=============================================================================================================
procedure LoadOptionsData;
var
  sl: TStringList;
begin
  LoadIniParams(cWorkingDir, cSettings, 'Options', slOptionsData);
end;

procedure LoadDebugData;
var
  sl: TStringList;
begin
  LoadIniParams(cWorkingDir, cSettings, 'Debug', slDebugData);
end;

//
//TownData Handling
//=============================================================================================================
procedure SortTownData(sl: TStringList);
var
  iIndex, iWorldIndex: Integer;
  sWorld: String;
  slCurrentWorld: TStringList;
begin
  for iIndex := 0 to Pred(sl.Count) do begin
    sWorld := sl.ValueFromIndex[iIndex];
    iWorldIndex := slWorld.IndexOf(sWorld);
    while iWorldIndex = -1 do begin
      slWorld.Add(sWorld);
      iWorldIndex := slWorld.IndexOf(sWorld);
    end;
    slCurrentWorld := aCity[iWorldIndex];
    if slCurrentWorld.IndexOf(sl.Names[iIndex]) <> -1 then continue;
    slCurrentWorld.Add(sl.Names[iIndex]);
  end;
end;
  
procedure LoadTownData;
const
  cSubDir='CellSettings\';
var
  iFileindex, iSecIndex, iParamIndex: Integer;
  sFileName, sIniName, sSection, sParam: String;
  f: IInterface;
  slCities, slSec, slParam: TStringList;
begin
  slCities := TStringList.Create;
  for iFileindex := 0 to Pred(FileCount) do begin
    f := FileByIndex(iFileindex);
    sFileName := GetFileName(f);
    sIniName := sFileName+'.ini';
    if not CheckINI(cWorkingDir+cSubDir, sIniName) then continue;
    slSec := TStringList.Create;
    LoadIniSections(cWorkingDir+cSubDir, sIniName, slSec);
    for iSecIndex := 0 to Pred(slSec.Count) do begin//File Level
      sSection := slSec[iSecIndex];
      slParam := TStringList.Create;
      LoadIniParamNames(cWorkingDir+cSubDir, sIniName, sSection, slParam);
      for iParamIndex := 0 to Pred(slParam.Count) do begin
        sParam := slParam[iParamIndex];
        slCities.Add(sParam+'='+sSection);
      end;
      slParam.Free;
    end;
    slSec.Free;
  end;
  AddMessage(slCities.Text);
  if slCities.Text = '' then begin
    sScriptFailedReason := 'Unable to process Cell data from "'+ScriptsPath+cWorkingDir+cSubDir+'". Please check the path for files.';
    exit;
  end;  
  SortTownData(slCities);//Prepare Town Data for GUI
  slCities.Free;
end;
 
//
//GUI Functions
//=============================================================================================================
procedure ofrm.AssetDirectory(Sender: TObject);
begin
  sender.Parent.Components[0].Caption := SelectDirectory('Select a directory', '', '', '');
end;

procedure ofrm.TextureDirectory(Sender: TObject);
begin
  sender.Parent.Components[1].Caption := SelectDirectory('Select a directory', DataPath+'textures\'+cWorkingDir, DataPath+'textures\'+cWorkingDir, '');
end;

procedure OptionsMenu;
var
  ofrm: TForm;
  gbWindow, gbAssetsDir, gbTexture: TGroupBox;
  btnCancel, btnOkay: TButton;
  sbTexture: TScrollBox;
  lblPath, lblDir: TLabel;
  imgPath: TImage;
  lblWorldTexture: Array[0..255] of TLabel;
  lblArea: Array[0..255,0..255] of TLabel;
  pnlPath: Array[0..255,0..255] of TPanel;
  imgTextureFolder: Array[0..255,0..255] of TImage;
  i, j: Integer;
begin
  AddMessage('Running Options GUI');
  ofrm := TForm.Create(nil);
  //try
    ofrm.BorderStyle := bsDialog;
    ofrm.Caption := 'Options';
    ofrm.Width := 600;
    ofrm.Position := poScreenCenter;
    ofrm.Height := 650;
      
    //Main Window
    gbWindow := cGroup(ofrm, ofrm, 0, 0, ofrm.height, ofrm.Width+9, '', '');
    //Asset Group Box
    gbAssetsDir := cGroup(ofrm, gbWindow, 15, 15, 50, ofrm.Width-30, 'Asset Directory', '');
    lblDir := cLabel(ofrm, gbAssetsDir, 15, 15, 20, 120, 'Current Asset Directory: ', '');
    lblPath := cLabel(gbAssetsDir, gbAssetsDir, 15, lblDir.Left+lblDir.Width+15, 15, gbAssetsDir.Width-(lblDir.Left+lblDir.Width+30), LoadIniValues(cWorkingDir, cSettings, 'General', 'AssetPath', ''), '');
    imgPath := cImage(gbAssetsDir, gbAssetsDir, 14, gbAssetsDir.Width-35, 25, 25, picFolder, '');
    imgPath.OnClick := AssetDirectory;
    
    gbTexture := cGroup(ofrm, gbWindow, gbAssetsDir.Top+gbAssetsDir.Height+15, gbAssetsDir.Left, gbWindow.Height-(gbWindow.Top+115), gbAssetsDir.Width, 'Texture Locations', '');
    sbTexture := cScrollBox(ofrm, gbTexture, gbTexture.Height-5, alTop);
    for i := 0 to Pred(slWorld.Count) do begin
      if i = 0 then
        lblWorldTexture[i] := cLabel(ofrm, sbTexture, 5, 5, 0, 0, slWorld[i], '')
      else
        lblWorldTexture[i] := cLabel(ofrm, sbTexture, 15+lblWorldTexture[i-1].Top+(20*(aCity[i-1].Count)), 5, 0, 0, slWorld[i], '');
      for j := 0 to Pred(aCity[i].Count) do begin
      //cEdit
      //OnClick check dir
        pnlPath[i,j] := TPanel.Create(ofrm);
          pnlPath[i,j].Parent := sbTexture;
          pnlPath[i,j].Top := (lblWorldTexture[i].Top+15)+(20*j);
          pnlPath[i,j].Left := 0;
          pnlPath[i,j].Height := 20;
          pnlPath[i,j].Width := sbTexture.Width-4;
          //pnlPath[i,j].Caption := IntToStr(i)+','+IntToStr(j);
        lblArea[i,j]:= cLabel(pnlPath[i,j], pnlPath[i,j], 2, 35, 15, 60, aCity[i].Strings[j]+': ', '');
        lblTexture[i,j] := cLabel(pnlPath[i,j], pnlPath[i,j], lblArea[i,j].Top, lblArea[i,j].Left+lblArea[i,j].Width+30, 15, gbTexture.Width-30, LoadIniValues(cWorkingDir, cTextureIni, slWorld[i], aCity[i].Strings[j], ''), '');
        if lblTexture[i,j].Caption = '' then
          lblTexture[i,j].Caption := DataPath+'textures\'+cWorkingDir+aCity[i].Strings[j];
        imgTextureFolder[i, j] := cImage(pnlPath[i,j], pnlPath[i,j], lblArea[i,j].Top, pnlPath[i,j].Width-35, 25, 25, picFolder, '');
        imgTextureFolder[i, j].OnClick := TextureDirectory;
      end;
    end;
    
    //Modal Buttons
    btnCancel := cButton(ofrm, gbWindow, gbWindow.Height-50, gbWindow.Width-120, 25, 75, 'Cancel');
    btnCancel.ModalResult := mrCancel;
    btnOkay := cButton(ofrm, gbWindow, btnCancel.Top, btnCancel.Left-85, 25, 75, 'Okay');
    btnOkay.ModalResult := mrOk;
    
    ofrm.ShowModal;
    
    if ofrm.ModalResult = mrOk then begin
      EraseIniSections(cWorkingDir, cTextureIni);
      //Save
      for i := 0 to Pred(slWorld.Count) do begin
        for j := 0 to Pred(aCity[i].Count) do begin
          if lblTexture[i,j].Caption = '' then 
            lblTexture[i,j].Caption := DataPath+'textures\'+cWorkingDir+aCity[i].Strings[j];
          if DirectoryExists(lblTexture[i,j].Caption) then begin
            SaveIniValues(cWorkingDir, cTextureIni, slWorld[i], aCity[i].Strings[j], lblTexture[i,j].Caption);
            cbAreas[i,j].Enabled := True;
          end;
          if cbAreas[i,j].Enabled then 
            lblDisabledAreas[i,j].Caption := GetStrEndsWith(lblTexture[i,j].Caption,'\')
          else
            lblDisabledAreas[i,j].Caption := cMissingDir;
        end;
      end;
    end;
    
  //finally
    ofrm.Free;
  //end;
end;

procedure frm.CheckAll;
var
  i, j: Integer;
begin
  for i := 0 to Pred(slWorld.Count) do
    for j := 0 to Pred(aCity[i].Count) do
      cbAreas[i,j].Checked := cbAreas[i,j].Enabled;
end;

procedure frm.UncheckAll;
var
  i, j: Integer;
begin
  for i := 0 to Pred(slWorld.Count) do
    for j := 0 to Pred(aCity[i].Count) do
      cbAreas[i,j].Checked := False;
end;

procedure CreateGUI;
const
  cSubDir='';
var
  i, j: Integer;
  frm: TForm;
  sbAreas: TScrollBox;
  imgOptions: TImage;
  gbWindow,gbAreas,gbDebug,gbOptions: TGroupBox;
  btnRun, btnCancel, btnCheckAll, btnUncheckAll: TButton;
  lblDebug, lblTitle, lblPluginFile, lblWorkingDir, lblVerINI, lblVerScript, lblAssetPath, lblAssetPathDir: TLabel;
  cbDoInteriors: TCheckBox;
  bDirectoryNotSet: Boolean;
begin
  AddMessage('Running GUI');
  frm := TForm.Create(nil);
    //try
    frm.BorderStyle := bsDialog;
    frm.Caption := 'Unique Town Textures';
    frm.Width := 650;
    frm.Position := poScreenCenter;
    frm.Height := 700;
      
    //Main Window
    gbWindow := cGroup(frm, frm, 0, 0, frm.height, frm.Width+9, '', '');
    
    //Title
    lblTitle := cLabel(frm, gbWindow, 5, (frm.Width-380)/2, 50, 380, 'Unique Town Textures', '');
    lblTitle.Font.Size := 28;
    
    //Other Labels
    lblPluginFile := cLabel(frm, gbWindow, lblTitle.Top+lblTitle.Height+15, 15, 15, gbWindow.Width/2, 'Current Plugin File: '+LoadIniValues(cWorkingDir, cSettings, 'General', 'PluginName', ''), '');
    lblWorkingDir := cLabel(frm, gbWindow, gbWindow.Height-40, 15, 15, gbWindow.Width/2, 'Current Working Directiory: "'+cWorkingDir+'"', '');
    lblVerINI := cLabel(frm, gbWindow, lblWorkingDir.Top-20, 15, 15, gbWindow.Width/2, 'INI File Version: '+LoadIniValues(cWorkingDir, cSettings, 'General', 'IniVer', ''), '');
    lblVerScript := cLabel(frm, gbWindow, lblVerINI.Top-20, 15, 15, gbWindow.Width/2, 'Script Version: '+LoadIniValues(cWorkingDir, cSettings, 'General', 'ScriptVer', ''), '');
    lblAssetPath := cLabel(frm, gbWindow, lblVerScript.Top-20, 15, 15, 200, 'Current Assset Directory: '+sAssetPath, '');
    if (sAssetPath <> '') AND (not DirectoryExists(sAssetPath)) then lblAssetPath.Caption := 'Current Asset Directory is Invalid!';
    
    //list of locations to affect
    gbAreas := cGroup(frm, gbWindow, lblTitle.Top+lblTitle.Height+35, (gbWindow.Width/2)+15, 450, (gbWindow.Width/2)-25, 'Locations to Affect', '');
    sbAreas := cScrollBox(frm, gbAreas, gbAreas.Height-20, alTop);
    for i := 0 to Pred(slWorld.Count) do begin
      if i = 0 then
        lblWorld[i] := cLabel(frm, sbAreas, 5, 5, 0, 0, slWorld[i], '')
      else
        lblWorld[i] := cLabel(frm, sbAreas, 15+lblWorld[i-1].Top+(20*(aCity[i-1].Count)), 5, 0, 0, slWorld[i], '');
      for j := 0 to Pred(aCity[i].Count) do begin
        cbAreas[i,j] := cCheckBox(frm, sbAreas, (lblWorld[i].Top+15)+(20*j), 25, 65, aCity[i].Strings[j], StrToBool(LoadIniValues(cWorkingDir+cSubDir, cCellEnable, slWorld[i], aCity[i].Strings[j], 'False')), '');
        cbAreas[i,j].Enabled := DirectoryExists(LoadIniValues(cWorkingDir, cTextureIni, slWorld[i], aCity[i].Strings[j], DataPath+'textures\'+cWorkingDir+aCity[i].Strings[j]+'\'));
        lblDisabledAreas[i,j] := cLabel(frm, sbAreas, cbAreas[i,j].Top, cbAreas[i,j].Left+cbAreas[i,j].Width+15, 0, 140, cMissingDir, '');
        
        if cbAreas[i,j].Enabled then 
          lblDisabledAreas[i,j].Caption := GetStrEndsWith(LoadIniValues(cWorkingDir, cTextureIni, slWorld[i], aCity[i].Strings[j], DataPath+'textures\'+cWorkingDir+aCity[i].Strings[j]+'\'),'\')
        else
          lblDisabledAreas[i,j].Caption := cMissingDir;
      end;
    end;
    
    //Options Nonsense
    gbOptions := cGroup(frm, gbWindow, gbAreas.Top, 15, (20*(slOptionsData.Count))+45, gbAreas.Width, 'Options', '');
    for i := 0 to Pred(slOptionsData.Count) do
      cbOptions[i] := cCheckBox(frm, gbOptions, (i*20)+20, 20, 150, slOptionsData.Names[i], StrToBool(slOptionsData.ValueFromIndex[i]), '');
    
    //Debugging Nonsense
    gbDebug := cGroup(frm, gbWindow, gbOptions.Top+gbOptions.Height+35, gbOptions.Left, (20*(slDebugData.Count))+60, gbAreas.Width, 'Debugging Options', '');
    lblDebug := cLabel(frm, gbDebug, 20, 5, 15, gbDebug.Width-30, 'Some options run before the GUI runs.', '');
    for i := 0 to Pred(slDebugData.Count) do
      cbDebug[i] := cCheckBox(frm, gbDebug, (i*20)+5+lblDebug.Height+lblDebug.Top, 20, 150, slDebugData.Names[i], StrToBool(slDebugData.ValueFromIndex[i]), '');
    
    //Modal Buttons
    btnCancel := cButton(frm, gbWindow, gbWindow.Height-50, gbWindow.Width-120, 25, 75, 'Cancel');
    btnCancel.ModalResult := mrCancel;
    btnRun := cButton(frm, gbWindow, btnCancel.Top, btnCancel.Left-85, 25, 75, 'Run');
    btnRun.ModalResult := mrOk;
    
    btnCheckAll := cButton(frm, gbWindow, gbAreas.Top+gbAreas.Height+5, (gbAreas.Left)+40, 25, 75, 'Check All');
    btnCheckAll.OnClick := CheckAll;
    btnUncheckAll := cButton(frm, gbWindow, btnCheckAll.Top, btnCheckAll.Left+btnCheckAll.Width+50, 25, 75, 'Uncheck All');
    btnUncheckAll.OnClick := UncheckAll;
    
    //Interactive Pictures
    imgOptions := cImage(frm, gbWindow, gbWindow.Height-50, gbWindow.Height-75, 50, 50, picGear, '');
    imgOptions.OnClick := OptionsMenu;
    
    //if (sAssetPath <> '') AND (not DirectoryExists(sAssetPath)) then OptionMenu;
    
    
    frm.ShowModal;
    
    for i := 0 to Pred(slWorld.Count) do begin
      for j := 0 to Pred(aCity[i].Count) do begin
        if (cbAreas[i,j].Checked) AND (not DirectoryExists(DataPath+'textures\'+cWorkingDir+aCity[i].Strings[j]+'\')) then bDirectoryNotSet := true;
      end;
    end;
    
    
    if (frm.ModalResult = mrOk) AND (not bDirectoryNotSet) then begin
      //Delete Previous Data
      EraseIniSections(cWorkingDir+cSubDir, cCellEnable);
      //Save World Data
      for i := 0 to Pred(slWorld.Count) do
        for j := 0 to Pred(aCity[i].Count) do
          SaveIniValues(cWorkingDir+cSubDir, cCellEnable, slWorld[i], aCity[i].Strings[j], BoolToStr(cbAreas[i,j].Checked AND cbAreas[i,j].Enabled));
      //Save Debugging Data
      for i := 0 to Pred(slDebugData.Count) do
        SaveIniValues(cWorkingDir, cSettings, 'Debug', slDebugData.Names[i], BoolToStr(cbDebug[i].Checked AND cbDebug[0].Checked));
      //Save Options Data
      for i := 0 to Pred(slOptionsData.Count) do
        SaveIniValues(cWorkingDir, cSettings, 'Options', slOptionsData.Names[i], BoolToStr(cbOptions[i].Checked));
    end;
  //finally
    frm.Free;
  //end;
end;
  
function Initialize: integer;
begin
  InitalSetup;//Basic checks and file creation
  if sScriptFailedReason <> '' then exit;
  CreateStringLists;//Initialize Stringlists and stringlist arrays
  LoadOptionsData;
  LoadDebugData;//load ini into a Name/Value pair
  LoadTownData;//Sort the stringlist into an array so that it is useable
  if sScriptFailedReason <> '' then exit;
  if bDoDebug then DebugReadWorlds;
  CreateGUI;//Spawn actual GUI
  
end;

function Finalize: integer;
begin
  FreeMemory;//Free all stringlists
  if sScriptFailedReason <> '' then begin
    AddMessage(sScriptFailedReason);
  end;
end;

end.
