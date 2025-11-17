return {
  {
    "kwkarlwang/bufresize.nvim",
    lazy = false,
    config = function()
      local ok_bufresize, bufresize = pcall(require, "bufresize")
      if ok_bufresize then
        bufresize.setup({})
      end

      local utils_ok, utils = pcall(require, "config.utils")
      if not utils_ok then
        return
      end

      vim.api.nvim_create_autocmd("WinClosed", {
        callback = function(args)
          local win = tonumber(args.match)
          if not win then
            return
          end

          local cfg = vim.api.nvim_win_get_config(win)
          if cfg and cfg.relative ~= "" then
            return -- ignore les fenêtres flottantes
          end

          if ok_bufresize then
            bufresize.resize()
            bufresize.register()
          end

          utils.resize_snacks_explorer()
        end,
      })

      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          if ok_bufresize then
            bufresize.resize()
          end
          utils.resize_snacks_explorer()
        end,
      })

      vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
          utils.resize_snacks_explorer()
          if ok_bufresize then
            bufresize.register()
          end
        end,
      })
    end,
  },
}
