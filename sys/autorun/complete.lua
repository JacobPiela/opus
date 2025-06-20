local fs = _G.fs

local function completeMultipleChoice(sText, tOptions, bAddSpaces)
	local tResults = { }
	for n = 1,#tOptions do
		local sOption = tOptions[n]
		if #sOption + (bAddSpaces and 1 or 0) > #sText and string.sub(sOption, 1, #sText) == sText then
			local sResult = string.sub(sOption, #sText + 1)
			if bAddSpaces then
				table.insert(tResults, sResult .. " ")
			else
				table.insert(tResults, sResult)
			end
		end
	end
	return tResults
end

_ENV.shell.setCompletionFunction("sys/apps/package.lua",
	function(_, index, text)
		if index == 1 then
			return completeMultipleChoice(text, { "install ", "update ", "uninstall ", "updateall ", "refresh" })
		end
	end)

_ENV.shell.setCompletionFunction("sys/apps/inspect.lua",
	function(_, index, text)
		if index == 1 then
			local components = { }
			for _, f in pairs(fs.list('sys/modules/opus/ui/components')) do
				table.insert(components, (f:gsub("%.lua$", "")))
			end
			return completeMultipleChoice(text, components)
		end
	end)



--Editor
local c = function(shell, nIndex, sText)
	if nIndex == 1 then
		return _G.fs.complete(sText, shell.dir(), true, false)
	end
end

_ENV.shell.setCompletionFunction("packages/common/edit.lua", c)

_ENV.shell.registerHandler(function(env, command, args)
	if command:match('^!') then
		return {
			title = 'lua',
			path = table.concat({ command:match('^!(.+)'), table.unpack(args) }, ' '),
			args = args,
			load = function(s)
				return function()
					local fn, m
					local wrapped

					fn = load('return (' ..s.. ')', 'lua', nil, env)

					if fn then
						fn = load('return {' ..s.. '}', 'lua', nil, env)
						wrapped = true
					end

					if fn then
						fn, m = pcall(fn)
						if #m <= 1 and wrapped then
							m = m[1]
						end
					else
						fn, m = load(s, 'lua', nil, env)
						if fn then
							fn, m = pcall(fn)
						end
					end

					if fn then
						if m or wrapped then
							require('opus.util').print(m or 'nil')
						else
							print()
						end
					else
						_G.printError(m)
					end
				end
			end,
			env = env,
		}
	end
end)
