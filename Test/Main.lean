import Test.Xdg
import Test.UserDir

def main : IO UInt32 := do
  let failures ← IO.mkRef (0 : Nat)

  runXdgTests failures
  runUserDirTests failures

  let n ← failures.get
  if n == 0 then
    IO.println s!"\nAll tests passed."
    return 0
  else
    IO.eprintln s!"\n{n} test(s) FAILED."
    return 1
