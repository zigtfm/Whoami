--[[ Translation ]]
	translation = {
		en = {
			journal = "Journal",
			notes = "Notes",
			hidden = "hidden",
			error = {
				longMessage = "Too long message",
			},
			command = { 
				nextTurn = "Next turn",
				allWordsGiven = "All words have been given.",
				newGame = "New game",
				playerWon = "Player %s won",
			},
			help = [[<a href='event:update_journal'><r>Version %s</r>
<p align='center'><font size='14'>Game "Who am i"</font></p>    Every player has a word which he needs to guess in order to win. The word is given by other players before the game and is visible in the journal. (Player, whose word is being discussed, can't open the journal, so he can't see the conversation )
After all words has been given, all players ask 3 questions by order. Answers can be only "yes" or "no". In the end player can try to guess a word by writting in chat.
After 3rd turn you can ask a tip from chosen by you player, but you can ask 3 questions this turn.
<p align='center'><font size='14'>Commands</font></p><b>P</b> - join the game
<b>!word <i>word</i></b> - change the word.
<b>!</b> - write a message in the journal

<b>H</b> - open this message.
<b>N</b> - add a note in the journal (only you can see it)
<b>V</b> - vote for the word

Press on the grey square or key <b>J</b> to open the journal]]
	},
		fr = {},
		br = {},
		ez = {},
		tr = {},
		pl = {},
		hu = {},
		ro = {},
		ar = {},
		vk = {},
		nl = {},
		id = {},
		de = {},
		ru = {
			journal = "Журнал",
			notes = "Записки",
			hidden = "скрыто",
			error = {
				longMessage = "Слишком длинное сообщение",
			},
			command = { 
				nextTurn = "Следующий ход",
				allWordsGiven = "Все слова разданы",
				newGame = "Новая игра",
				playerWon = "Игрок %s победил",
			},
			help = [[<a href='event:update_journal'><r>Версия %s</r>
<p align='center'><font size='14'>Игра "Кто я"</font></p>	У каждого игрока есть слово, которую ему надо угадать, чтобы победить. Слово задается другими игроками перед игрой и отображается в журнале. (Игрок, чью слово сейчас выбирают, не может открыть журнал, чтобы не видеть обсуждения )
	Когда все слова разданы, все игроки по очереди задают 3 вопроса. Ответом на них должны быть "да" или "нет". В конце хода игрок может попобовать угадать слово, написав в чат.
	С после вашего 3-го хода можно попросить подсказку от выбранного вами игрока, но вы не можете задавать вопросы на этот ход.
<p align='center'><font size='14'>Команды</font></p><b>P</b> - присоединиться к игре
<b>!word <i>слово</i></b> - изменить слово игрока.
<b>!</b> - написать сообщение в журнал

<b>H</b> - открыть это сообщение.
<b>N</b> - добавить заметку в журнал (её видите только Вы)
<b>V</b> - голосовать за выбор слова

Нажмите в области серого квадрата или клавишу <b>J</b> чтобы открыть журнал]],
		},
		cn = {},
		ph = {},
		lt = {},
		jp = {},
		fi = {},
		il = {},
		it = {},
		cz = {},
		hr = {},
		bg = {},
		lv = {},
		ee = {},
		rs = {},
	}
--[[ / ]]

--[[ Who used ]]

	local who_used
	do
		local _,name = pcall(nil)
		who_used = string.match(name, "(.-)%.")
	end

--[[ / --]]

function table.copy(t)
	local out = {}
	for i, v in next, t do
		out[i] = v
	end
	return out
end

-- var

	local playerTurnList = {}
	local isPicking = true
	local turn 

	misc = {
		version = "1.3.1"
	}

	local community = tfm.get.room.playerList[who_used].community
	community = translation[community].journal and community or "en"

	translation = table.copy(translation[community])
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
		return false
	end

--[[ / --]]


--[[ eventNewPlayer --]]

	--local playerData = {}

	local key = {
		J = string.byte("J"),
		N = string.byte("N"),
		H = string.byte("H"),
		V = string.byte("V"),
		P = string.byte("P"),
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

	local journalTextDefault = "<font color='#000'><bl><p align='center'><font size='14'>"..translation.journal.."</font></p><font face='Consolas'>"
	local journalText --= {"<font color='#000'><bl><p align='center'><font size='14'>Журнал</font></p><font face='Consolas'>"}

	-- get amount of lines in journal
	function calcJournalLen()
		local len = 0

		-- loop through all values of journalText

		-- 1st line is journalTextDefault
		-- so skip it
		for i = 2, #journalText do
			local v = journalText[i]

			-- get legnth of line
			-- -46 is for special invisible symbols
			-- like \n <b> <font> etc
			-- /80 is approx amount of characters in each line
			local lines = (length(v)-46)/80

			-- main ceil
			lines = math.ceil(lines)

			len = len + lines
		end

		return len
	end


	function fixLength()
		local len = calcJournalLen()

		-- delete lines in journal until
		-- their amount is <= 20
		while len > 20 do
			table.remove(journalText, 2)

			len = calcJournalLen()
		end
	end


	-- add a message to the journal
	function addMessage(playerName, message)
		local formattedPlayerName = formatPlayerName(playerName)

		message = message:gsub("("..string.rep("%S", 40-#playerName)..")", "%1\n", 1)

		if length(message) > 120-#playerName+10 then
			journalText[#journalText + 1] = "\n<bv>["..formattedPlayerName.."]</bv> : <r>"..translation.error.longMessage.."</r>"
		else
			journalText[#journalText + 1] = "\n<bv>["..formattedPlayerName.."]</bv> : <g>"..message.."</g>"
		end

		fixLength()

		ui.updateTextArea(15, table.concat(journalText, ""))
	end


	function addNote(playerName, message)
		local Data = playerData[playerName]

		Data.notes[#Data.notes + 1] = message:gsub("(note *)", "") or "<r>nil</r>"

		updateUi(playerName)
	end


	-- add player to the turn list
	function join(playerName)
		if playerData[playerName].role ~= "#" then
			playerData[playerName].isInGame = true
		else
			playerData[playerName].isInGame = isPicking
		end

		if not table.find(playerTurnList, playerName) then
			local pos = tfm.get.room.playerList[playerName]
			tfm.exec.displayParticle(15, pos.x, pos.y, 0, -1, 0, 0.1)

			playerTurnList[#playerTurnList + 1] = playerName			

			updateUi()
		end

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


	--[[ -- never used

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
	--]]


	-- return: if all players pickPoll == true
	function checkAgreedPlayers()
		for i, v in next, playerData do
			if (not v.pickPoll) and (v.isInGame) then
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
		ui.addTextArea(17, translation.help:format(misc.version), playerName, 190, 40, 430, 340, 0x000001, 0x000001, 0.5, true)
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
		
		if (keyCode == key.P) then
			join(playerName)
			return

		elseif (keyCode == key.H) then
			Data.isUiVisible = false
			updateUi(playerName)
			updateHelpMessage(playerName)
			
			return
		end

		if Data.isInGame then
			if (keyCode == key.J) then
				if isPicking and Data.isTurn then return end
	
				Data.isUiVisible = not Data.isUiVisible
				updateUi(playerName)
	
			elseif (keyCode == key.N) then
				ui.addPopup(0, 2, "", playerName, 350, 200, 100, true)
	
	
			elseif (keyCode == key.V) and (not Data.isTurn) and isPicking then
				Data.pickPoll = not Data.pickPoll
				checkAgreedPlayers()
	
				updateUi()
			end
		end
	end


	function eventPopupAnswer(popupId, playerName, answer)
		if answer ~= "" then
			addNote(playerName, "note "..answer)
		end
	end


	function notesText(playerName)
		local out, c = {"<font color='#000'><bl><p align='center'><font size='14'>"..translation.notes.."</font></p>"}, 1

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

				if Data.isTurn or (not Data.isInGame) then
					pollState = ""
				elseif Data.pickPoll then
					pollState = "<vp>✓</vp>"
				else
					pollState = "<r>✗</r>"
				end


				out[c] = color[1]..Name..color[2].." [ "..((playerName == Name) and "<b>"..translation.hidden.."</b>" or Data.role).." ] "..pollState.."\n"

			else
				if Data.isWon then
					out[c] ="<vp>"..Name.." [ "..Data.role.." ]</vp>\n"
				else
					out[c] = color[1]..Name..color[2].." [ "..((playerName == Name) and "<b>"..translation.hidden.."</b>" or Data.role).." ]\n"
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

--[[ 	local pickTimer = 0
	local pickTime = 20

	function eventLoop(elapsedTime, remainingTime)
		pickTimer = (pickTimer + 1) % pickTime
		if pickTime then

		end
	end ]]

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

				addMessage(playerName, "<rose>"..translation.command.nextTurn.."</rose>")
				return

			elseif args[1] == "start" then
				isPicking = false

				-- clear journal and set everyones isTurn to false
				journalText = {journalTextDefault}

				addMessage(playerName, "<rose>"..translation.command.allWordsGiven.."</rose>")
				updateUi()
				return

			elseif args[1] == "restart" then
				Reload()

				addMessage(playerName, "<rose>"..translation.command.newGame.."</rose>")
				return

			elseif args[1] == "win" then
				if playerData[args[2]] then
					playerWin(args[2])
					addMessage(playerName, string.format("<rose>"..translation.command.playerWon.."!</rose>", args[2]))
					updateUi()
				end
				return
			end
		end

		if (not Data.isTurn) and (playerName ~= args[2]) and (turn > 0) then
			if args[1] == "word" then
				if isPicking then
					local turnPlayer = playerTurnList[turn]

					playerData[turnPlayer].role = args[2] or "#"
					addMessage(playerName, "<n2>-&gt; "..args[2].."</n2>")

					updateUi()

				end
				return
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

		for playerName in next, tfm.get.room.playerList do
			eventNewPlayer(playerName)
			updateUi(playerName, false)
			print(isPicking)
		end

		turn = 0
	end


Reload()

for playerName in next, tfm.get.room.playerList do
	tfm.exec.setPlayerScore(playerName, 0, false)
end