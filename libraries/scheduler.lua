scheduler = {}

waiting = {}

starttime = love.timer.getTime()

function scheduler.step()
	t = os.time()
	for i,task in ipairs(waiting) do
		if (t-task.start) >= task.delay then
			task.func()
			table.remove(waiting,i)
		end
	end
end

function scheduler.delay(n,f)
	local task = {
		start = os.time();
		delay = n;
		func = f;
	}
	table.insert(waiting,task)
end

function scheduler.runtime()
	return love.timer.getTime()-starttime
end

return scheduler