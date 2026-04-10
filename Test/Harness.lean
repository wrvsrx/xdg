namespace Test.Harness

def ok (label : String) : IO Unit :=
  IO.println s!"  ✓ {label}"

def fail (label : String) (detail : String) (failures : IO.Ref Nat) : IO Unit := do
  IO.eprintln s!"  ✗ {label}"
  IO.eprintln s!"    {detail}"
  failures.modify (· + 1)

def check [BEq α] [ToString α]
    (label : String) (actual expected : α) (failures : IO.Ref Nat) : IO Unit := do
  if actual == expected then
    ok label
  else
    fail label s!"expected: {expected}\n    actual:   {actual}" failures

def checkTrue (label : String) (b : Bool) (failures : IO.Ref Nat) : IO Unit :=
  check label b true failures

def checkFalse (label : String) (b : Bool) (failures : IO.Ref Nat) : IO Unit :=
  check label b false failures

end Test.Harness
