local M = {}

-- Edit user config file, based on the assumption it exists in the config as
-- theme = "theme name"
-- 1st arg as current theme, 2nd as new theme
M.change_theme = require "nvchad.change_theme"

-- clear command line from lua
M.clear_cmdline = function()
   vim.defer_fn(function()
      vim.cmd "echo"
   end, 0)
end

-- wrapper to use vim.api.nvim_echo
-- table of {string, highlight}
-- e.g echo({{"Hello", "Title"}, {"World"}})
M.echo = function(opts)
   if opts == nil or type(opts) ~= "table" then
      return
   end
   vim.api.nvim_echo(opts, false, {})
end

-- clear last echo using feedkeys (this is a bit hacky)
M.clear_last_echo = function()
   -- wrap this with inputsave and inputrestore just in case
   vim.fn.inputsave()
   vim.api.nvim_feedkeys(":", "nx", true)
   vim.fn.inputrestore()
end

-- a wrapper for running terminal commands that also handles errors
-- 1st arg - the command to run
-- 2nd arg - a boolean to indicate whether to print possible errors
-- returns the result if successful, nil otherwise
M.cmd = function(cmd, print_error)
   local result = vim.fn.system(cmd)
   if vim.api.nvim_get_vvar "shell_error" ~= 0 then
      if print_error then
         vim.api.nvim_err_writeln("Error running command:\n" .. cmd .. "\nError message:\n" .. result)
      end
      return nil
   end
   return result
end

-- 1st arg - r or w
-- 2nd arg - file path
-- 3rd arg - content if 1st arg is w
-- return file data on read, nothing on write
M.file = function(mode, filepath, content)
   local data
   local base_dir = vim.fn.fnamemodify(filepath, ":h")
   -- check if file exists in filepath, return false if not
   if mode == "r" and vim.fn.filereadable(filepath) == 0 then
      return false
   end
   -- check if directory exists, create it and all parents if not
   if mode == "w" and vim.fn.isdirectory(base_dir) == 0 then
      vim.fn.mkdir(base_dir, "p")
   end
   local fd = assert(vim.loop.fs_open(filepath, mode, 438))
   local stat = assert(vim.loop.fs_fstat(fd))
   if stat.type ~= "file" then
      data = false
   else
      if mode == "r" then
         data = assert(vim.loop.fs_read(fd, stat.size, 0))
      else
         assert(vim.loop.fs_write(fd, content, 0))
         data = true
      end
   end
   assert(vim.loop.fs_close(fd))
   return data
end

M.list_themes = function()
   local themes = {}

   local default_themes = vim.fn.stdpath "data" .. "/site/pack/packer/opt/base46/lua/hl_themes"
   local user_themes = vim.fn.stdpath "config" .. "/lua/custom/themes"

   -- list all theme files in above dirs into a table
   local theme_paths = require("plenary.scandir").scan_dir({ default_themes, user_themes }, {})

   -- trunacate absolute theme paths to just theme names
   for _, theme in ipairs(theme_paths) do
      local name = vim.fn.fnamemodify(theme, ":t")
      name = vim.fn.fnamemodify(name, ":r")

      themes[#themes + 1] = name
   end

   return themes
end

-- reload themes without restarting vim
-- if no theme name given then reload the current theme

M.reload_theme = require "nvchad.reload_theme"

-- update nvchad
M.update_nvchad = require "nvchad.updater.update"

-- create snapshot
M.snap = require "nvchad.updater.snap"

-- rollback nvchad
M.rollback = require "nvchad.updater.rollback"

M.write_data = function(old_data, new_data)
   local file_fn = require("nvchad").file
   local file = vim.fn.stdpath "config" .. "/lua/custom/" .. "chadrc.lua"
   local data = file_fn("r", file)

   local content = string.gsub(data, old_data, new_data)

   -- see if the find string exists in file
   assert(file_fn("w", file, content))
end

return M
