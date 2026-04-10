import System.Xdg
import Test.Harness

open Test.Harness

def testSplitBy (f : IO.Ref Nat) : IO Unit := do
  IO.println "System.Xdg.splitBy"
  check "basic split"         (System.Xdg.splitBy ':' "a:b:c") ["a", "b", "c"] f
  check "empty string"        (System.Xdg.splitBy ':' "")       []              f
  check "no separator"        (System.Xdg.splitBy ':' "abc")    ["abc"]         f
  check "empty segments drop" (System.Xdg.splitBy ':' "a::b")   ["a", "b"]      f
  check "leading sep drop"    (System.Xdg.splitBy ':' ":a")     ["a"]           f
  check "trailing sep drop"   (System.Xdg.splitBy ':' "a:")     ["a"]           f
  check "only seps"           (System.Xdg.splitBy ':' ":::")    []              f

def testParseXdgDirs (f : IO.Ref Nat) : IO Unit := do
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

def runXdgTests (f : IO.Ref Nat) : IO Unit := do
  testSplitBy f
  testParseXdgDirs f
