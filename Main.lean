import System.Xdg

def main : IO Unit := do
  -- Test XDG directory functions
  IO.println "=== XDG Directories ==="

  let dataHome ← System.Xdg.getXdgDirectory System.Xdg.XdgDirectory.Data ""

  IO.println s!"XDG_DATA_HOME: {dataHome}"

  let configHome ← System.Xdg.getXdgDirectory System.Xdg.XdgDirectory.Config ""
  IO.println s!"XDG_CONFIG_HOME: {configHome}"

  let stateHome ← System.Xdg.getXdgDirectory System.Xdg.XdgDirectory.State ""
  IO.println s!"XDG_STATE_HOME: {stateHome}"

  let cacheHome ← System.Xdg.getXdgDirectory System.Xdg.XdgDirectory.Cache ""
  IO.println s!"XDG_CACHE_HOME: {cacheHome}"

  -- Try to get runtime dir (might fail if not set)
  try
    let runtimeDir ← System.Xdg.getXdgDirectory System.Xdg.XdgDirectory.Runtime ""
    IO.println s!"XDG_RUNTIME_DIR: {runtimeDir}"
  catch e =>
    IO.println s!"XDG_RUNTIME_DIR not set: {e}"

  IO.println "\n=== XDG Data Directories ==="
  let dataDirs ← System.Xdg.getXdgDirectoryList System.Xdg.XdgDirectoryList.DataDirs
  for dir in dataDirs do
    IO.println s!"  {dir}"

  IO.println "\n=== XDG Config Directories ==="
  let configDirs ← System.Xdg.getXdgDirectoryList System.Xdg.XdgDirectoryList.ConfigDirs
  for dir in configDirs do
    IO.println s!"  {dir}"
