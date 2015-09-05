{
  *Scan for Interior cells.
    +cycle through records if DoInteriors is enabled.
  *Scan All Cells for valid meshes -> cache
  
  * Check for valid 'meshes\UTT\<town>' and copy loose meshes
    * If loose mesh doesnt exist, get it from bsa
  + Search through ALL the towns for valid "town" meshes
    * cache the valid mesh directories
  + Scan through the meshes and log the textures
    * cache the required valid textures
		
    
Future plans
  *INI File Check separate procedure
  *Detect if town texture folders actually contain at least one *.dds file.
  *GUI
    +Add Hint
  *Make reading vars a procedure
  *Make reading ini a procedure
  *Make writing to ini a procedure
  *Add small towns
    +Add ini file entries
    +Add GUI entries
  *Remove Ignored Meshes in slValidCells
  
  
  *AddIgnored Objects FormIDs
  *AddForced Object FormIDs
  
  
  
  DoInteriors 
    if not RegenVanillaInteriors
      -skip bethsoft file
      +load values from ini
    +ProcessInteriors WRLD
      //-Ignore 00000D74
      //second level of interior cells?
    
  CacheCells
    if not DoVanilla
      -skip bethsoft file
    Store ValidCells as NameValue Pair
    
Affected Cells is what is going to be used to cache meshes list
   
}
unit UTTMain;
uses mteFunctions;
uses __HishyFunctions;
uses 'UTT\lib\UTTFunctions';
uses 'UTT\lib\FileHandling';
uses 'UTT\lib\GUI';
uses 'UTT\lib\Prepare';

const
  cVer='0.1';
  cWorkingPath=ScriptsPath+'UTT\';
  cTexturesPath=DataPath+'textures\UTT\';
  cPatchFile='UniqueTownTextures.esp';
  cUpdateNumber=10000;//store in ini
  cRecuriveDepth=6;
  
  cDashes='------------------------------------------------------------------------------------------';
  cBethesdaFiles='Skyrim.esm,Update.esm,Dawnguard.esm,HearthFires.esm,Dragonborn.esm';
  
  cEnabledLocationsFile=cWorkingPath+'Settings\EnabledLocations.ini';
  cLangFile=cWorkingPath+'Assets\english.lang';
  cGeneralSettings=cWorkingPath+'Settings\General.ini';
  cTextureCacheFile=cWorkingPath+'Cache\TextureCache.ini';
  cCacheCheckSumFile=cWorkingPath+'Cache\FileCheckSums.txt';
  cCacheFormIDsFile=cWorkingPath+'Cache\FormIDs.ini';
  cTexturePathsFile=cWorkingPath+'Settings\TexturePaths.ini';
  cCellRulesPath=cWorkingPath+'Rules\';
  
  cOptionsNames='doInteriors,doParallax';
  cDebugNames='doDebug,doDebugGeneral,doDebugGUI,doDebugPrepare,doDebugFindInteriors';
  cRequiredAssets='Gear.png,Folder.png,Undo.png,Error.png,Check.png,Reset.png';
  
var
  bDoDebug: Boolean;
  iniSettings: TMemIniFile;
  lang: TStringList;
  iRun: int;
  
procedure InitialStartup;
var
  recRules: TSearchRec;
  slAssets: TStringList;
begin
  if wbAppName <> 'TES5' then 
    raise Exception.Create('This is a Skyrim only script. I have no intention in bringing this to any other game.');
    
  if not FileExists(cLangFile) then //Check for language file
    raise Exception.Create('You are missing the "'+cLangFile+'" file, please reinstall the "Edit Scripts" folder.')
  else //load language strings
  begin
    lang := TStringList.Create;
    lang.LoadFromFile(cLangFile);
  end;
  
  if FindFirst(cCellRulesPath+'*.ini',faAnyFile,recRules) = 2 then//Search for ANY rules
    raise Exception.Create(lang.Values['sMissingFile']);
  FindClose(recRules);
  
  CreateFileIfMissing(cGeneralSettings);
  CreateFileIfMissing(cCacheCheckSumFile);
  CreateFileIfMissing(cCacheFormIDsFile);
  
  slAssets := TStringList.Create;
  for i := 0 to Pred(slAssets.Count) do
  begin
    if FileExists(cWorkingPath+'Assets\'+slAssets[i]) then continue;
    raise Exception.Create(lang.Values['sMissingFile']);
  end;
  slAssets.Free;
  
  iniSettings := TMemIniFile.Create(cGeneralSettings);
  iniSettings.WriteString('General', 'PluginName', cPatchFile);
  
  //Update Ini
  UpdateSettingsBool(iniSettings,'Options', cOptionsNames);
  UpdateSettingsBool(iniSettings,'Debug', cDebugNames);
  
end;



procedure Introduction;
begin
  AddMessage(cDashes);
  AddMessage('');
  AddMessage(Inden(5)+lang.Values['sWelcome']);
  AddMessage(Inden(5)+lang.Values['sScriptVer']+cVer);
  AddMessage(Inden(5)+lang.Values['sIniVer']+iniSettings.ReadString('General','IniVer', 'Invalid'));
  AddMessage('');
  AddMessage(cDashes);
end;

  
function Initialize: integer;
begin
  InitialStartup;
  Introduction;
  StartGUI;
  if iRun = 0 then 
    raise Exception.Create(lang.Values['sSelectAtLeasetOneLocation'])
  else if iRun = -1 then 
    exit;
    
  GatherRecords;
  {
  FindRecords;
  if sScriptFailedReason <> '' then exit;
  //FindMeshes;
  //Scan through cells for Valid Meshes
  //Scan Meshes for Valid Textures
  
  
  }
end;

function Finalize: integer;
begin
  FreeMemory;
end;

procedure FreeMemory;
begin
  lang.Free;
  iniSettings.UpdateFile;
  iniSettings.Free;
end; 

end.