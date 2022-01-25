allow_defined = true
stds.eso = {
  read_globals = {"GetWorldName", ZO_SavedVars = {
    fields = {
      NewAccountWide = { read_only = true },
      NewCharacterIdSettings = { read_only = true },
    }
  }}
}
files["addons/**/*.lua"].std = "+eso"

-- vim: ft=lua
