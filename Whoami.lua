--[[ Who used ]]

	local who_used
	do
		local _,name = pcall(nil)
		who_used = string.match(name, "(.-)%.")
	end

--[[ / --]]

-- var

	local playerTurnList = {}
	local isPicking = true
	local turn 

--

--[[ Misc functions --]]

	function formatPlayerName(s)
		return s:sub(0, -6).."<font size='9'><g>"..s:sub(-5).."</g></font>"
	end

	-- length that counts russian letters correct (which are utf-8)
	function length(s)
		local out = 0
		s = s:lower()

		for v in s:gmatch("[а-я][а-я]") do
			out = out + 1
		end
		for v in s:gmatch("[^а-я]") do
			out = out + 1
		end
		return out
	end

	-- return : index by value
	function table.find(t, v)
		for i, s in next, t do
			if v == s then
				return i

			end
		end
	end

--[[ / --]]


--[[ eventNewPlayer --]]

	--local playerData = {}

	local key = {
		J = string.byte("J"),
		N = string.byte("N"),
		H = string.byte("H"),
		V = string.byte("V"),
	}

	function eventNewPlayer(playerName)
		tfm.exec.respawnPlayer(playerName)

		if not playerData[playerName] then
			playerData[playerName] = {
				isUiVisible = false,
				isTurn = false,
				isWon = false,
				isInGame = false,
				pickPoll = false,
				role = "#",
				notes = {},
			}
		end
		
		if playerData[playerName].role ~= "#" then
			playerData[playerName].isInGame = true
		else
			playerData[playerName].isInGame = isPicking
		end

		for _, v in next, key do
			system.bindKeyboard(playerName, v, true, true)	
		end

		updateHelpMessage(playerName)

	end

	--table.foreach(tfm.get.room.playerList, eventNewPlayer)


	function eventPlayerLeft(playerName)
		playerData[playerName].isInGame = false
	end


	function eventPlayerDied(playerName)
		tfm.exec.respawnPlayer(playerName)
	end

--[[ / --]]


--[[ Main --]]

	local journalTextDefault = "<font color='#000'><bl><p align='center'><font size='14'>Журнал</font></p><font face='Consolas'>"
	local journalText --= {"<font color='#000'><bl><p align='center'><font size='14'>Журнал</font></p><font face='Consolas'>"}

	function calcJournalLen(excess)
		local len = #journalText

		for i = 2, #journalText do
			local v = journalText[i]

			local lines = (length(v)-excess)/80
			lines = (lines < 1 and 0) or math.ceil(lines)

			len = len + lines
		end

		return len
	end


	function fixLength(excess)
		local len = calcJournalLen(excess)

		while len > 20 do
			table.remove(journalText, 2)

			len = calcJournalLen(excess)
		end
	end


	function addMessage(playerName, message)
		local formattedPlayerName = formatPlayerName(playerName)

		message = message:gsub("("..string.rep("%S", 40-#playerName)..")", "%1\n", 1)

		if length(message) > 120-#playerName+10 then
			journalText[#journalText + 1] = "\n<bv>["..formattedPlayerName.."]</bv> : <r>Слишком длинное сообщение</r>"
		else
			journalText[#journalText + 1] = "\n<bv>["..formattedPlayerName.."]</bv> : <g>"..message.."</g>"
		end

		fixLength(46)

		ui.updateTextArea(15, table.concat(journalText, ""))
	end


	function addNote(playerName, message)
		local Data = playerData[playerName]

		Data.notes[#Data.notes + 1] = message:gsub("(note *)", "") or "<r>nil</r>"

		updateUi(playerName)
	end


	function nextTurn()
		for i, v in next, playerData do
			v.pickPoll = false
		end

		-- set prev. player to false
		if turn > 0 then
			local Data = playerData[playerTurnList[turn]]
			Data.isTurn = false
		end

		-- next turn
		local isNotValid = true

		while isNotValid do
			turn = turn + 1
			if turn > #playerTurnList then
				turn = 1 
			end
			if playerData[playerTurnList[turn]].isInGame then
				isNotValid = playerData[playerTurnList[turn]].isWon
			end
		end


		local turnPlayer = playerTurnList[turn]
		-- spawn an arrow
		local Data = tfm.get.room.playerList[turnPlayer]
		tfm.exec.addShamanObject(0, Data.x, Data.y)

		-- set next player to true
		Data = playerData[turnPlayer]
		Data.isTurn = true

		-- update journal if picking
		if isPicking then
			journalText = {journalTextDefault}
			Data.isUiVisible = false
			updateUi(turnPlayer)
		end

		updateUi()
	end


	function updateTurns()
		playerTurnList = {}
		c = 0
		for playerName, Data in next, playerData do
			if not Data.isWon then
				c = c + 1
				playerTurnList[c] = playerName
			end
		end
	end


	function checkAgreedPlayers()
		for i, v in next, playerData do
			if not v.pickPoll then
				if not v.isTurn then
					return
				end
			end
		end

		nextTurn()
	end


	function playerWin(playerName)
		playerData[playerName].isWon = true

		tfm.exec.giveCheese(playerName)
		tfm.exec.playerVictory(playerName)
		tfm.exec.respawnPlayer(playerName)

		updateUi()

		for i, v in next, playerData do
			if v.isInGame then
				if not v.isWon then
					return
				end
			end
		end
		Reload()
	end


	function eventChatMessage(playerName, message)
		local Data = playerData[playerName]

		if Data.isTurn then
			if message == Data.role then
				playerWin(playerName)
				nextTurn()
			end
		end
	end
--[[ / --]]


--[[ Text --]]

	local addText = ui.addTextArea
	local removeText = ui.removeTextArea


	function updateJournalUi(playerName, isVisible)
		if isVisible then
			addText(0, "", playerName, 90, 40, 630, 340, 0x3d1b01, 0x3d1b01, 1, true)
			addText(1, "", playerName, 90, 40, 313, 340, 0x240901, 0x3d1b01, 1, true)
			addText(2, "", playerName, 100, 60, 300, 300, 0xc4c4c4, 0xc4c4c4, 1, true)
			addText(3, "", playerName, 410, 60, 300, 300, 0xd1d1d1, 0xd1d1d1, 1, true)

			for i = 1, 10 do
				addText(i+3, "", playerName, 395, i * 30 + 45, 20, 0, 0x948109, 0xb59b0b, 1, true)
			end

			addText(15, table.concat(journalText, ""), playerName, 100, 60, 280, 300, 0x324650, 0x000000, 0, true)
			addText(16, notesText(playerName), playerName, 430, 60, 280, 300, 0x324650, 0x000000, 0, true)

			addText(17, "<a href='event:update_journal'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", playerName, 190, 40, 430, 340, 0x324650, 0x000001, 0, true)
		else
			for i = 0, 16 do
				removeText(i, playerName)
			end
		end
	end


	function updateUi(playerName)
		if playerName then
			updateJournalUi(playerName, playerData[playerName].isUiVisible)
		else
			for playerName, Data in next, playerData do
				updateJournalUi(playerName, Data.isUiVisible)
			end
		end
	end


	function updateHelpMessage(playerName)
		ui.addTextArea(17, "<a href='event:update_journal'><r>! Обновление 1.2</r>\n<p align='center'><font size='14'>Игра \"Кто я\"</font></p>\n\tРоль каждого игрока выбирается перед началом игры, и будет отображаться в журнале. Вы не будете видеть только свою роль. Игрок, чью роль сейчас выбирают, не может открыть журнал, чтобы не видеть обсуждения. После того, как все роли разданы, все игроки по очереди задают 3 вопроса. Ответом на них должны быть \"да\" или \"нет\". В конце, выделенный игрок может попробовать угадать роль, написав в чат.\n\tС 4-го хода можно попросить подсказку от выбранного вами игрока, но вы не можете задавать вопросы на этот ход.\n\n<p align='center'><font size='14'>Команды</font></p>\n<b>H</b> или <b>!help</b> - открыть это сообщение.\n<b>!role <i>роль</i></b> - изменить роль игрока.\n<b>!</b> - написать в журнал сообщение\n<b>N</b> или <b>!note <i>заметка</i></b> - добавить заметку в журнал (её видите только Вы)\n<b>V</b> или <b>!+</b> - голосовать за выбор роли\n\nНажмите в области серого квадрата или клавишу <b>J</b> чтобы открыть журнал\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", playerName, 190, 40, 430, 340, 0x000001, 0x000001, 0.5, true)
	end


	function eventTextAreaCallback(textAreaId, playerName, eventName)
		local Data = playerData[playerName]

		if eventName == "update_journal" then

			if not Data.isTurn then
				Data.isUiVisible = not Data.isUiVisible
				updateUi(playerName)
			end
		end
	end


	function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
		local Data = playerData[playerName]

		if (keyCode == key.J) then
			if isPicking and Data.isTurn then return end

			Data.isUiVisible = not Data.isUiVisible
			updateUi(playerName)

		elseif (keyCode == key.N) then
			ui.addPopup(0, 2, "", playerName, 350, 200, 100, true)

		elseif (keyCode == key.H) then
			updateHelpMessage(playerName)

		elseif (keyCode == key.V) and (not Data.isTurn) and isPicking then
			Data.pickPoll = not Data.pickPoll
			checkAgreedPlayers()

			updateUi()
		end
	end


	function eventPopupAnswer(popupId, playerName, answer)
		if answer then
			addNote(playerName, "note "..answer)
		end
	end


	function notesText(playerName)
		local out, c = {"<font color='#000'><bl><p align='center'><font size='14'>Записки</font></p>"}, 1

		for Name, Data in next, playerData do
			c = c + 1

			local color

			if Data.isInGame then
				color = (Data.isTurn and {"&gt; <b><vp>", "</vp></b>"}) or {"<bv>", "</bv>"}
			else
				color = {"<n2>", "</n2>"}
			end

			if isPicking then

				local pollState

				if Data.isTurn then
					pollState = ""
				elseif Data.pickPoll then
					pollState = "<vp>✓</vp>"
				else
					pollState = "<r>✗</r>"
				end


				out[c] = color[1]..Name..color[2].." [ "..((playerName == Name) and "<b>скрыто</b>" or Data.role).." ] "..pollState.."\n"

			else
				if Data.isWon then
					out[c] ="<vp>"..Name.." [ "..Data.role.." ]</vp>\n"
				else
					out[c] = color[1]..Name..color[2].." [ "..((playerName == Name) and "<b>скрыто</b>" or Data.role).." ]\n"
				end
			end
		end

		for i, note in next, playerData[playerName].notes do
			c = c + 1
			out[c] = "<bv>"..i.."</bv>. "..note..".\n"
		end

		return table.concat(out, "")
	end

--[[ / --]]


--[[ Flags --]]

	tfm.exec.disableAutoTimeLeft()
	tfm.exec.disableAutoNewGame()
	tfm.exec.disableAutoScore()
	tfm.exec.disableAfkDeath()
	tfm.exec.disableAutoShaman()
	tfm.exec.disableMinimalistMode()
	tfm.exec.disablePhysicalConsumables()
	tfm.exec.setUIMapName("#whoami - <bl>Zigwin<bl>")
	system.disableChatCommandDisplay(nil)

--[[ --]]


--[[ Debug --]]

	function log(args)
		local matches, c = {}, 1
		do
			for match in string.gmatch(debug.traceback(), "in .- (.-)\n") do
				matches[c] = match
				c = c + 1
			end
		end
		do
			local _args = {}
			for i, v in next, args do
				_args[i] = tostring(v)
			end
			args = _args
		end


		print("<n>"..table.concat(matches, "</n> <g>-></g> <n>").."\n\t"..table.concat(args, "\n\t").."</n>")
	end

--[[ / --]]


--[[ Eventloop --]]

	local pickTimer = 0
	local pickTime = 20

	function eventLoop(elapsedTime, remainingTime)
		pickTimer = (pickTimer + 1) % pickTime
		if pickTime then

		end
	end

--[[ / --]]


--[[ Commonds --]]

	function eventChatCommand(playerName, command)
		local args, c = {}, 1

		for match in string.gmatch(command, "%S+") do
			args[c] = match
			c = c + 1
		end

		local Data = playerData[playerName]

		if args[1] == "note" then
			addNote(playerName, command)

			return
		elseif args[1] == "help" then
			updateHelpMessage(playerName)

			return
		end

		if playerName == who_used then
			if args[1] == "next" then
				nextTurn()

				addMessage(playerName, "<rose>Следующий ход</rose>")
				return
			elseif args[1] == "start" then
				isPicking = false

				-- clear journal and set everyones isTurn to false
				journalText = {journalTextDefault}

				addMessage(playerName, "<rose>Все роли разданы</rose>")
				updateUi()
				return
			elseif args[1] == "restart" then
				Reload()

				addMessage(playerName, "<rose>Новая игра</rose>")
				return

			elseif args[1] == "win" then
				if playerData[args[2]] then
					playerWin(args[2])
					addMessage(playerName, "<rose>Игрок "..args[2].." победил!</rose>")
					updateUi()
				end
				return
			end
		end

		if (not Data.isTurn) and (playerName ~= args[2]) then
			if isPicking then
				if args[1] == "role" then
					local turnPlayer = playerTurnList[turn]

					playerData[turnPlayer].role = args[2] or "#"
					addMessage(playerName, "<n2>-&gt; "..args[2].."</n2>")

					updateUi()

					return

				elseif args[1] == "+" then
					Data.pickPoll = not Data.pickPoll
					checkAgreedPlayers()

					updateUi()
					return
				end
			end


			addMessage(playerName, command)		
			return
		end
	end

--[[ / ]]

	function Reload()
		journalText = {journalTextDefault}
		playerData = {}
		playerTurnList = {}
		isPicking = true
		local c = 0

		for playerName in next, tfm.get.room.playerList do
			c = c + 1
			playerTurnList[c] = playerName

			eventNewPlayer(playerName)
			updateUi(playerName, false)
			print(isPicking)
		end

		turn = 0

		nextTurn()
	end


Reload()

for playerName in next, tfm.get.room.playerList do
	tfm.exec.setPlayerScore(playerName, 0, false)
end