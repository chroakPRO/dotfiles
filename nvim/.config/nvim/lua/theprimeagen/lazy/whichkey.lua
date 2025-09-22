return {
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
        -- Set up which-key
        require("which-key").setup {
            ignore_missing = true,
          -- configuration options here
        }
        -- Register keybindings
        require("which-key").register({
          p = {
            f = { "<cmd>Telescope find_files<cr>", "Find Files" },
            w = {
              s = { "<cmd>Telescope grep_string<cr>", "Grep Word Under Cursor" },
              Ws = { "<cmd>Telescope grep_string<cr>", "Grep WORD Under Cursor" },
            },
            s = { "<cmd>Telescope live_grep<cr>", "Search" },
            v = { "<cmd>Ex<cr>", "Open File Explorer" }, -- Added
            ["vpp"] = { "<cmd>edit $MYVIMRC<cr>", "Edit Packer Config" }, -- Added
          },
          ["<C-p>"] = { "<cmd>Telescope git_files<cr>", "Find Git Files" },
          -- Add more which-key specific mappings here if needed
        }, {
          prefix = "<leader>"
        })
      end,
    }
  }