" Set up minimal runtimepath
set rtp+=~/.local/share/nvim/lazy/plenary.nvim
set rtp+=~/.local/share/nvim/lazy/telescope.nvim

" Configure Lua environment to persist in tests
lua <<EOF
-- Store original package.path if not already stored
if not _G.__test_package_path then
  _G.__test_package_path = package.path .. ';' ..
    vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim/lua/?.lua') .. ';' ..
    vim.fn.expand('~/.local/share/nvim/lazy/telescope.nvim/lua/?.lua') .. ';' ..
    vim.fn.expand('~/.local/share/nvim/lazy/telescope.nvim/lua/?/init.lua')
end

-- Hook into PlenaryBusted test environment
vim.api.nvim_create_autocmd('User', {
  pattern = 'BustedStart',
  callback = function()
    -- Reset package.path for test environment
    package.path = _G.__test_package_path
    print('Test environment package.path configured')
  end
})

-- Initialize for current session
package.path = _G.__test_package_path
require('telescope').setup()
EOF

" Load core plugin files
runtime! plugin/plenary.vim
runtime! plugin/telescope.lua
