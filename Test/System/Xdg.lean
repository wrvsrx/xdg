import System.Xdg
import Test.Harness

open Test.Harness

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
  testParseXdgDirs f
