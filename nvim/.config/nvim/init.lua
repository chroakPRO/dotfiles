-- Suppress all vim.tbl_* deprecation warnings from plugins
local original_deprecate = vim.deprecate
vim.deprecate = function(name, alternative, version, plugin, backtrace)
  if name and (name:match("tbl_add_reverse_lookup") or name:match("tbl_islist")) then
    return
  end
  if original_deprecate then
    original_deprecate(name, alternative, version, plugin, backtrace)
  end
end

require("theprimeagen")
vim.g.python3_host_prog = "/Users/chek/miniconda/bin/python"
