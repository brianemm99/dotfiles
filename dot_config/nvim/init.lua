vim.opt.autoindent = true

-- 2-space indentation everywhere
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.background = "dark"
vim.opt.number = true
vim.opt.relativenumber = true

vim.cmd.colorscheme("sorbet")

-- Highlight trailing whitespace
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
  pattern = "*",
  callback = function()
    vim.fn.matchadd("Error", [[\s\+$]])
  end,
})
