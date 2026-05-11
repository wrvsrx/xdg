import System.Xdg

/--
info: [FilePath.mk "/usr/share", FilePath.mk "/usr/local/share"]
-/
#guard_msgs in
#eval System.Xdg.parseXdgDirs "/usr/share:/usr/local/share"

/--
info: [FilePath.mk "/etc/xdg"]
-/
#guard_msgs in
#eval System.Xdg.parseXdgDirs "/etc/xdg"

/--
info: []
-/
#guard_msgs in
#eval System.Xdg.parseXdgDirs ""
