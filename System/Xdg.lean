/-!
# XDG Base Directory Specification

This module implements the XDG Base Directory Specification for Lean.
It provides functions to get XDG directories for data, config, cache, state, and runtime files.

## References
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
-/

namespace System.Xdg

/-- XDG-related errors -/
inductive XdgError where
  | missingEnv (name : String)
  | invalidPath (path : String)
  | noReadableFile
  deriving Repr, Inhabited

instance : ToString XdgError where
  toString := fun
    | XdgError.missingEnv name => s!"Missing environment variable: {name}"
    | XdgError.invalidPath path => s!"Invalid path: {path}"
    | XdgError.noReadableFile => "No readable file found"

/-- Get environment variable, throwing XdgError.missingEnv if not found -/
def requireEnv (name : String) : IO String := do
  match (← IO.getEnv name) with
  | some value => pure value
  | none => throw (IO.userError s!"Missing environment variable: {name}")

/-- Get XDG data home directory -/
def getDataHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_DATA_HOME") with
  | some path => pure ⟨path⟩
  | none => do
    let home ← requireEnv "HOME"
    pure ⟨home ++ "/.local/share"⟩

/-- Get XDG config home directory -/
def getConfigHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_CONFIG_HOME") with
  | some path => pure ⟨path⟩
  | none => do
    let home ← requireEnv "HOME"
    pure ⟨home ++ "/.config"⟩

/-- Get XDG state home directory -/
def getStateHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_STATE_HOME") with
  | some path => pure ⟨path⟩
  | none => do
    let home ← requireEnv "HOME"
    pure ⟨home ++ "/.local/state"⟩

/-- Get XDG cache home directory -/
def getCacheHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_CACHE_HOME") with
  | some path => pure ⟨path⟩
  | none => do
    let home ← requireEnv "HOME"
    pure ⟨home ++ "/.cache"⟩

/-- Get XDG runtime directory -/
def getRuntimeDir : IO System.FilePath := do
  let dir ← requireEnv "XDG_RUNTIME_DIR"
  pure ⟨dir⟩

/-- Split string by separator -/
def splitBy (sep : Char) (s : String) : List String :=
  s.split (· == sep) |>.filter (· ≠ "")

/-- Parse XDG directories from colon-separated environment variable -/
def parseXdgDirs (envValue : String) : List System.FilePath :=
  (splitBy ':' envValue).map (⟨·⟩)

/-- Get XDG data directories -/
def getDataDirs : IO (List System.FilePath) := do
  let userDataHome ← try
    some <$> getDataHome
  catch _ =>
    pure none

  let envDirs := match (← IO.getEnv "XDG_DATA_DIRS") with
    | some dirs => parseXdgDirs dirs
    | none => [⟨"/usr/local/share"⟩, ⟨"/usr/share"⟩]

  pure $ (userDataHome.map (· :: envDirs)).getD envDirs

/-- Get XDG config directories -/
def getConfigDirs : IO (List System.FilePath) := do
  let userConfigHome ← try
    some <$> getConfigHome
  catch _ =>
    pure none

  let envDirs := match (← IO.getEnv "XDG_CONFIG_DIRS") with
    | some dirs => parseXdgDirs dirs
    | none => [⟨"/etc/xdg"⟩]

  pure $ (userConfigHome.map (· :: envDirs)).getD envDirs

/-- Read file from first available directory -/
def readFileFromDirs (dirs : List System.FilePath) (subPath : System.FilePath) : IO String := do
  let rec tryDirs : List System.FilePath → IO String
    | [] => throw (IO.userError "No readable file found")
    | dir :: rest => do
      let filePath := dir / subPath
      try
        IO.FS.readFile filePath
      catch _ =>
        tryDirs rest
  tryDirs dirs

/-- Read file from single directory -/
def readFileFromDir (getDir : IO System.FilePath) (subPath : System.FilePath) : IO String := do
  let dir ← getDir
  let filePath := dir / subPath
  IO.FS.readFile filePath

/-- Read data file from XDG data directories -/
def readDataFile (subPath : System.FilePath) : IO String := do
  let dirs ← getDataDirs
  readFileFromDirs dirs subPath

/-- Read config file from XDG config directories -/
def readConfigFile (subPath : System.FilePath) : IO String := do
  let dirs ← getConfigDirs
  readFileFromDirs dirs subPath

/-- Read state file from XDG state home -/
def readStateFile (subPath : System.FilePath) : IO String :=
  readFileFromDir getStateHome subPath

/-- Read cache file from XDG cache home -/
def readCacheFile (subPath : System.FilePath) : IO String :=
  readFileFromDir getCacheHome subPath

/-- Read runtime file from XDG runtime directory -/
def readRuntimeFile (subPath : System.FilePath) : IO String :=
  readFileFromDir getRuntimeDir subPath

/-- Ensure directory exists -/
def ensureDir (dir : System.FilePath) : IO Unit := do
  IO.FS.createDirAll dir

/-- Write file to directory -/
def writeFileToDir (getDir : IO System.FilePath) (subPath : System.FilePath) (content : String) : IO Unit := do
  let dir ← getDir
  ensureDir dir
  let filePath := dir / subPath
  -- Create parent directory if it doesn't exist
  match filePath.parent with
  | some parent => ensureDir parent
  | none => pure ()
  IO.FS.writeFile filePath content

/-- Write config file to XDG config home -/
def writeConfigFile (subPath : System.FilePath) (content : String) : IO Unit :=
  writeFileToDir getConfigHome subPath content

/-- Write data file to XDG data home -/
def writeDataFile (subPath : System.FilePath) (content : String) : IO Unit :=
  writeFileToDir getDataHome subPath content

/-- Write cache file to XDG cache home -/
def writeCacheFile (subPath : System.FilePath) (content : String) : IO Unit :=
  writeFileToDir getCacheHome subPath content

/-- Write state file to XDG state home -/
def writeStateFile (subPath : System.FilePath) (content : String) : IO Unit :=
  writeFileToDir getStateHome subPath content

/-- Write runtime file to XDG runtime directory -/
def writeRuntimeFile (subPath : System.FilePath) (content : String) : IO Unit :=
  writeFileToDir getRuntimeDir subPath content

/-- Try to read file, returning None if it fails -/
def maybeReadFile (action : IO String) : IO (Option String) := do
  try
    some <$> action
  catch _ =>
    pure none

/-- Maybe read data file -/
def maybeReadDataFile (subPath : System.FilePath) : IO (Option String) :=
  maybeReadFile (readDataFile subPath)

/-- Maybe read config file -/
def maybeReadConfigFile (subPath : System.FilePath) : IO (Option String) :=
  maybeReadFile (readConfigFile subPath)

/-- Maybe read state file -/
def maybeReadStateFile (subPath : System.FilePath) : IO (Option String) :=
  maybeReadFile (readStateFile subPath)

/-- Maybe read cache file -/
def maybeReadCacheFile (subPath : System.FilePath) : IO (Option String) :=
  maybeReadFile (readCacheFile subPath)

/-- Maybe read runtime file -/
def maybeReadRuntimeFile (subPath : System.FilePath) : IO (Option String) :=
  maybeReadFile (readRuntimeFile subPath)

-- Export a hello function for the main file to use temporarily
def hello : String := "XDG"

end System.Xdg
