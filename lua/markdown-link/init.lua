local MarkdownLink = {}
local config = {}

function MarkdownLink.setup(opts)
	config.valid_link_pattern = opts.valid_link_pattern or "^https?://.*"
	if type(config.valid_link_pattern) ~= "string" then
		error("valid_link_pattern has to be a string")
	end
end

local function getLastCharBeforeLocation(line, colnr)
	if colnr == 0 then
		return ""
	end
	local before_cursor = string.sub(line, 1, colnr)
	return vim.fn.strcharpart(before_cursor, vim.fn.strchars(before_cursor) - 1)
end

local function getPosToInsert(lines, mode)
	if not config.valid_link_pattern then
		error("Run setup() first")
	end
	local line, col
	if mode == "n" then
		local pos = vim.fn.getpos(".")
		line = pos[2] - 1
		col = pos[3]
	elseif mode == "i" then
		local pos = vim.fn.getpos(".")
		line = pos[2] - 1
		col = pos[3] - 1 -- TODO: only when not at end of line, should be - 1
	elseif mode == "v" then
		local pos1 = vim.fn.getpos("v")
		local pos2 = vim.fn.getpos(".")
		if pos1[2] ~= pos2[2] then
			error("Does not work with multi-line selections")
		end
		if pos1[3] > pos2[3] then
			pos2, pos1 = pos1, pos2
		end
		line = pos1[2] - 1
		local startCol = pos1[3]
		local endCol = pos2[3]
		if endCol > #lines[line + 1] then
			endCol = endCol - 1
		end
		vim.api.nvim_buf_set_text(0, line, endCol, line, endCol, { "]" })
		vim.api.nvim_buf_set_text(0, line, startCol - 1, line, startCol - 1, { "[" })
		col = endCol + 2
		lines[line + 1] = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
	end
	-- note: in case of col=0 (insert mode at start of line) last char was newline
	-- (or start of file, but neither matches `]`
	local char = getLastCharBeforeLocation(lines[line + 1], col)
	if char ~= "]" then
		error("Can only insert after a `]` character; under cursor: `" .. char .. "`")
	end
	return line, col
end

local function findOrInsertLinkAtBottom(lines, url)
	local MD_PATTERN = "^%[(%d+)%]: +(.+)$"

	local max_used_number = 0
	for _, myline in pairs(lines) do
		local nr_str, found_url = string.match(myline, MD_PATTERN)
		if nr_str then
			local nr = tonumber(nr_str) + 0
			if url == found_url then
				return nr
			end
			max_used_number = max_used_number > nr and max_used_number or nr
		end
	end

	if max_used_number == 0 then
		if lines[#lines] ~= "" then
			vim.api.nvim_buf_set_lines(0, -1, -1, true, { "", "" })
		elseif lines[#lines - 1] ~= "" then
			vim.api.nvim_buf_set_lines(0, -1, -1, true, { "" })
		end
	end
	vim.api.nvim_buf_set_lines(0, -1, -1, true, {
		"[" .. max_used_number + 1 .. "]: " .. url,
	})
	return max_used_number + 1
end

local function doPasteMarkdownLink()
	local url = vim.fn.getreg("*")
	if not string.match(url, config.valid_link_pattern) then
		error("Paste buffer does not contain a URL")
	end
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local modeAndBlocking = vim.api.nvim_get_mode()
	if modeAndBlocking.blocking then
		error("Cannot run while input is expected")
	end
	local mode = modeAndBlocking.mode

	local line, col = getPosToInsert(lines, mode)
	local nr = findOrInsertLinkAtBottom(lines, url)

	vim.api.nvim_buf_set_text(0, line, col, line, col, { "[" .. nr .. "]" })
	if mode == "v" then
		vim.api.nvim_input("<Esc>") -- exit visual mode
	end
	-- set cursor to end of just inserted block; if mode == i, we need to go one further
	vim.api.nvim_win_set_cursor(0, { line + 1, col + (mode == "i" and 3 or 2) })
end

function MarkdownLink.PasteMarkdownLink()
	local status, error = pcall(doPasteMarkdownLink)
	if not status then
		vim.api.nvim_err_writeln("" .. error)
	end
end

return MarkdownLink
