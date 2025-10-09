import System.Xdg

def main : IO Unit := do
  IO.println s!"Hello, {System.Xdg.hello}!"

  -- Test XDG directory functions
  IO.println "=== XDG Directories ==="

  let dataHome ← System.Xdg.getDataHome
  IO.println s!"XDG_DATA_HOME: {dataHome}"

  let configHome ← System.Xdg.getConfigHome
  IO.println s!"XDG_CONFIG_HOME: {configHome}"

  let stateHome ← System.Xdg.getStateHome
  IO.println s!"XDG_STATE_HOME: {stateHome}"

  let cacheHome ← System.Xdg.getCacheHome
  IO.println s!"XDG_CACHE_HOME: {cacheHome}"

  -- Try to get runtime dir (might fail if not set)
  try
    let runtimeDir ← System.Xdg.getRuntimeDir
    IO.println s!"XDG_RUNTIME_DIR: {runtimeDir}"
  catch e =>
    IO.println s!"XDG_RUNTIME_DIR not set: {e}"

  IO.println "\n=== XDG Data Directories ==="
  let dataDirs ← System.Xdg.getDataDirs
  for dir in dataDirs do
    IO.println s!"  {dir}"

  IO.println "\n=== XDG Config Directories ==="
  let configDirs ← System.Xdg.getConfigDirs
  for dir in configDirs do
    IO.println s!"  {dir}"
