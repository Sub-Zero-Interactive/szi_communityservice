ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterCommand('comserv', 'admin', function(xPlayer, args, showError)
	if xPlayer.job.name == 'police' then
		if args.id ~= nil and args.amount ~= nil then
			TriggerEvent('szi_communityservice:sendToCommunityService', args.id.source, args.amount)
		else
			TriggerClientEvent('chat:addMessage', xPlayer.source, { args = { _U('system_msn'), _U('invalid_player_id_or_actions') } } )
		end
	end
end, true, {help = "Sends a player to community service.", validate = true, arguments = {
	{name = "id", help = _U('target_id'), type = 'player'},
	{name = 'amount', help = "amount of comserv", type = 'number'}
}})

ESX.RegisterCommand('endcomserv', 'admin', function(xPlayer, args, showError)
	if xPlayer.job.name == 'police' then
		if args.id ~= nil then
			TriggerEvent('szi_communityservice:endCommunityServiceCommand', args.id.source)
		else
			TriggerEvent('szi_communityservice:endCommunityServiceCommand', xPlayer.source)
		end
	end
end, true, {help = "Removes a player from community service.", validate = false, arguments = {
	{name = "id", help = _U('target_id'), type = 'player'}
}})

RegisterServerEvent('szi_communityservice:endCommunityServiceCommand')
AddEventHandler('szi_communityservice:endCommunityServiceCommand', function(source)
	if source ~= nil then
		releaseFromCommunityService(source)
	end
end)

-- unjail after time served
RegisterServerEvent('szi_communityservice:finishCommunityService')
AddEventHandler('szi_communityservice:finishCommunityService', function()
	releaseFromCommunityService(source)
end)

RegisterServerEvent('szi_communityservice:completeService')
AddEventHandler('szi_communityservice:completeService', function()
	local _source = source
	local identifier = GetPlayerIdentifiers(_source)[1]

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)

		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining - 1 WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})
		else
			print ("szi_communityservice :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)

RegisterServerEvent('szi_communityservice:extendService')
AddEventHandler('szi_communityservice:extendService', function()
	local _source = source
	local identifier = GetPlayerIdentifiers(_source)[1]

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)

		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining + @extension_value WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@extension_value'] = Config.ServiceExtensionOnEscape
			})
		else
			print ("szi_communityservice :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)

RegisterServerEvent('szi_communityservice:sendToCommunityService')
AddEventHandler('szi_communityservice:sendToCommunityService', function(target, actions_count)
	local xPlayer = ESX.GetPlayerFromId(target)
	local identifier = GetPlayerIdentifiers(target)[1]

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = @actions_remaining WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count
			})
		else
			MySQL.Async.execute('INSERT INTO communityservice (identifier, actions_remaining) VALUES (@identifier, @actions_remaining)', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count
			})
		end
	end)

	TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_msg', xPlayer.getName(target), actions_count) }, color = { 147, 196, 109 } })
	TriggerClientEvent('esx_policejob:unrestrain', target)
	TriggerClientEvent('szi_communityservice:inCommunityService', target, actions_count)
end)

RegisterServerEvent('szi_communityservice:checkIfSentenced')
AddEventHandler('szi_communityservice:checkIfSentenced', function()
	local _source = source -- cannot parse source to client trigger for some weird reason
	local identifier = GetPlayerIdentifiers(_source)[1] -- get steam identifier

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] ~= nil and result[1].actions_remaining > 0 then
			TriggerClientEvent('szi_communityservice:inCommunityService', _source, tonumber(result[1].actions_remaining))
		end
	end)
end)

function releaseFromCommunityService(target)
	local xPlayer = ESX.GetPlayerFromId(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('DELETE from communityservice WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})

			TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_finished', xPlayer.getName(target)) }, color = { 147, 196, 109 } })
		end
	end)

	TriggerClientEvent('szi_communityservice:finishCommunityService', target)
end
