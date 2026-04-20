import System.Xdg
import System.IO.GetEnvironment

/-!
# XDG User Directories

This module implements XDG user directory lookups as defined by the
freedesktop.org specification. It reads per-user configuration from
`$XDG_CONFIG_HOME/user-dirs.dirs` and falls back to the system-wide
defaults in `/etc/xdg/user-dirs.defaults`.

## References
- [XDG User Directories](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/)
-/

/-! ## Internal parsing helpers (exposed for testing) -/

namespace System.Xdg.UserDir.Internal

/-- Element of a shell-format string -/
inductive Element where
  | fixed (c : Char)
  | var   (name : String)
  deriving BEq, Repr

private def isVarBreak (c : Char) : Bool :=
  "!#/;:,.*?%-=$<> \r\n\t".contains c

private partial def parseStringAux : List Char → List Element
  | [] => []
  | '$' :: rest =>
    let (nameChars, tail) := rest.span (!isVarBreak ·)
    if nameChars.isEmpty then
      Element.fixed '$' :: parseStringAux rest
    else
      Element.var (String.ofList nameChars) :: parseStringAux tail
  | c :: rest => Element.fixed c :: parseStringAux rest

/-- Parse a shell-format string into a list of fixed characters and variable references.
    Variable names are terminated by any of `!#/;:,.*?%-=$<>` or whitespace. -/
def parseString (s : String) : List Element :=
  parseStringAux s.toList

/-- Expand `$VAR` references in a string using a pre-loaded environment array.
    Unknown variables expand to the empty string. -/
def expandVars (envs : Array (String × String)) (s : String) : String :=
  let elems := parseString s
  elems.foldl (fun acc e =>
    match e with
    | Element.fixed c  => acc.push c
    | Element.var name => acc ++ (envs.find? (·.1 == name) |>.map (·.2) |>.getD ""))
  ""

/-- Return `true` for lines that are neither empty nor comments (starting with `#`). -/
def notComment (line : String) : Bool :=
  !line.isEmpty && !line.startsWith "#"

/-- Strip a matching pair of surrounding single or double quotes. -/
def stripQuotes (s : String) : String :=
  let cs := s.toList
  match cs with
  | '"'  :: rest => if rest.getLast? == some '"'  then String.ofList rest.dropLast else s
  | '\'' :: rest => if rest.getLast? == some '\'' then String.ofList rest.dropLast else s
  | _            => s

/-- Parse a `NAME=VALUE` line, splitting at the first `=`.
    Returns `none` if no `=` is present. -/
def parsePair (line : String) : Option (String × String) :=
  let (namePart, rest) := line.toList.span (· != '=')
  match rest with
  | '=' :: valuePart => some (String.ofList namePart, stripQuotes (String.ofList valuePart))
  | _                => none

/-- Read `NAME=VALUE` pairs from a file, skipping blank lines and comments.
    Returns an empty list if the file does not exist or cannot be read. -/
def readPairs (path : System.FilePath) : IO (List (String × String)) := do
  let content ← try IO.FS.readFile path catch _ => return []
  return content.splitOn "\n" |>.filter notComment |>.filterMap parsePair

/-- Try to interpret a `NAME=VALUE` pair as an XDG user directory entry.
    Entries of the form `XDG_FOO_DIR=value` yield `("FOO", value)`;
    all other entries yield `none`. -/
def pairToXdgPair (pair : String × String) : Option (String × String) :=
  let (name, value) := pair
  match name.splitOn "_" with
  | ["XDG", var, "DIR"] => some (var, value)
  | _                   => none

/-- Look up a named XDG user directory from pre-loaded `userDirs` and `defaults`
    lists, expanding `$VAR` references using the provided environment array.
    User entries take precedence over defaults.
    Returns `none` if the key is absent from both lists. -/
def getUserDirWithEnvs
    (userDirs defaults : List (String × String))
    (envs : Array (String × String))
    (name : String) : Option System.FilePath :=
  match (userDirs ++ defaults).lookup name with
  | none      => none
  | some path => some ⟨expandVars envs path⟩

end System.Xdg.UserDir.Internal

/-! ## Public API -/

namespace System.Xdg.UserDir

open Internal

/-- Read the system-wide default user directories from `/etc/xdg/user-dirs.defaults`.
    Entries in this file are plain `KEY=value` pairs (e.g. `DESKTOP=Desktop`).
    Returns an empty list if the file is absent (e.g. on non-Linux platforms). -/
def readDefaults : IO (List (String × String)) :=
  readPairs ⟨"/etc/xdg/user-dirs.defaults"⟩

/-- Read the user-configured XDG user directories from `user-dirs.dirs` inside
    the XDG config home directory. Values are returned as-is; call `getUserDir`
    to get paths with `$VAR` references expanded. -/
def readUserDirs : IO (List (String × String)) := do
  let configHome ← getConfigHome
  let pairs ← readPairs (configHome / "user-dirs.dirs")
  return pairs.filterMap pairToXdgPair

/-- Return the path for a named XDG user directory (e.g. `"DOWNLOAD"`, `"DESKTOP"`).
    Looks up `name` in the merged list of user-configured directories
    (`$XDG_CONFIG_HOME/user-dirs.dirs`) and system defaults
    (`/etc/xdg/user-dirs.defaults`). User entries take precedence.
    `$VAR` references in the value are expanded using the current process environment.
    Returns `none` if the key is absent from both sources. -/
def getUserDir (name : String) : IO (Option System.FilePath) := do
  let defaults ← readDefaults
  let userDirs ← readUserDirs
  let envs ← getEnvironment
  return getUserDirWithEnvs userDirs defaults envs name


end System.Xdg.UserDir
