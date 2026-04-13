import System.Xdg.UserDir
import Test.Harness

open Test.Harness
open System.Xdg.UserDir.Internal

def testNotComment (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.notComment"
  checkFalse "empty string"         (notComment "")                f
  checkFalse "hash at start"        (notComment "# comment")       f
  checkFalse "hash alone"           (notComment "#")               f
  checkTrue  "valid pair"           (notComment "KEY=value")       f
  checkTrue  "leading space"        (notComment "  KEY=value")     f
  checkTrue  "XDG_DESKTOP_DIR line" (notComment "XDG_DESKTOP_DIR=\"$HOME/Desktop\"") f

def testStripQuotes (f : IO.Ref Nat) : IO Unit := do
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

def testParsePair (f : IO.Ref Nat) : IO Unit := do
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

def testExpandVars (f : IO.Ref Nat) : IO Unit := do
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

def testPairToXdgPair (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.pairToXdgPair"
  check "DESKTOP entry"
    (pairToXdgPair ("XDG_DESKTOP_DIR", "$HOME/Desktop"))
    (some ("DESKTOP", "$HOME/Desktop")) f
  check "DOWNLOAD entry"
    (pairToXdgPair ("XDG_DOWNLOAD_DIR", "$HOME/Downloads"))
    (some ("DOWNLOAD", "$HOME/Downloads")) f
  check "absolute value"
    (pairToXdgPair ("XDG_MUSIC_DIR", "/mnt/music"))
    (some ("MUSIC", "/mnt/music")) f
  check "plain KEY=val (no XDG prefix)"
    (pairToXdgPair ("DESKTOP", "Desktop"))
    none f
  check "too few parts"
    (pairToXdgPair ("XDG_DIR", "foo"))
    none f
  check "too many parts"
    (pairToXdgPair ("XDG_EXTRA_DESKTOP_DIR", "foo"))
    none f
  check "missing DIR suffix"
    (pairToXdgPair ("XDG_DESKTOP_path", "foo"))
    none f

def testReadPairs (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir.Internal.readPairs"
  let tmp : System.FilePath := ⟨"/tmp/xdg_lean_test_pairs"⟩
  IO.FS.writeFile tmp
    "# comment\n\nKEY1=val1\nKEY2=\"val2\"\nKEY3='val3'\nKEY4=a=b\n"
  let pairs ← readPairs tmp
  check "skips comments and blanks, reads four pairs" pairs
    [("KEY1", "val1"), ("KEY2", "val2"), ("KEY3", "val3"), ("KEY4", "a=b")] f
  IO.FS.removeFile tmp

  let pairs2 ← readPairs ⟨"/tmp/xdg_lean_no_such_file_abc123"⟩
  check "missing file returns []" pairs2 [] f

def testPublicApi (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.UserDir – public API"

  let defs ← System.Xdg.UserDir.readDefaults
  let _ := defs
  ok "readDefaults does not throw"

  let userDirs ← System.Xdg.UserDir.readUserDirs
  let _ := userDirs
  ok "readUserDirs does not throw"

  let p ← System.Xdg.UserDir.getUserDir "DOES_NOT_EXIST_XYZ_ABC"
  check "unknown key returns none" p none f

  for key in ["DESKTOP", "DOWNLOAD", "DOCUMENTS", "MUSIC", "PICTURES", "VIDEOS"] do
    let dir ← System.Xdg.UserDir.getUserDir key
    checkTrue s!"getUserDir {key} is non-empty" (!dir.isNone) f

def runUserDirTests (f : IO.Ref Nat) : IO Unit := do
  testNotComment f
  testStripQuotes f
  testParsePair f
  testExpandVars f
  testPairToXdgPair f
  testReadPairs f
  testPublicApi f
