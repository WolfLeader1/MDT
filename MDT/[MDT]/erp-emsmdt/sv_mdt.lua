RegisterCommand("ems", function(source, args, rawCommand)
	local usource = source
	local xPlayer = exports['envyrp']:GetPlayerFromId(usource)
	if xPlayer then
		if xPlayer.job.name == 'ambulance' and xPlayer.job.duty == 1 then
				MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_reports_ems` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(reports)
					for r = 1, #reports do
						reports[r].charges = json.decode(reports[r].charges)
					end
				local officer = GetCharacterName(xPlayer, true)
				TriggerClientEvent('emsmdt:toggleVisibilty', usource, reports, {}, officer)
			end)
		elseif xPlayer.job.name == 'ambulance' and xPlayer.job.duty == 0 then
			local officer = GetCharacterName(xPlayer, true)
			TriggerClientEvent('emsmdt:offduty', usource, officer)
		end 
	end
end, false)

RegisterNetEvent("emsmdt:hotKeyOpen")
AddEventHandler("emsmdt:hotKeyOpen", function(src, sentSwitch)
	local usource = source
	if src then usource = src end
    local xPlayer = exports['envyrp']:GetPlayerFromId(usource)
    if xPlayer.job.name == 'ambulance' and xPlayer.job.duty == 1 then
    	MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_reports_ems` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(reports)
    		for r = 1, #reports do
    			reports[r].charges = json.decode(reports[r].charges)
			end
			local officer = GetCharacterName(xPlayer, true)
			if sentSwitch == true then
				switch = true
			else
				switch = false
			end
			TriggerClientEvent('emsmdt:toggleVisibilty', usource, reports, {}, officer, false)
    	end)
    end
end)

local fines = {
	--[[ Title 1 ]]--
	{["id"] = 1, ["title"] = "P.C. 2101", ["label"] = "Use for now", ["amount"] = 750}

}

RegisterNetEvent("emsmdt:getOffensesAndOfficer")
AddEventHandler("emsmdt:getOffensesAndOfficer", function()
	local usource = source
	local officer = GetCharacterName(usource)
	TriggerClientEvent("emsmdt:returnOffensesAndOfficer", usource, fines, officer)
end)

RegisterNetEvent("emsmdt:performOffenderSearch")
AddEventHandler("emsmdt:performOffenderSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE LOWER(`firstname`) LIKE @query OR LOWER(`lastname`) LIKE @query OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`)) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			table.insert(matches, data)
		end

		TriggerClientEvent("emsmdt:returnOffenderSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("emsmdt:getOffenderDetails")
AddEventHandler("emsmdt:getOffenderDetails", function(offender)
	local usource = source
	GetLicenses(offender.id, function(licenses) 
		offender.licenses = licenses 
		MySQL.Async.fetchAll('SELECT * FROM `user_mdt_ems` WHERE `char_id` = @id', {
			['@id'] = offender.id
		}, function(result)
			offender.notes = ""
			offender.mugshot_url = ""
			if result[1] then
				offender.notes = result[1].notes
				offender.mugshot_url = result[1].mugshot_url
			end
			MySQL.Async.fetchAll('SELECT * FROM `user_convictions_ems` WHERE `char_id` = @id', {
				['@id'] = offender.id
			}, function(convictions)
				if convictions[1] then
					offender.convictions = {}
					for i = 1, #convictions do
						local conviction = convictions[i]
						offender.convictions[conviction.offense] = conviction.count
					end
				end
				offender.haswarrant = false
				TriggerClientEvent("emsmdt:returnOffenderDetails", usource, offender)
			end)
		end)
	end)
end)

RegisterNetEvent("erp-emsmdt:switchDuty")
AddEventHandler("erp-emsmdt:switchDuty", function()
	local src = source
	local player = exports['envyrp']:GetPlayerFromId(source)
	if player then
		local job = player.job.name
		local grade = player.job.grade
		local duty = player.job.duty

		if job == 'ambulance' and duty == 1 then
			TriggerEvent('envyrp:toggleduty', src)
			TriggerClientEvent('emsmdt:offduty', src)
			TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = 'inform', text = 'You are now off-duty.', length = 5000, style = { ['background-color'] = '#4287f5', ['color'] = '#ffffff' } })
		elseif job == 'ambulance' and duty == 0 then
			TriggerEvent('envyrp:toggleduty', src)
			TriggerEvent('emsmdt:hotKeyOpen', src, false)
			TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = 'inform', text = 'You are now on-duty.', length = 5000, style = { ['background-color'] = '#4287f5', ['color'] = '#ffffff' } })
		end
	end
end) 

RegisterNetEvent("emsmdt:getOffenderDetailsById")
AddEventHandler("emsmdt:getOffenderDetailsById", function(char_id)
	local usource = source
	MySQL.Async.fetchAll('SELECT * FROM `users` WHERE `id` = @id', {
		['@id'] = char_id
	}, function(result)
		local offender = result[1]
		GetLicenses(offender.id, function(licenses) 
			offender.licenses = licenses 
			MySQL.Async.fetchAll('SELECT * FROM `user_mdt_ems` WHERE `char_id` = @id', {
				['@id'] = offender.id
			}, function(result)
				offender.notes = ""
				offender.mugshot_url = ""
				if result[1] then
					offender.notes = result[1].notes
					offender.mugshot_url = result[1].mugshot_url
				end
				MySQL.Async.fetchAll('SELECT * FROM `user_convictions_ems` WHERE `char_id` = @id', {
					['@id'] = offender.id
				}, function(convictions)
					if convictions[1] then
						offender.convictions = {}
						for i = 1, #convictions do
							local conviction = convictions[i]
							offender.convictions[conviction.offense] = conviction.count
						end
					end
	
					TriggerClientEvent("emsmdt:returnOffenderDetails", usource, offender)
				end)
			end)
		end)	
	end)
end)

RegisterNetEvent("emsmdt:saveOffenderChanges")
AddEventHandler("emsmdt:saveOffenderChanges", function(id, changes)
	MySQL.Async.fetchAll('SELECT * FROM `user_mdt_ems` WHERE `char_id` = @id', {
		['@id']  = id
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE `user_mdt_ems` SET `notes` = @notes, `mugshot_url` = @mugshot_url WHERE `char_id` = @id', {
				['@id'] = id,
				['@notes'] = changes.notes,
				['@mugshot_url'] = changes.mugshot_url
			})
		else
			MySQL.Async.insert('INSERT INTO `user_mdt_ems` (`char_id`, `notes`, `mugshot_url`) VALUES (@id, @notes, @mugshot_url)', {
				['@id'] = id,
				['@notes'] = changes.notes,
				['@mugshot_url'] = changes.mugshot_url
			})
		end

		if changes and #changes.licenses_removed > 0 then
			for i = 1, #changes.licenses_removed do
				local license = changes.licenses_removed[i]
				MySQL.Async.execute('DELETE FROM `licenses` WHERE `type` = @type AND `cid` = @cid', {
					['@type'] = license.type,
					['@cid'] = id
				})
			end
		end

		if changes and changes.convictions then
			for conviction, amount in pairs(changes.convictions) do	
				MySQL.Async.execute('UPDATE `user_convictions_ems` SET `count` = @count WHERE `char_id` = @id AND `offense` = @offense', {
					['@id'] = id,
					['@count'] = amount,
					['@offense'] = conviction
				})
			end
		end

		if changes and #changes.convictions_removed > 0 then
			for i = 1, #changes.convictions_removed do
				MySQL.Async.execute('DELETE FROM `user_convictions_ems` WHERE `char_id` = @id AND `offense` = @offense', {
					['@id'] = id,
					['offense'] = changes.convictions_removed[i]
				})
			end
		end
	end)
end)

RegisterNetEvent("emsmdt:saveReportChanges")
AddEventHandler("emsmdt:saveReportChanges", function(data)
	MySQL.Async.execute('UPDATE `mdt_reports_ems` SET `title` = @title, `incident` = @incident WHERE `id` = @id', {
		['@id'] = data.id,
		['@title'] = data.title,
		['@incident'] = data.incident
	})
end)

RegisterNetEvent("emsmdt:deleteReport")
AddEventHandler("emsmdt:deleteReport", function(id)
	MySQL.Async.execute('DELETE FROM `mdt_reports_ems` WHERE `id` = @id', {
		['@id']  = id
	})
end)

RegisterNetEvent("emsmdt:submitNewReport")
AddEventHandler("emsmdt:submitNewReport", function(data)
	local usource = source
	local author = GetCharacterName(source)
	if tonumber(data.sentence) and tonumber(data.sentence) > 0 then
		data.sentence = tonumber(data.sentence)
	else 
		data.sentence = nil 
	end
	charges = json.encode(data.charges)
	data.date = os.date('%m-%d-%Y %H:%M:%S', os.time())
	MySQL.Async.insert('INSERT INTO `mdt_reports_ems` (`char_id`, `title`, `incident`, `charges`, `author`, `name`, `date`, `jailtime`) VALUES (@id, @title, @incident, @charges, @author, @name, @date, @sentence)', {
		['@id']  = data.char_id,
		['@title'] = data.title,
		['@incident'] = data.incident,
		['@charges'] = charges,
		['@author'] = author,
		['@name'] = data.name,
		['@date'] = data.date,
		['@sentence'] = data.sentence
	}, function(id)
		TriggerEvent("emsmdt:getReportDetailsById", id, usource)
	end)

	for offense, count in pairs(data.charges) do
		MySQL.Async.fetchAll('SELECT * FROM `user_convictions_ems` WHERE `offense` = @offense AND `char_id` = @id', {
			['@offense'] = offense,
			['@id'] = data.char_id
		}, function(result)
			if result[1] then
				MySQL.Async.execute('UPDATE `user_convictions_ems` SET `count` = @count WHERE `offense` = @offense AND `char_id` = @id', {
					['@id']  = data.char_id,
					['@offense'] = offense,
					['@count'] = count + 1
				})
			else
				MySQL.Async.insert('INSERT INTO `user_convictions_ems` (`char_id`, `offense`, `count`) VALUES (@id, @offense, @count)', {
					['@id']  = data.char_id,
					['@offense'] = offense,
					['@count'] = count
				})
			end
		end)
	end
end)

RegisterNetEvent("emsmdt:submitNewBolo")
AddEventHandler("emsmdt:submitNewBolo", function(data)
	local usource = source
	local author = GetCharacterName(source)
	if tonumber(data.sentence) and tonumber(data.sentence) > 0 then
		data.sentence = tonumber(data.sentence)
	else 
		data.sentence = nil 
	end
	data.date = os.date('%m-%d-%Y %H:%M:%S', os.time())
	MySQL.Async.insert('INSERT INTO `bolo_reports` (`title`, `incident`, `author`, `date`) VALUES (@title, @incident, @author, @date)', {
		['@title'] = data.title,
		['@incident'] = data.incident,
		['@author'] = author,
		['@date'] = data.date,
	}, function(id)
		TriggerEvent("emsmdt:getReportDetailsById", id, usource)
	end)
end)

RegisterNetEvent("emsmdt:sentencePlayer")
AddEventHandler("emsmdt:sentencePlayer", function(jailtime, charges, char_id, fine, players)
	local usource = source
	local jailmsg = ""
	for offense, amount in pairs(charges) do
		jailmsg = jailmsg .. " "..offense.." x"..amount.." |"
	end
	for _, src in pairs(players) do
		if src ~= 0 and GetPlayerName(src) then
			MySQL.Async.fetchAll('SELECT * FROM `users` WHERE `identifier` = @identifier', {
				['@identifier'] = GetPlayerIdentifiers(src)[1]
			}, function(result)
				if result[1].id == char_id then
					if jailtime and jailtime > 0 then
						jailtime = math.ceil(jailtime)
						TriggerEvent("tp-qalle-jail:jailPlayer", src, jailtime, jailmsg)
					end
					if fine > 0 then
						TriggerClientEvent("emsmdt:billPlayer", usource, src, 'police', 'Fine: '..jailmsg, fine)
					end
					return
				end
			end)
		end
	end
end)

RegisterNetEvent("emsmdt:performReportSearch")
AddEventHandler("emsmdt:performReportSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `mdt_reports_ems` WHERE `id` LIKE @query OR LOWER(`title`) LIKE @query OR LOWER(`name`) LIKE @query OR LOWER(`author`) LIKE @query or LOWER(`charges`) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			data.charges = json.decode(data.charges)
			table.insert(matches, data)
		end

		TriggerClientEvent("emsmdt:returnReportSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("emsmdt:performBoloSearch")
AddEventHandler("emsmdt:performBoloSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `bolo_reports`", {
		--['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			table.insert(matches, data)
		end

		TriggerClientEvent("emsmdt:returnBoloSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("emsmdt:performVehicleSearch")
AddEventHandler("emsmdt:performVehicleSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `owned_vehicles` WHERE LOWER(`plate`) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			local data_decoded = json.decode(data.vehicle)
			data.model = data_decoded.model
			if data_decoded.color1 then
				data.color = colors[tostring(data_decoded.color1)]
				if colors[tostring(data_decoded.color2)] then
					data.color = colors[tostring(data_decoded.color2)] .. " on " .. colors[tostring(data_decoded.color1)]
				end
			end
			table.insert(matches, data)
		end

		TriggerClientEvent("emsmdt:returnVehicleSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("emsmdt:getWarrants")
AddEventHandler("emsmdt:getWarrants", function()
	local usource = source
	TriggerClientEvent("emsmdt:returnWarrants", usource, {})
end)

RegisterNetEvent("emsmdt:getBolos")
AddEventHandler("emsmdt:getBolos", function()
	local usource = source
	MySQL.Async.fetchAll("SELECT * FROM `bolo_reports`", {}, function(bolos)
		TriggerClientEvent("emsmdt:returnBolos", usource, bolos)
	end)
end)

RegisterNetEvent("emsmdt:submitNewWarrant")
AddEventHandler("emsmdt:submitNewWarrant", function(data)
	local usource = source
	data.charges = json.encode(data.charges)
	data.author = GetCharacterName(source)
	data.date = os.date('%m-%d-%Y %H:%M:%S', os.time())
	MySQL.Async.insert('INSERT INTO `mdt_warrants_ems` (`name`, `char_id`, `report_id`, `report_title`, `charges`, `date`, `expire`, `notes`, `author`) VALUES (@name, @char_id, @report_id, @report_title, @charges, @date, @expire, @notes, @author)', {
		['@name']  = data.name,
		['@char_id'] = data.char_id,
		['@report_id'] = data.report_id,
		['@report_title'] = data.report_title,
		['@charges'] = data.charges,
		['@date'] = data.date,
		['@expire'] = data.expire,
		['@notes'] = data.notes,
		['@author'] = data.author
	}, function()
		TriggerClientEvent("emsmdt:completedWarrantAction", usource)
	end)
end)

RegisterNetEvent("emsmdt:deleteWarrant")
AddEventHandler("emsmdt:deleteWarrant", function(id)
	local usource = source
	MySQL.Async.execute('DELETE FROM `mdt_warrants_ems` WHERE `id` = @id', {
		['@id']  = id
	}, function()
		TriggerClientEvent("emsmdt:completedWarrantAction", usource)
	end)
end)

RegisterNetEvent("emsmdt:deleteBolo")
AddEventHandler("emsmdt:deleteBolo", function(id)
	local usource = source
	MySQL.Async.execute('DELETE FROM `bolo_reports` WHERE `id` = @id', {
		['@id']  = id
	}, function()
		TriggerClientEvent("emsmdt:completedBoloAction", usource)
	end)
end)

RegisterNetEvent("emsmdt:getReportDetailsById")
AddEventHandler("emsmdt:getReportDetailsById", function(query, _source)
	if _source then source = _source end
	local usource = source
	MySQL.Async.fetchAll("SELECT * FROM `mdt_reports_ems` WHERE `id` = @query", {
		['@query'] = query
	}, function(result)
		if result and result[1] then
			result[1].charges = json.decode(result[1].charges)
			TriggerClientEvent("emsmdt:returnReportDetails", usource, result[1])
		end
	end)
end)

function GetLicenses(cid, cb)
	local licenses = {}
	MySQL.Async.fetchAll('SELECT * FROM licenses WHERE cid = @cid', {
		['@cid'] = cid
	}, function(result)
		if result then
			for i=1, #result do
				local result2 = exports['erp-license']:GetLicenseInfo(result[i]['type'])
				if result2 then
					table.insert(licenses, {
						type = result[i]['type'],
						label = result2['label']
					})
				end
			end
		end
		cb(licenses)
	end)
end

function GetCharacterName(source, isInfo)
	if source then
		local xPlayer = source
		if not isInfo then xPlayer = exports['envyrp']:GetPlayerFromId(source) end
		if type(xPlayer) == 'table' then
			return xPlayer.firstname..' '..xPlayer.lastname
		else
			return ""
		end
	end
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end