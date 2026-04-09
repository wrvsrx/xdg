import System.Xdg
import System.Xdg.UserDir

open System.Xdg.UserDir.Internal

-- ---------------------------------------------------------------------------
-- Minimal test harness
-- ---------------------------------------------------------------------------

private def ok (label : String) : IO Unit :=
  IO.println s!"  ✓ {label}"

private def fail (label : String) (detail : String) (failures : IO.Ref Nat) : IO Unit := do
  IO.eprintln s!"  ✗ {label}"
  IO.eprintln s!"    {detail}"
  failures.modify (· + 1)

private def check [BEq α] [ToString α]
    (label : String) (actual expected : α) (failures : IO.Ref Nat) : IO Unit := do
  if actual == expected then
    ok label
  else
    fail label s!"expected: {expected}\n    actual:   {actual}" failures

private def checkTrue (label : String) (b : Bool) (failures : IO.Ref Nat) : IO Unit :=
  check label b true failures

private def checkFalse (label : String) (b : Bool) (failures : IO.Ref Nat) : IO Unit :=
  check label b false failures

-- ---------------------------------------------------------------------------
-- System.Xdg tests
-- ---------------------------------------------------------------------------

private def testSplitBy (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.splitBy"
  check "basic split"         (System.Xdg.splitBy ':' "a:b:c") ["a", "b", "c"] f
  check "empty string"        (System.Xdg.splitBy ':' "")       []              f
  check "no separator"        (System.Xdg.splitBy ':' "abc")    ["abc"]         f
  check "empty segments drop" (System.Xdg.splitBy ':' "a::b")   ["a", "b"]      f
  check "leading sep drop"    (System.Xdg.splitBy ':' ":a")     ["a"]           f
  check "trailing sep drop"   (System.Xdg.splitBy ':' "a:")     ["a"]           f
  check "only seps"           (System.Xdg.splitBy ':' ":::")    []              f

private def testParseXdgDirs (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.parseXdgDirs"
  check "two paths"
    (System.Xdg.parseXdgDirs "/usr/share:/usr/local/share")
    [⟨"/usr/share"⟩, ⟨"/usr/local/share"⟩] f
  check "single path"
    (System.Xdg.parseXdgDirs "/etc/xdg")
    [⟨"/etc/xdg"⟩] f
  check "empty string"
    (System.Xdg.parseXdgDirs "")
    [] f

-- ---------------------------------------------------------------------------
-- System.Xdg.UserDir.Internal – pure function tests
-- ---------------------------------------------------------------------------

private def testNotComment (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.notComment"
  checkFalse "empty string"         (notComment "")                f
  checkFalse "hash at start"        (notComment "# comment")       f
  checkFalse "hash alone"           (notComment "#")               f
  checkTrue  "valid pair"           (notComment "KEY=value")       f
  checkTrue  "leading space"        (notComment "  KEY=value")     f
  checkTrue  "XDG_DESKTOP_DIR line" (notComment "XDG_DESKTOP_DIR=\"$HOME/Desktop\"") f

private def testStripQuotes (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.stripQuotes"
  check "double-quoted"      (stripQuotes "\"hello\"")   "hello"        f
  check "single-quoted"      (stripQuotes "'hello'")     "hello"        f
  check "unquoted"           (stripQuotes "hello")       "hello"        f
  check "empty string"       (stripQuotes "")            ""             f
  check "mismatched quotes"  (stripQuotes "\"hello'")    "\"hello'"     f
  check "double alone"       (stripQuotes "\"")          "\""           f
  check "single alone"       (stripQuotes "'")           "'"            f
  check "inner equals kept"  (stripQuotes "\"a=b\"")     "a=b"          f
  check "nested quotes kept" (stripQuotes "\"'inner'\"") "'inner'"      f

private def testParsePair (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.parsePair"
  check "simple pair"          (parsePair "KEY=value")           (some ("KEY", "value"))       f
  check "quoted value"         (parsePair "KEY=\"value\"")        (some ("KEY", "value"))       f
  check "value contains ="     (parsePair "KEY=a=b")             (some ("KEY", "a=b"))         f
  check "empty value"          (parsePair "KEY=")                (some ("KEY", ""))            f
  check "no equals"            (parsePair "noequals")            none                          f
  check "empty line"           (parsePair "")                    none                          f
  check "XDG dir entry"
    (parsePair "XDG_DESKTOP_DIR=\"$HOME/Desktop\"")
    (some ("XDG_DESKTOP_DIR", "$HOME/Desktop")) f

private def testExpandVars (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.expandVars"
  let env : List (String × String) := [("HOME", "/home/user"), ("XDG", "/xdg")]
  check "single var"         (expandVars env "$HOME")               "/home/user"            f
  check "var with path"      (expandVars env "$HOME/Downloads")     "/home/user/Downloads"  f
  check "two vars"           (expandVars env "$HOME/$XDG")          "/home/user//xdg"       f
  check "no vars"            (expandVars env "novar")               "novar"                 f
  check "unknown var"        (expandVars env "$UNKNOWN")            ""                      f
  check "lone dollar"        (expandVars env "price: $")            "price: $"              f
  check "dollar before sep"  (expandVars env "$/path")              "$/path"                f
  check "empty string"       (expandVars env "")                    ""                      f

private def testXdgVar (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.xdgVar"
  let env : List (String × String) := [("HOME", "/home/user")]
  check "DESKTOP entry"
    (xdgVar env ("XDG_DESKTOP_DIR", "$HOME/Desktop"))
    (some ("DESKTOP", "/home/user/Desktop")) f
  check "DOWNLOAD entry"
    (xdgVar env ("XDG_DOWNLOAD_DIR", "$HOME/Downloads"))
    (some ("DOWNLOAD", "/home/user/Downloads")) f
  check "absolute value"
    (xdgVar env ("XDG_MUSIC_DIR", "/mnt/music"))
    (some ("MUSIC", "/mnt/music")) f
  check "plain KEY=val (no XDG prefix)"
    (xdgVar env ("DESKTOP", "Desktop"))
    none f
  check "too few parts"
    (xdgVar env ("XDG_DIR", "foo"))
    none f
  check "too many parts"
    (xdgVar env ("XDG_EXTRA_DESKTOP_DIR", "foo"))
    none f
  check "missing DIR suffix"
    (xdgVar env ("XDG_DESKTOP_path", "foo"))
    none f

-- ---------------------------------------------------------------------------
-- System.Xdg.UserDir.Internal – IO tests (readPairs via temp file)
-- ---------------------------------------------------------------------------

private def testReadPairs (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.readPairs"
  let tmp : System.FilePath := ⟨"/tmp/xdg_lean_test_pairs"⟩
  IO.FS.writeFile tmp
    "# comment\n\nKEY1=val1\nKEY2=\"val2\"\nKEY3='val3'\nKEY4=a=b\n"
  let pairs ← readPairs tmp
  check "skips comments and blanks, reads four pairs" pairs
    [("KEY1", "val1"), ("KEY2", "val2"), ("KEY3", "val3"), ("KEY4", "a=b")] f
  IO.FS.removeFile tmp

  -- Non-existent file returns []
  let pairs2 ← readPairs ⟨"/tmp/xdg_lean_no_such_file_abc123"⟩
  check "missing file returns []" pairs2 [] f

-- ---------------------------------------------------------------------------
-- System.Xdg.UserDir – public API smoke tests
-- ---------------------------------------------------------------------------

private def testPublicApi (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir – public API"

  -- readDefaults: should never throw; returns [] on non-Linux or missing file
  let defs ← System.Xdg.UserDir.readDefaults
  let _ := defs  -- just check it doesn't throw
  ok "readDefaults does not throw"

  -- readUserDirs: should never throw
  let userDirs ← System.Xdg.UserDir.readUserDirs
  let _ := userDirs
  ok "readUserDirs does not throw"

  -- getUserDir for unknown key: should return $HOME (or "")
  let home := (← IO.getEnv "HOME").getD ""
  let p ← System.Xdg.UserDir.getUserDir "DOES_NOT_EXIST_XYZ_ABC"
  check "unknown key returns HOME" p.toString home f

  -- getUserDir for common keys: should return a non-empty path
  for key in ["DESKTOP", "DOWNLOAD", "DOCUMENTS", "MUSIC", "PICTURES", "VIDEOS"] do
    let dir ← System.Xdg.UserDir.getUserDir key
    checkTrue s!"getUserDir {key} is non-empty" (!dir.toString.isEmpty) f

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

def main : IO UInt32 := do
  let failures ← IO.mkRef (0 : Nat)

  testSplitBy    failures
  testParseXdgDirs failures
  testNotComment failures
  testStripQuotes failures
  testParsePair  failures
  testExpandVars failures
  testXdgVar     failures
  testReadPairs  failures
  testPublicApi  failures

  let n ← failures.get
  if n == 0 then
    IO.println s!"\nAll tests passed."
    return 0
  else
    IO.eprintln s!"\n{n} test(s) FAILED."
    return 1
