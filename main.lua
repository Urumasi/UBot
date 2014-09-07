local socket = require("socket")
local http = require("socket.http")
local json = require("json")
BOT = {CHAN="#UBot", PORT=6667, SERVER="irc.netfuze.net", NICK="UBot", USERNAME="UBot"}
IRC = {msg=" ", respond=0}
history = {"Welcome"}
curC = BOT.CHAN
rawtext = 0
typing = nil

source = "http://pastebin.com/fdKKZn6P"
no = {"Nope.", "Nah.", "No.", "Make me.", "Nuh-uh.", "No way."}
reply_cmds = {{"?ubot", "My name is UBot, I was made by Urumasi in Lua using LÖVE."}, {"?love", "LÖVE is available at http://love2d.org/"}}

function getF(fn)
	local file = io.open(fn, "r")
	local jf = file:read("*a")
	file:close()
	return json.decode(jf)
end
function trim(s)
	return s:find('^%s*$') and '' or s:match('^%s*(.*%S)')
end
function tFind(t, a)
	for k, v in ipairs(t) do
		if string.lower(v)==string.lower(a) then
			return k
		end
	end
	return nil
end
function saveP()
	local jsonString = json.encode({ADMINS, OPS, TRUSTED})
	local file = io.open("perms.json", "w")
	file:write(jsonString)
	file:close()
	clog("Saved "..jsonString)
end

function ping()
	IRC.msg = client:receive()
	if IRC.msg then
		if string.find(IRC.msg, "PING") == 1 then
			client:send("PONG :"..string.sub(IRC.msg, 7).."\r\n")
		end
	end
end
function sendM(m)
	client:send("PRIVMSG "..curC.." :"..m.."\r\n")
	clog("[BOT] <"..BOT.NICK.."> "..m)
end
function pm(n, m)
	client:send("PRIVMSG "..n.." :"..m.."\r\n")
	clog("Sent private message to "..n)
end
function procCmd(n, m)
	if m=="source" then
		if tFind(ADMINS, n) then
			pm(n, "Do NOT spread this source code please.")
			pm(n, source)
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;source")
		end
	end
	if m=="rawtext" then
		if tFind(ADMINS, n) then
			rawtext = 1-rawtext
			sendM("Raw text toggled .")
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;rawtext")
		end
	end
	if m=="part" then
		if tFind(ADMINS, n) then
			sendM("Goodbye!")
			love.event.push("quit")
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;part")
		end
	end
	if string.sub(m, 1, 4)=="join" and string.sub(m, 6) then
		if tFind(OPS, n) then
			sendM("See you there at "..string.sub(m, 6).."!")
			curC = string.sub(m, 6)
			client:send("JOIN "..curC.."\r\n")
			ping()
			sendM("Hello!")
			clog("Joined "..curC)
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;join")
		end
	end
	if m=="ping" then
		if string.lower(n)=="patrick" then
			sendM("Pong! [Not going to say what you suggest '._.]")
		else
			sendM("Pong!")
		end
	end
	if m=="todo" then
		pm(n, "Todo list:")
		for k, v in ipairs(TODO) do
			pm(n, v)
		end
	end
	if m=="help" or m=="commands" then
		pm(n, "List of commands:")
		for k, v in ipairs(HELP[1]) do
			pm(n, "  "..v)
		end
		if tFind(TRUSTED, n) then
			pm(n, "Trusted commands:")
			for k, v in ipairs(HELP[2]) do
				pm(n, "  "..v)
			end
		end
		if tFind(OPS, n) then
			pm(n, "Op commands:")
			for k, v in ipairs(HELP[3]) do
				pm(n, "  "..v)
			end
		end
		if tFind(ADMINS, n) then
			pm(n, "Admin commands:")
			for k, v in ipairs(HELP[4]) do
				pm(n, "  "..v)
			end
		end
	end
	if m=="drama" then
		if tFind(TRUSTED, n) then
			sendM(http.request("http://asie.pl/drama.php?plain"))
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;drama")
		end
	end
	if string.sub(m, 1, 5)=="whois" and string.sub(m, 7) then
		if string.lower(BOT.NICK)==string.lower(string.sub(m, 7)) then
			sendM(string.sub(m, 7).." is the Bot.")
		elseif tFind(ADMINS, string.sub(m, 7)) then
			sendM(string.sub(m, 7).." is an Admin.")
		elseif tFind(OPS, string.sub(m, 7)) then
			sendM(string.sub(m, 7).." is an Operator.")
		elseif tFind(TRUSTED, string.sub(m, 7)) then
			sendM(string.sub(m, 7).." is trused.")
		else
			sendM(string.sub(m, 7).." is normal.")
		end
	end
	if string.sub(m, 1, 6)=="notice" and string.sub(m, 8) then
		client:send("NOTICE "..string.sub(m, 8).."   -["..n.."]".."\r\n")
		clog("Noticing: "..string.sub(m, 8))
	end
	if string.sub(m, 1, 4)=="rank" and string.sub(m, 6) then
		if tFind(ADMINS, n) then
			local ws = string.find(string.sub(m, 6), " ")+5
			local wt = {n = string.sub(m, 6, ws-1), r = string.sub(m, ws+1)}
			if wt.n and wt.r then
				if wt.r=="normal" then
					for ri=1, #ADMINS do
						if tFind(ADMINS, wt.n) then
							table.remove(ADMINS, tFind(ADMINS, wt.n))
						end
					end
					for ri=1, #OPS do
						if tFind(OPS, wt.n) then
							table.remove(OPS, tFind(OPS, wt.n))
						end
					end
					for ri=1, #TRUSTED do
						if tFind(TRUSTED, wt.n) then
							table.remove(TRUSTED, tFind(TRUSTED, wt.n))
						end
					end
					sendM("Set rank of "..wt.n.." to "..wt.r)
				elseif wt.r=="trusted" then
					for ri=1, #ADMINS do
						if tFind(ADMINS, wt.n) then
							table.remove(ADMINS, tFind(ADMINS, wt.n))
						end
					end
					for ri=1, #OPS do
						if tFind(OPS, wt.n) then
							table.remove(OPS, tFind(OPS, wt.n))
						end
					end
					if not tFind(TRUSTED, wt.n) then
						table.insert(TRUSTED, wt.n)
					end
					sendM("Set rank of "..wt.n.." to "..wt.r)
				elseif wt.r=="operator" then
					for ri=1, #ADMINS do
						if tFind(ADMINS, wt.n) then
							table.remove(ADMINS, tFind(ADMINS, wt.n))
						end
					end
					if not tFind(OPS, wt.n) then
						table.insert(OPS, wt.n)
					end
					if not tFind(TRUSTED, wt.n) then
						table.insert(TRUSTED, wt.n)
					end
					sendM("Set rank of "..wt.n.." to "..wt.r)
				elseif wt.r=="admin" then
					if not tFind(ADMINS, wt.n) then
						table.insert(ADMINS, wt.n)
					end
					if not tFind(OPS, wt.n) then
						table.insert(OPS, wt.n)
					end
					if not tFind(TRUSTED, wt.n) then
						table.insert(TRUSTED, wt.n)
					end
					sendM("Set rank of "..wt.n.." to "..wt.r)
				end
			end
			saveP()
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;rank")
		end
	end
	if m=="reload" then
		if tFind(TRUSTED, n) then
			local jt = getF("perms.json")
			ADMINS = jt[1]
			OPS = jt[2]
			TRUSTED = jt[3]
			TODO = getF("todo.json")
			HELP = getF("help.json")
			sendM("Data reloaded.")
		else
			sendM(no[math.random(1, #no)])
			clog(n.." attempted to ;reload")
		end
	end
end
function clog(m)
	table.insert(history, m)
end

function love.load()
	local jt = getF("perms.json")
	ADMINS = jt[1]
	OPS = jt[2]
	TRUSTED = jt[3]
	TODO = getF("todo.json")
	HELP = getF("help.json")
	client, err = socket.tcp()
	if not client then
		error(err)
	end
	client:settimeout(20)
	client:connect(BOT.SERVER, BOT.PORT)
	ping()
	client:send("NICK "..BOT.NICK.."\r\n")
	ping()
	client:send("USER " ..BOT.USERNAME.." * 8 :"..BOT.NICK.."\r\n")
	ping()
	client:send("JOIN "..BOT.CHAN.."\r\n")
	ping()
	client:send("PRIVMSG nickserv identify SECRET\r\n") --I don't want you to see my bot's password
	sendM("Hello!")
	client:settimeout(0)
end
function love.update()
	IRC.msg = client:receive()
	if IRC.msg ~="" and IRC.msg then
		if rawtext==1 then
			clog(IRC.msg)
		end
		if string.find(IRC.msg, "PING") == 1 then
			client:send("PONG :"..string.sub(IRC.msg, 7).."\r\n")
		elseif string.find(string.lower(IRC.msg), string.lower(curC)) and string.find(IRC.msg, "!") then
			ms = string.sub(IRC.msg, string.find(string.lower(IRC.msg), string.lower(curC))+#curC+2)
			nm = string.sub(IRC.msg, 2, string.find(IRC.msg, "!")-1)
			clog()
			if rawtext==0 then
				if BOT.NICK==nm then
					lto = "[BOT] "
				elseif tFind(ADMINS, nm) then
					lto = "[ADMIN] "
				elseif tFind(OPS, nm) then
					lto = "[OP] "
				elseif tFind(TRUSTED, nm) then
					lto = "[TRUSTED] "
				else
					lto = ""
				end
				lto = lto.."<"..nm.."> "..ms
				clog(lto)
			end
			if string.sub(ms, 1, 1)==";" then
				procCmd(nm, string.lower(string.sub(ms, 2)))
			else
				for i=1, #reply_cmds do
					if string.lower(ms)==reply_cmds[i][1] then
						sendM(reply_cmds[i][2])
					end
				end
			end
		end
	end
end
function love.draw()
	local hamm = love.window.getHeight()/10-2
	for i=1, hamm do
		if history[#history+i-hamm] then
			if string.sub(history[#history+i-hamm], 1, 5)=="[BOT]" or string.sub(history[#history+i-hamm], 1, 5)=="[RAW]" or string.sub(history[#history+i-hamm], 1, 7)=="[ADMIN]" then
				love.graphics.setColor(255, 0, 0, 255)
			elseif string.sub(history[#history+i-hamm], 1, 4)=="[OP]" then
				love.graphics.setColor(255, 85, 85, 255)
			elseif string.sub(history[#history+i-hamm], 1, 9)=="[TRUSTED]" then
				love.graphics.setColor(255, 170, 170, 255)
			else
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		love.graphics.print(history[#history+i-hamm] or "", 0, i*10-10)
	end
	love.graphics.setColor(255, 255, 255, 255)
	if typing then
		love.graphics.print("> "..typing, 0, love.window.getHeight()-15)
	else
		love.graphics.print("", 0, 585)
	end
end
function love.mousepressed(x, y, b)
	if b=="l" and not typing then
		typing = ""
	elseif b=="r" then
		typing = nil
	end
end
function love.textinput(k)
	if typing then
		typing = typing..k
	end
end
function love.keypressed(k)
	if typing and typing~="" then
		if k=="return" then
			if string.sub(typing, 1, 6)=="//sraw" then
				client:send(string.sub(typing, 8).."\r\n")
				clog("[RAW] "..string.sub(typing, 8))
			elseif string.sub(typing, 1, 5)=="//raw" then
				sendM(string.sub(typing, 7))
			elseif string.sub(typing, 1, 4)=="//me" then
				sendM("\001ACTION "..string.sub(typing, 6).."\001")
			elseif string.sub(typing, 1, 1)=="/" then
				procCmd(BOT.NICK, string.lower(string.sub(typing, 2)))
			else
				sendM("[CONSOLE] "..typing)
			end
			typing = nil
		elseif k=="backspace" then
			typing = string.sub(typing, 1, #typing-1)
		end
	end
end