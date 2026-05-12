/-!
# XDG Base Directory Specification

This module implements the XDG Base Directory Specification for Lean.
It provides functions to get XDG directories for data, config, cache, state, and runtime files.

## References
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)

## API Design
The public API (`XdgDirectory`, `XdgDirectoryList`, `getXdgDirectory`, `getXdgDirectoryList`,
`getHomeDirectory`, `getTemporaryDirectory`) mirrors the interface of the Haskell
[`directory`](https://hackage.haskell.org/package/directory) library.
See [`System.Directory`](https://hackage.haskell.org/package/directory/docs/System-Directory.html).

`XdgDirectory.Runtime` (`XDG_RUNTIME_DIR`) is an extension not present in the Haskell library;
it is included here because the XDG Base Directory Specification defines it.
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

private def requireEnv (name : String) : IO String := do
  match (← IO.getEnv name) with
  | some value => pure value
  | none => throw (IO.userError s!"Missing environment variable: {name}")

def parseXdgDirs (envValue : String) : List System.FilePath :=
  envValue.splitOn ":"
    |> List.filter (! ·.isEmpty)
    |> List.map (⟨·⟩)

/-- Get the current user's home directory -/
def getHomeDirectory : IO System.FilePath :=
  return ⟨← requireEnv "HOME"⟩

/-- Get XDG data home directory -/
private def getDataHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_DATA_HOME") with
  | some path => pure ⟨path⟩
  | none => return (← getHomeDirectory) / ".local" / "share"

/-- Get XDG config home directory -/
private def getConfigHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_CONFIG_HOME") with
  | some path => pure ⟨path⟩
  | none => return (← getHomeDirectory) / ".config"

/-- Get XDG state home directory -/
private def getStateHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_STATE_HOME") with
  | some path => pure ⟨path⟩
  | none => return (← getHomeDirectory) / ".local" / "state"

/-- Get XDG cache home directory -/
private def getCacheHome : IO System.FilePath := do
  match (← IO.getEnv "XDG_CACHE_HOME") with
  | some path => pure ⟨path⟩
  | none => return (← getHomeDirectory) / ".cache"

/-- Get XDG runtime directory -/
private def getRuntimeDir : IO System.FilePath :=
  return ⟨← requireEnv "XDG_RUNTIME_DIR"⟩

/-- XDG single-directory types for user-specific base directories -/
inductive XdgDirectory where
  /-- Data files (`XDG_DATA_HOME`, default `~/.local/share`) -/
  | Data
  /-- Configuration files (`XDG_CONFIG_HOME`, default `~/.config`) -/
  | Config
  /-- Non-essential cached data (`XDG_CACHE_HOME`, default `~/.cache`) -/
  | Cache
  /-- Persistent state data (`XDG_STATE_HOME`, default `~/.local/state`) -/
  | State
  /-- Runtime files (`XDG_RUNTIME_DIR`, no default) -/
  | Runtime
  deriving Repr, BEq, Inhabited

/-- XDG directory-list types for system-wide base directory search paths -/
inductive XdgDirectoryList where
  /-- System-wide data directories (`XDG_DATA_DIRS`, defaults `/usr/local/share:/usr/share`) -/
  | DataDirs
  /-- System-wide config directories (`XDG_CONFIG_DIRS`, default `/etc/xdg`) -/
  | ConfigDirs
  deriving Repr, BEq, Inhabited

/-- Get the XDG base directory for the given type, with `subPath` appended -/
def getXdgDirectory (xdgDir : XdgDirectory) (subPath : System.FilePath) : IO System.FilePath := do
  let base ← match xdgDir with
    | .Data   => getDataHome
    | .Config => getConfigHome
    | .Cache  => getCacheHome
    | .State  => getStateHome
    | .Runtime => getRuntimeDir
  pure (
    match subPath with
      | "" => base
      | _ => base / subPath
  )

/-- Get the system-wide XDG directory search path for the given type -/
def getXdgDirectoryList (xdgDirList : XdgDirectoryList) : IO (List System.FilePath) := do
  match xdgDirList with
  | .DataDirs =>
    match (← IO.getEnv "XDG_DATA_DIRS") with
    | some dirs => pure (parseXdgDirs dirs)
    | none => pure [⟨"/usr/local/share"⟩, ⟨"/usr/share"⟩]
  | .ConfigDirs =>
    match (← IO.getEnv "XDG_CONFIG_DIRS") with
    | some dirs => pure (parseXdgDirs dirs)
    | none => pure [⟨"/etc/xdg"⟩]

/-- Get the temporary directory (`$TMPDIR` or `/tmp`) -/
def getTemporaryDirectory : IO System.FilePath := do
  match (← IO.getEnv "TMPDIR") with
  | some dir => pure ⟨dir⟩
  | none => pure ⟨"/tmp"⟩

end System.Xdg
