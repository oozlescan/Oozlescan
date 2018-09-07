function love.load()
	-- init

	--initialize
	love.filesystem.setIdentity("bot")
	_os = love.system.getOS()

	--load third party libraries
	http = require("socket.http")
	ltn12 = require("ltn12")
	json = require("libraries/json")

	--load my libraries
	require("libraries/scheduler")
	require("libraries/nestedtabletostring")

	--graphics
	love.window.setIcon(love.image.newImageData("hatscanicon.png"))
	love.window.setMode(640, 666, {resizable = true})
	font = love.graphics.newFont("SourceCodePro/SourceCodePro-Medium.otf",12)
	love.graphics.setColor(186,128,176)
	love.graphics.setBackgroundColor(66,56,74)

	--sounds
	sound = love.audio.newSource("hatfound.ogg","static")
	playsounds = true

	targets = {
		["roblox"] = true;
	}

	scanresults = {}
	scanresultids = {}
	scanned = 0
	logs = {}
	numlogs = 0

	mode = "searching" --stopped, searching, scanning
	paused = true

	starttime = os.time()
	start = 152980324
	current = start
	goal = math.huge
	finished = false
	focus = love.window.hasFocus()
	alert = false
	verbal = true
	flash = true
	autoopen = false

	outputheight = 10
	scanresultsheight = 3

	basesearchint = 100000000
	searchint = basesearchint
	acceptablesearchint = 1

	textinput = ""

	output("loaded libraries and configured settings")
	output("scanner ready! :)")
	output([[type "search" and press enter to start scanning from most recent asset]])
	output([[type "help" and press enter for help]])
	output("if you are unfamiliar with this, it's recommended that you read the help")

end

function output(string)
	numlogs = numlogs + 1
	table.insert(logs,("#"..numlogs.." @ "..math.floor(os.time()*100)/100)..": "..string)
	if #logs > outputheight then
		table.remove(logs,1)
	end
end

--opens link in web browser
function openurl(url)
	if _os == "OS X" then
		os.execute([[open ]]..url)
	elseif _os == "Linux" then
		os.execute([[xdg-open "]]..url..[[" ]])
	else
		os.execute([[start ]]..url)
	end
end

--fetches http data, sinks it into a table, assembles the table, and returns the assembled data
function httpget(_url)
	local t = {}
	local httpdata = http.request{
		url = _url;
		sink = ltn12.sink.table(t);
	}
	local assembleddata = table.concat(t)
	return assembleddata
end

--fetch image data from a url and return it as an imagedata
images = 0
function loadimagedata(_url,extension)
	local imgdata = love.image.newImageData(love.filesystem.newFileData(httpget(_url),"img"..images.."."..extension,"file"))
	images = images + 1
	return imgdata
end

function love.update(dt)

	if not paused then

		if mode == "searching" then

			scanned = scanned + 1

			if searchint <= acceptablesearchint then

				output("search finished, set current id to "..current)
				mode = "scanning"
				output("==========BEGINNING SCAN")

			else

				exists = nil
				pcall(function() exists = json.decode(httpget("http://api.roblox.com/marketplace/productinfo?assetId="..current)) end)

				if exists then
					if verbal then
						output(current.." exists, jumping "..searchint.." to "..current+searchint)
					end
					current = current + searchint
				else
					if verbal then
						output(current.." does not exist, reverting to "..current-searchint.." and changing search int to "..searchint/10)
					end
					current = current-searchint
					searchint = searchint/10
				end

			end

		elseif mode == "scanning" then


			if current <= goal+1 then

				scanned = scanned + 1

				local assetinfo = nil

				pcall(function() assetinfo = json.decode(httpget("http://api.roblox.com/marketplace/productinfo?assetId="..current)) end)

				if assetinfo then

					if assetinfo.Creator.Name and targets[string.lower(assetinfo.Creator.Name)] then

						table.insert(scanresults,"item #"..(#scanresults+1)..":\n  type: "..assetinfo.AssetTypeId.."\n  creator: "..assetinfo.Creator.Name.."\n  id: "..current.."\n  name: "..assetinfo.Name.."\n  description: "..assetinfo.Description.."\n  created: "..assetinfo.Created)
						output("found suspicious asset: "..current)
						table.insert(scanresultids,current)
						if playsounds then
							love.audio.stop()
							sound:play()
						end

						if not focus then
							alert = true
						end

						if autoopen then
							local link = "http://www.roblox.com/--item?id="..current
							output("auto opening "..link.." in web browser")
							openurl(link)
						end

					end

					if verbal then
						output("scanned "..current..[[, "]]..assetinfo.Name..[[" by ]]..assetinfo.Creator.Name)
					end

					current = current + 1

				else

					if verbal then
						output("ERROR: could not scan asset "..current..", trying again...")
					end

				end

			elseif not finished then

				output("finished")
				finished = true

			end

		end

	end

	love.window.setTitle((alert and "**" or "").."oozle's scanner - "..mode.." "..(paused and "(paused)" or ""))
	if alert and os.time()%2 == 1 then
		love.graphics.setBackgroundColor(112,98,122)
	else
		love.graphics.setBackgroundColor(66,56,74)
	end

end

function processinput()

	--page one of help
	if textinput == "help" then
		output("==========HELP, PAGE 1:")
		output([["search" to start scanning from most recent item (recommended)]])
		output([["newscan" to start a new scan scan with current settings without searching for most recent item]])
		output([["startat [num]" to set ## as the starting id]])
		output([["endat [num]" to set ## as the ending id, use "inf" to scan indefinitely]])
		output([["toggleverbal" to turn verbal output on/off]])
		output([["copy" to copy scan results to the clipboard]])
		output([["pause" to pause the current search]])
		output([["resume" to resume the current search]])
		output([["help2" to view second page of commands]])

	elseif textinput == "search" then
		output("==========SEARCHING FOR MOST RECENT ASSET")
		mode = "searching"
		current = start
		starttime = os.time()
		searchint = basesearchint
		scanned = 0
		scanresults = {}
		scanresultids = {}
		paused = false

	elseif textinput == "newscan" then
		output("==========BEGINNING NEW SCAN")
		mode = "scanning"
		current = start
		starttime = os.time()
		scanned = 0
		scanresults = {}
		scanresultids = {}
		paused = false

	elseif string.find(textinput,"startat") then
		local num = string.sub(textinput,string.len("startat")+2,string.len(textinput))
		local id = tonumber(num)
		if id then
			start = id
			output("changed starting id to "..id)
		else
			output(num.." is not a valid number")
		end

	elseif string.find(textinput,"endat") then
		local num = string.sub(textinput,string.len("endat")+2,string.len(textinput))
		local id = tonumber(num)
		if id then
			goal = id
			output("changed ending id to "..id..(num == "inf" and ", scanner will scan indefinitely" or ""))
		else
			output(num.." is not a valid number")
		end

	elseif textinput == "toggleverbal" then
		verbal = not verbal
		output("changed verbal to "..(verbal and "true" or "false"))

	elseif textinput == "copy" then
		local info = "SCAN RESULTS:\n\nscanned "..scanned.." ids in "..os.time()-starttime.." seconds and found "..#scanresults.." suspicious items\n\n"..table.concat(scanresults,"\n\n")
		love.system.setClipboardText(info)
		output("copied scan results to clipboard")

	elseif textinput == "pause" then
		output("scanner paused")
		paused = true

	elseif textinput == "resume" then
		output("scanner resumed")
		paused = false

	--page two of help
	elseif textinput == "help2" then
		output("==========HELP, PAGE 2:")
		output([["clear" to clear output]])
		output([["clearitems" to clear suspicious items]])
		output([["hideborder" to hide window borders (cannot be undone)]])
		output([["quit" to close window]])
		output([["goto ##" to go to the given asset]])
		output([["skip" to skip the current asset]])
		output([["togglesound" to toggle sound effects when hats are found]])
		output([["toggleflash" to toggle flashing effect when hats are found]])
		output([["help3" to view third page of commands]])

	elseif textinput == "clear" then
		for i=1,outputheight do
			output("")
		end
		output("output cleared")

	elseif textinput == "clearitems" then
		scanresults = {}
		scanresultids = {}
		scanned = 0
		output("suspicious items cleared")

	elseif textinput == "hideborder" then
		local width,height = love.window.getDimensions()
		love.window.setMode(width, height, {resizable = true; borderless = true})
		output("hid window borders")

	elseif textinput == "quit" then
		love.event.quit()

	elseif string.find(textinput,"goto") then
		local num = string.sub(textinput,string.len("goto")+2,string.len(textinput))
		local id = tonumber(num)
		if id then
			current = id
			output("changed current id to "..id)
		else
			output(num.." is not a valid number")
		end

	elseif textinput == "skip" then
		output("skipped asset "..current)
		current = current + 1

	elseif textinput == "togglesound" then
		playsounds = not playsounds
		output("turned sounds "..(playsounds and "on" or "off"))

	elseif textinput == "toggleflash" then
		flash = not flash
		output("turned flashing "..(flashing and "on" or "off"))

	--page three of help
	elseif textinput == "help3" then
		output("==========HELP, PAGE 3:")
		output([["open [num]" to open the specified item in the default web browser]])
		output([["open all" to open all suspicious items in the default web browser]])
		output([["target [user]" to toggle searching for items by the specified user]])
		output([["autoopen" to toggle auto opening links for suspicious items]])
		output([["itemheight num]" to change the number of shown suspicious items]])
		output([["butt" to butt]])
		output([["butt" to butt]])
		output([["butt" to butt]])
		output([["butt" to butt]])

	elseif string.find(textinput,"open") and textinput ~= "autoopen" then
		local input = string.sub(textinput,string.len("open")+2,string.len(textinput))
		local num = tonumber(input)
		if num and scanresultids[num] then
			local link = "http://www.roblox.com/--item?id="..scanresultids[num]
			output("opening "..link.." in web browser")
			openurl(link)
		elseif input == "all" then
			output("opening "..#scanresultids.." items in web browser")
			for _,id in ipairs(scanresultids) do
				love.timer.sleep(0.05)
				openurl("http://www.roblox.com/--item?id="..id)
			end
		else
			output(input.." is not a valid item")
		end

	elseif string.find(textinput,"target") then
		local user = string.lower(string.sub(textinput,string.len("target")+2,string.len(textinput)))
		targets[user] = not targets[user]
		output((targets[user] and "now searching for" or "stopped searching for").." items by "..user)

	elseif textinput == "autoopen" then
		autoopen = not autoopen
		output("autoopen "..(autoopen and "enabled" or "disabled"))

	elseif string.find(textinput,"itemheight") then
		local num = string.sub(textinput,string.len("itemheight")+2,string.len(textinput))
		local id = tonumber(num)
		if id then
			if id > 1 then
				scanresultsheight = id
				output("changed the number of shown items id to "..id)
			else
				scanresultsheight = 1
				output(id.." is too small, changes the number of shown items to 1")
			end
		else
			output(num.." is not a valid number")
		end

	elseif textinput == "butt" then
		output(string.rep(string.rep("butt ",40).."\n",50))

	--command not recognized
	else
		output("could not recognize input")
	end
	textinput = ""
end

function love.keypressed(key)
	if key == "backspace" then
		textinput = string.sub(textinput,1,#textinput-1)
	elseif key == "return" then
		processinput()
	else
		textinput = textinput..key
	end
end

function love.focus(f)
	focus = f
	if f then
		alert = false
	end
end

function love.draw()

	love.graphics.setFont(font)

	local stats = {
		"at id "..tostring(current)..", stopping at "..tostring(goal)..", elapsed time: "..(os.time()-starttime).." seconds, scanned ids: "..tostring(scanned);
		"";
	}

	table.insert(stats,"OUTPUT:")

	table.insert(stats,"")

	for i,v in ipairs(logs) do
		table.insert(stats,v)
	end

	table.insert(stats,"")

	table.insert(stats,"SUSPICIOUS ITEMS:")
	for i=1,scanresultsheight do
		local id = #scanresults - scanresultsheight + i
		if scanresults[id] then
			table.insert(stats,"\n"..scanresults[id])
		end
	end

	table.insert(stats,"")

	table.insert(stats,"COMMAND LINE:")

	table.insert(stats,">"..textinput.."_")

	love.graphics.print(table.concat(stats,"\n"),10,10)
	--love.graphics.print(filedata:getSize())

end
