RegisterCommand("mdt", function(source, args, rawCommand)
	local usource = source
    local xPlayer = exports['envyrp']:GetPlayerFromId(usource)
	print(xPlayer.job.isPolice)
    if (xPlayer.job.isPolice) and xPlayer.job.duty == 1 then
    	MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_reports` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(reports)
    		for r = 1, #reports do
    			reports[r].charges = json.decode(reports[r].charges)
    		end
    		MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_warrants` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(warrants)
    			for w = 1, #warrants do
    				warrants[w].charges = json.decode(warrants[w].charges)
				end
				local officer = ""
				local jobInfo = exports['envyrp']:GetJobInfo(xPlayer.job.name)
    		if jobInfo then officer = jobInfo['grades'][xPlayer.job.grade]['label']..' '..xPlayer.lastname
				else officer = xPlayer.fullname end
				TriggerClientEvent('mdt:toggleVisibilty', usource, reports, warrants, officer)
    	end)
		end)
	elseif xPlayer.job.isPolice and xPlayer.job.duty == 0 then
		local officer = xPlayer.fullname
		TriggerClientEvent('mdt:offduty', usource, officer)
  end
end, false)

RegisterNetEvent("mdt:hotKeyOpen")
AddEventHandler("mdt:hotKeyOpen", function(src, sentSwitch)
	local usource = source
	if src then usource = src end
    local xPlayer = exports['envyrp']:GetPlayerFromId(usource)
		if xPlayer then
			if (xPlayer.job.isPolice or xPlayer.job.name == 'doj' or xPlayer.job.name == 'mib') and xPlayer.job.duty == 1 then
				MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_reports` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(reports)
					for r = 1, #reports do
						reports[r].charges = json.decode(reports[r].charges)
					end
					MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_warrants` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(warrants)
						for w = 1, #warrants do
							warrants[w].charges = json.decode(warrants[w].charges)
					end

					local officer = ""
					local jobInfo = exports['envyrp']:GetJobInfo(xPlayer.job.name)
					if jobInfo then officer = jobInfo['grades'][xPlayer.job.grade]['label']..' '..xPlayer.lastname
					else officer = xPlayer.fullname end
					if sentSwitch == true then
						switch = true
					else
						switch = false
					end
					TriggerClientEvent('mdt:toggleVisibilty', usource, reports, warrants, officer, false)
					end)
				end)
			end
		end
end)

RegisterNetEvent("mdt:getOffensesAndOfficer")
AddEventHandler("mdt:getOffensesAndOfficer", function()
	local src = source
	TriggerEvent('envyrp:getplayerfromid', src, function(player)
		if player then
			local fines = exports['erp-police']:GetFines()
			local officer = ""
			local jobInfo = exports['envyrp']:GetJobInfo(player.job.name)
			if jobInfo then officer = jobInfo['grades'][player.job.grade]['label']..' '..player.lastname
			else officer = player.fullname end
			TriggerClientEvent("mdt:returnOffensesAndOfficer", src, fines, officer)
		end
	end)
end)

RegisterNetEvent("mdt:performOffenderSearch")
AddEventHandler("mdt:performOffenderSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `users` WHERE LOWER(`firstname`) LIKE @query OR LOWER(`lastname`) LIKE @query OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`)) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			table.insert(matches, data)
		end

		TriggerClientEvent("mdt:returnOffenderSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("mdt:getOffenderDetails")
AddEventHandler("mdt:getOffenderDetails", function(offender)
	local usource = source
	GetLicenses(offender.id, function(licenses) 
		offender.licenses = licenses 
		MySQL.Async.fetchAll('SELECT * FROM `user_mdt` WHERE `char_id` = @id', {
			['@id'] = offender.id
		}, function(result)
			offender.notes = ""
			offender.mugshot_url = ""
			if result[1] then
				offender.notes = result[1].notes
				offender.mugshot_url = result[1].mugshot_url
			end
			MySQL.Async.fetchAll('SELECT * FROM `user_convictions` WHERE `char_id` = @id', {
				['@id'] = offender.id
			}, function(convictions)
				if convictions[1] then
					offender.convictions = {}
					for i = 1, #convictions do
						local conviction = convictions[i]
						offender.convictions[conviction.offense] = conviction.count
					end
				end
	
				MySQL.Async.fetchAll('SELECT * FROM `mdt_warrants` WHERE `char_id` = @id', {
					['@id'] = offender.id
				}, function(warrants)
					if warrants[1] then
						offender.haswarrant = true
					end
	
					TriggerClientEvent("mdt:returnOffenderDetails", usource, offender)
				end)
			end)
		end)
	end)
	
end)

RegisterNetEvent("mdt:getOffenderDetailsById")
AddEventHandler("mdt:getOffenderDetailsById", function(char_id)
	local usource = source
	MySQL.Async.fetchAll('SELECT * FROM `users` WHERE `id` = @id', {
		['@id'] = char_id
	}, function(result)
		if result and result[1] then
			local offender = result[1]
			GetLicenses(offender.id, function(licenses) 
				offender.licenses = licenses 
				MySQL.Async.fetchAll('SELECT * FROM `user_mdt` WHERE `char_id` = @id', {
					['@id'] = offender.id
				}, function(result)
					offender.notes = ""
					offender.mugshot_url = ""
					if result[1] then
						offender.notes = result[1].notes
						offender.mugshot_url = result[1].mugshot_url
					end
					MySQL.Async.fetchAll('SELECT * FROM `user_convictions` WHERE `char_id` = @id', {
						['@id'] = offender.id
					}, function(convictions)
						if convictions[1] then
							offender.convictions = {}
							for i = 1, #convictions do
								local conviction = convictions[i]
								offender.convictions[conviction.offense] = conviction.count
							end
						end
	
						TriggerClientEvent("mdt:returnOffenderDetails", usource, offender)
					end)
				end)
			end)
		end
	end)
end)

RegisterNetEvent("mdt:saveOffenderChanges")
AddEventHandler("mdt:saveOffenderChanges", function(id, changes)
	MySQL.Async.fetchAll('SELECT * FROM `user_mdt` WHERE `char_id` = @id', {
		['@id']  = id
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE `user_mdt` SET `notes` = @notes, `mugshot_url` = @mugshot_url WHERE `char_id` = @id', {
				['@id'] = id,
				['@notes'] = changes.notes,
				['@mugshot_url'] = changes.mugshot_url
			})
		else
			MySQL.Async.insert('INSERT INTO `user_mdt` (`char_id`, `notes`, `mugshot_url`) VALUES (@id, @notes, @mugshot_url)', {
				['@id'] = id,
				['@notes'] = changes.notes,
				['@mugshot_url'] = changes.mugshot_url
			})
		end

		if changes and changes.licenses_removed then
			for k,v in pairs(changes.licenses_removed) do
				MySQL.Sync.execute("DELETE FROM licenses WHERE type=@type AND cid=@cid", { ['@type'] = v.type, ['@cid'] = id })
			end
		end

		if changes and changes.convictions then
			for conviction, amount in pairs(changes.convictions) do	
				MySQL.Async.execute('UPDATE `user_convictions` SET `count` = @count WHERE `char_id` = @id AND `offense` = @offense', {
					['@id'] = id,
					['@count'] = amount,
					['@offense'] = conviction
				})
			end
		end

		if changes and changes.convictions_removed and #changes.convictions_removed > 0 then
			for i = 1, #changes.convictions_removed do
				MySQL.Async.execute('DELETE FROM `user_convictions` WHERE `char_id` = @id AND `offense` = @offense', {
					['@id'] = id,
					['offense'] = changes.convictions_removed[i]
				})
			end
		end
	end)
end)

RegisterNetEvent("mdt:saveReportChanges")
AddEventHandler("mdt:saveReportChanges", function(data)
	MySQL.Async.execute('UPDATE `mdt_reports` SET `title` = @title, `incident` = @incident WHERE `id` = @id', {
		['@id'] = data.id,
		['@title'] = data.title,
		['@incident'] = data.incident
	})
end)

RegisterNetEvent("mdt:saveBoloChanges")
AddEventHandler("mdt:saveBoloChanges", function(data)
	MySQL.Async.execute('UPDATE `mdt_bolos` SET `plate` = @plate, `owner` = @owner, `individual` = @individual WHERE `id` = @id', {
		['@id'] = data.id,
		['@plate'] = data.plate,
		['@owner'] = data.owner,
		['@individual'] = data.individual
	})
end)

RegisterNetEvent("mdt:deleteReport")
AddEventHandler("mdt:deleteReport", function(id)
	MySQL.Async.execute('DELETE FROM `mdt_reports` WHERE `id` = @id', {
		['@id']  = id
	})
end)

RegisterNetEvent("mdt:deleteBolo")
AddEventHandler("mdt:deleteBolo", function(id)
	MySQL.Async.execute('DELETE FROM `mdt_bolos` WHERE `id` = @id', {
		['@id']  = id
	})
end)

RegisterNetEvent("mdt:submitNewReport")
AddEventHandler("mdt:submitNewReport", function(data)
	local usource = source
	local fullname = exports['envyrp']:GetOnePlayerInfo(usource, 'fullname')
	if fullname then
		local author = fullname
		if tonumber(data.sentence) and tonumber(data.sentence) > 0 then
			data.sentence = tonumber(data.sentence)
		else 
			data.sentence = nil 
		end
		charges = json.encode(data.charges)
		data.date = os.date('%m-%d-%Y %H:%M:%S', os.time())
		MySQL.Async.insert('INSERT INTO `mdt_reports` (`char_id`, `title`, `incident`, `charges`, `author`, `name`, `date`, `jailtime`) VALUES (@id, @title, @incident, @charges, @author, @name, @date, @sentence)', {
			['@id']  = data.char_id,
			['@title'] = data.title,
			['@incident'] = data.incident,
			['@charges'] = charges,
			['@author'] = author,
			['@name'] = data.name,
			['@date'] = data.date,
			['@sentence'] = data.sentence
		}, function(id)
			TriggerEvent("mdt:getReportDetailsById", id, usource)
		end)

		for offense, count in pairs(data.charges) do
			MySQL.Async.fetchAll('SELECT * FROM `user_convictions` WHERE `offense` = @offense AND `char_id` = @id', {
				['@offense'] = offense,
				['@id'] = data.char_id
			}, function(result)
				if result[1] then
					MySQL.Async.execute('UPDATE `user_convictions` SET `count` = @count WHERE `offense` = @offense AND `char_id` = @id', {
						['@id']  = data.char_id,
						['@offense'] = offense,
						['@count'] = count + 1
					})
				else
					MySQL.Async.insert('INSERT INTO `user_convictions` (`char_id`, `offense`, `count`) VALUES (@id, @offense, @count)', {
						['@id']  = data.char_id,
						['@offense'] = offense,
						['@count'] = count
					})
				end
			end)
		end
	end
end)

RegisterNetEvent("mdt:submitNewBolo")
AddEventHandler("mdt:submitNewBolo", function(data)
	local usource = source
	local fullname = exports['envyrp']:GetOnePlayerInfo(usource, 'fullname')
	if fullname then
		local author = fullname
		MySQL.Async.insert('INSERT INTO `mdt_bolos` (`title`, `plate`, `owner`, `individual`, `reason`, `officersinvolved`, `expire`, `author`) VALUES (@title, @plate, @owner, @individual, @reason, @officersinvolved, @expire, @author)', {
			['@title']  = data.title,
			['@plate']  = data.plate,
			['@owner'] = data.owner,
			['@individual'] = data.individual,
			['@reason'] = data.reason,
			['@officersinvolved'] = data.officersinvolved,
			['@expire'] = data.expire,
			['@author'] = author
		}, function()
			TriggerClientEvent("mdt:completedBoloAction", usource)
		end)
	end
end)

RegisterNetEvent("mdt:sentencePlayer")
AddEventHandler("mdt:sentencePlayer", function(jailtime, charges, char_id, fine, players)
	TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = 'Use /fine and F1 jail please.', length = 5000 })
end)

RegisterNetEvent("mdt:performReportSearch")
AddEventHandler("mdt:performReportSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `mdt_reports` WHERE `id` LIKE @query OR LOWER(`title`) LIKE @query OR LOWER(`name`) LIKE @query OR LOWER(`author`) LIKE @query or LOWER(`charges`) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			data.charges = json.decode(data.charges)
			table.insert(matches, data)
		end

		TriggerClientEvent("mdt:returnReportSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("mdt:performBoloSearch")
AddEventHandler("mdt:performBoloSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT * FROM `mdt_bolos`", {
		--['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)

		for index, data in ipairs(result) do
			table.insert(matches, data)
		end

		TriggerClientEvent("mdt:returnBoloSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("mdt:performVehicleSearch")
AddEventHandler("mdt:performVehicleSearch", function(query)
	local usource = source
	local matches = {}
	MySQL.Async.fetchAll("SELECT id, vehicle, owner, plate, vehicle_state, garage FROM `owned_vehicles` WHERE LOWER(`plate`) LIKE @query", {
		['@query'] = string.lower('%'..query..'%') -- % wildcard, needed to search for all alike results
	}, function(result)
		for index, data in ipairs(result) do
			local data_decoded = json.decode(data.vehicle)
			if data_decoded then
				data.model = data_decoded.model
				if data_decoded.color1 then
					data.color = colors[tostring(data_decoded.color1)]
					if colors[tostring(data_decoded.color2)] then
						data.color = colors[tostring(data_decoded.color2)] .. " on " .. colors[tostring(data_decoded.color1)]
					end
				end
				if #result < 50 then
					local queryPlate = data.plate
					local plate = string.gsub(queryPlate, "^%s*(.-)%s*$", "%1")
					MySQL.Async.fetchAll("SELECT * FROM `impound` WHERE plate=@plate", {['@plate'] = queryPlate}, function(resulot)
						if not resulot[1] then
							data.status = 'Not Impounded'
						else
							data.status = 'State Impounded'
						end
					end)
					while data.status == nil do Wait(0) end;
				end
				table.insert(matches, data)
			end
		end

		TriggerClientEvent("mdt:returnVehicleSearchResults", usource, matches)
	end)
end)

RegisterNetEvent("mdt:performVehicleSearchInFront")
AddEventHandler("mdt:performVehicleSearchInFront", function(query)
	local usource = source
	local xPlayer = exports['envyrp']:GetPlayerFromId(usource)
	if xPlayer then
    if (xPlayer.job.isPolice or xPlayer.job.name == 'doj' or xPlayer.job.name == 'mib') and xPlayer.job.duty == 1 then
    	MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_reports` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(reports)
    		for r = 1, #reports do
    			reports[r].charges = json.decode(reports[r].charges)
    		end
    		MySQL.Async.fetchAll("SELECT * FROM (SELECT * FROM `mdt_warrants` ORDER BY `id` DESC LIMIT 3) sub ORDER BY `id` DESC", {}, function(warrants)
    			for w = 1, #warrants do
    				warrants[w].charges = json.decode(warrants[w].charges)
    			end
    			MySQL.Async.fetchAll("SELECT * FROM `owned_vehicles` WHERE `plate` = @query", {
					['@query'] = query
				}, function(result)
					
					local officer = ""
					local jobInfo = exports['envyrp']:GetJobInfo(xPlayer.job.name)
					if jobInfo then officer = jobInfo['grades'][xPlayer.job.grade]['label']..' '..xPlayer.lastname
					else officer = xPlayer.fullname end

    			TriggerClientEvent('mdt:toggleVisibilty', usource, reports, warrants, officer)
					TriggerClientEvent("mdt:returnVehicleSearchInFront", usource, result, query)
				end)
    		end)
    	end)
		end
	end
end)

RegisterNetEvent("mdt:getVehicle")
AddEventHandler("mdt:getVehicle", function(vehicle)
	local usource = source
	MySQL.Async.fetchAll("SELECT firstname, lastname FROM `users` WHERE `id` = @query", {
		['@query'] = vehicle.owner
	}, function(result)
		if result[1] then
			local blah = vehicle.owner
			vehicle.owner = result[1].firstname .. ' ' .. result[1].lastname
			vehicle.owner_id = blah
		end

		vehicle.type = types[vehicle.type]
		TriggerClientEvent("mdt:returnVehicleDetails", usource, vehicle)
	end)
end)

RegisterNetEvent("mdt:getWarrants")
AddEventHandler("mdt:getWarrants", function()
	local usource = source
	MySQL.Async.fetchAll("SELECT * FROM `mdt_warrants`", {}, function(warrants)
		for i = 1, #warrants do
			warrants[i].expire_time = ""
			warrants[i].charges = json.decode(warrants[i].charges)
		end
		TriggerClientEvent("mdt:returnWarrants", usource, warrants)
	end)
end)

RegisterNetEvent("mdt:getBolos")
AddEventHandler("mdt:getBolos", function()
	local usource = source
	MySQL.Async.fetchAll("SELECT * FROM `mdt_bolos`", {}, function(warrants)
		for i = 1, #warrants do
			warrants[i].expire_time = ""
		end
		TriggerClientEvent("mdt:returnBolos", usource, warrants)
	end)
end)


RegisterNetEvent("mdt:submitNewWarrant")
AddEventHandler("mdt:submitNewWarrant", function(data)
	local usource = source
	data.charges = json.encode(data.charges)
	local fullname = exports['envyrp']:GetOnePlayerInfo(usource, 'fullname')
	if fullname then
		local author = fullname
		data.author = author
		data.date = os.date('%m-%d-%Y %H:%M:%S', os.time())
		MySQL.Async.insert('INSERT INTO `mdt_warrants` (`name`, `char_id`, `report_id`, `report_title`, `charges`, `date`, `expire`, `notes`, `author`) VALUES (@name, @char_id, @report_id, @report_title, @charges, @date, @expire, @notes, @author)', {
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
			TriggerClientEvent("mdt:completedWarrantAction", usource)
		end)
	end
end)

RegisterNetEvent("mdt:deleteWarrant")
AddEventHandler("mdt:deleteWarrant", function(id)
	local usource = source
	MySQL.Async.execute('DELETE FROM `mdt_warrants` WHERE `id` = @id', {
		['@id']  = id
	}, function()
		TriggerClientEvent("mdt:completedWarrantAction", usource)
	end)
end)

RegisterNetEvent("mdt:deleteBolo")
AddEventHandler("mdt:deleteBolo", function(id)
	local usource = source
	MySQL.Async.execute('DELETE FROM `mdt_bolos` WHERE `id` = @id', {
		['@id']  = id
	}, function()
		TriggerClientEvent("mdt:completedBoloAction", usource)
	end)
end)

RegisterNetEvent("mdt:getReportDetailsById")
AddEventHandler("mdt:getReportDetailsById", function(query, _source)
	if _source then source = _source end
	local usource = source
	MySQL.Async.fetchAll("SELECT * FROM `mdt_reports` WHERE `id` = @query", {
		['@query'] = query
	}, function(result)
		if result and result[1] then
			result[1].charges = json.decode(result[1].charges)
			TriggerClientEvent("mdt:returnReportDetails", usource, result[1])
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

RegisterNetEvent("mdt:unimpoundMofoka")
AddEventHandler("mdt:unimpoundMofoka", function(plate)
	local source = source
	local plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
    MySQL.Async.execute("UPDATE impound SET time=69 WHERE plate=@plate LIMIT 1", {['@plate'] = plate}, function(data)
        if data > 0 then
            TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'Vehicle impound timer removed.', length = 5000 })
        end
	end)
end)

RegisterNetEvent("erp-mdt:switchDuty")
AddEventHandler("erp-mdt:switchDuty", function()
	local src = source
	local player = exports['envyrp']:GetPlayerFromId(src)
	if player then
		local job = player.job.name
		local grade = player.job.grade
		local duty = player.job.duty

		if player.job.isPolice and duty == 1 then
			TriggerEvent('envyrp:toggleduty', src)
			TriggerClientEvent('mdt:offduty', src)
			TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = 'inform', text = 'You are now off-duty.', length = 5000, style = { ['background-color'] = '#4287f5', ['color'] = '#ffffff' } })
		elseif player.job.isPolice and duty == 0 then
			TriggerEvent('envyrp:toggleduty', src)
			TriggerEvent('mdt:hotKeyOpen', src, false)
			TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = 'inform', text = 'You are now on-duty.', length = 5000, style = { ['background-color'] = '#4287f5', ['color'] = '#ffffff' } })
		end
	end
end)