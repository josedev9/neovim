local dap_status_ok, dap = pcall(require, "dap")
if not dap_status_ok then
	return
end

local dap_ui_status_ok, dapui = pcall(require, "dapui")
if not dap_ui_status_ok then
	return
end

function Get_current_username()
  local handle = io.popen("whoami")
    if handle then
        local result = handle:read("*a")
        local success, reason, code = handle:close()
        if success then
            -- Strip trailing newline character
            return result and result:match("^%s*(.-)%s*$")
        else
            -- Handle error in closing the handle
            print("Error closing handle:", reason, code)
        end
    else
        -- Handle error in opening the handle
        print("Error opening handle")
    end
    return nil
end


local username = Get_current_username()

local miniconda_dir = string.format('/home/%s/miniconda3/envs/working/bin/python', username);
local conda_dir = string.format('/home/joser/anaconda3/envs/working/bin/python', username);
function Exists()
    local file = io.open(miniconda_dir, "r")
    local filetwo = io.open(conda_dir, "r")
    if file then
        io.close(file)
        return miniconda_dir
    elseif filetwo then
        io.close(filetwo)
        return conda_dir
    else
        return "/usr/bin/python3"
    end
end
-- local dap_install_status_ok, dap_install = pcall(require, "dap-install")
-- if not dap_install_status_ok then
-- 	return
-- end

-- dap_install.setup({
-- 	installation_path = vim.fn.stdpath("data") .. "/dapinstall/",
-- })
-- dap_install.config("python", {})
-- dap_install.config("codelldb", {})
dap.adapters.python = {
  type = 'executable';
  command = Exists();
  args = { '-m', 'debugpy.adapter' };
}
dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = 'launch';
    name = "Launch file";

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    program = "${file}"; -- This configuration will launch the current file if used.
    pythonPath = dap.adapters.python.command;
  },
}
dap.adapters.codelldb = {
    type = 'server',
  port = '${port}',
  executable = {
    -- CHANGE THIS to your path!
    command = '/home/jose/.local/share/nvim/mason/packages/codelldb/codelldb',
    args = {"--port", "${port}"},

    -- On windows you may have to uncomment this:
    -- detached = false,
  }
}
dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
-- add other configs here

dapui.setup({
	expand_lines = true,
	icons = { expanded = "", collapsed = "", circular = "" },
	mappings = {
		-- Use a table to apply multiple mappings
		expand = { "<CR>", "<2-LeftMouse>" },
		open = "o",
		remove = "d",
		edit = "e",
		repl = "r",
		toggle = "t",
	},
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.33 },
				{ id = "breakpoints", size = 0.17 },
				{ id = "stacks", size = 0.25 },
				{ id = "watches", size = 0.25 },
			},
			size = 0.33,
			position = "right",
		},
		{
			elements = {
				{ id = "repl", size = 0.55 },
				{ id = "console", size = 0.45 },
			},
			size = 0.27,
			position = "bottom",
		},
	},
	floating = {
		max_height = 0.9,
		max_width = 0.5, -- Floats will be treated as percentage of your screen.
		border = vim.g.border_chars, -- Border style. Can be 'single', 'double' or 'rounded'
		mappings = {
			close = { "q", "<Esc>" },
		},
	},
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end
