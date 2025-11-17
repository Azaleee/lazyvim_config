vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt.indentexpr = ""
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    if vim.bo[args.buf].filetype == "" or vim.bo[args.buf].filetype == "text" then
      vim.cmd("filetype detect")
    end
    if not vim.fn.exists("g:syntax_on") or vim.fn.exists("g:syntax_on") == 0 then
      vim.cmd("syntax enable")
    end
  end,
})

local function clear_float_bg()
  vim.cmd("hi NormalFloat guibg=NONE ctermbg=NONE")
  vim.cmd("hi FloatBorder guibg=NONE ctermbg=NONE")
end
clear_float_bg()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NeovideFloatBG", { clear = true }),
  callback = clear_float_bg,
})
