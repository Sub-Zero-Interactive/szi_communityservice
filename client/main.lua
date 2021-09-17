ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

local communityServiceFinished, isSentenced, disable_actions = false, false, false
local cleaning_net, gardening_net = nil, nil

local actionsRemaining = 0
local availableActions = {}

local cleaningmodel = Config.CleaningModel
local gardeningmodel = Config.GardeningModel

Citizen.CreateThread(function()
	Citizen.Wait(2000) --Wait for mysql-async
	TriggerServerEvent('szi_communityservice:checkIfSentenced')
end)

function FillActionTable(last_action)
	while #availableActions < 5 do
		local service_does_not_exist = true
		local random_selection = Config.ServiceLocations[math.random(1,#Config.ServiceLocations)]

		for i = 1, #availableActions do
			if random_selection.coords.x == availableActions[i].coords.x and random_selection.coords.y == availableActions[i].coords.y and random_selection.coords.z == availableActions[i].coords.z then
				service_does_not_exist = false
			end
		end
		if last_action ~= nil and random_selection.coords.x == last_action.coords.x and random_selection.coords.y == last_action.coords.y and random_selection.coords.z == last_action.coords.z then
			service_does_not_exist = false
		end
		if service_does_not_exist then
			table.insert(availableActions, random_selection)
		end
	end
end

RegisterNetEvent('szi_communityservice:inCommunityService')
AddEventHandler('szi_communityservice:inCommunityService', function(actions_remaining)
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local distance = #(coords - Config.ServiceLocation)

	if isSentenced then
		return
	end
	actionsRemaining = actions_remaining
	FillActionTable()
	print(":: Available Actions: " .. #availableActions)
	ApplyPrisonerSkin()
	ESX.Game.Teleport(playerPed, Config.ServiceLocation)
	isSentenced = true
	communityServiceFinished = false

	while actionsRemaining > 0 and communityServiceFinished ~= true do
		if IsPedInAnyVehicle(playerPed, false) then
			ClearPedTasksImmediately(playerPed)
		end

		Citizen.Wait(20000)

		if distance <= Config.MaxDistance then
			ESX.Game.Teleport(playerPed, Config.ServiceLocation)
			TriggerEvent('chat:addMessage', { args = { _U('judge'), _U('escape_attempt') }, color = { 147, 196, 109 } })
			TriggerServerEvent('szi_communityservice:extendService')
			actionsRemaining = actionsRemaining + Config.ServiceExtensionOnEscape
		end
	end

	TriggerServerEvent('szi_communityservice:finishCommunityService', -1)
	ESX.Game.Teleport(playerPed, Config.ReleaseLocation)
	isSentenced = false

	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:loadSkin', skin)
	end)
end)

RegisterNetEvent('szi_communityservice:finishCommunityService')
AddEventHandler('szi_communityservice:finishCommunityService', function(source)
	communityServiceFinished = true
	isSentenced = false
	actionsRemaining = 0
end)

Citizen.CreateThread(function()
	while true do
		:: start_over ::
		Citizen.Wait(1)

		if actionsRemaining > 0 and isSentenced then
			draw2dText( _U('remaining_msg', ESX.Math.Round(actionsRemaining)), { 0.175, 0.955 } )
			DrawAvailableActions()
			DisableViolentActions()

			local pCoords = GetEntityCoords(PlayerPedId())

			for i = 1, #availableActions do
				local distance = #(pCoords - availableActions[i].coords)
				if distance < 1.5 then
					DisplayHelpText(_U('press_to_start'))
					if(IsControlJustReleased(1, 38))then
						tmp_action = availableActions[i]
						RemoveAction(tmp_action)
						FillActionTable(tmp_action)
						disable_actions = true
						TriggerServerEvent('szi_communityservice:completeService')
						actionsRemaining = actionsRemaining - 1
						if (tmp_action.type == "cleaning") then
							local cSCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
							local vassouspawn = CreateObject(GetHashKey(cleaningmodel), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
							local netid = ObjToNet(vassouspawn)
							ESX.Streaming.RequestAnimDict("amb@world_human_janitor@male@idle_a", function()
									TaskPlayAnim(PlayerPedId(), "amb@world_human_janitor@male@idle_a", "idle_a", 8.0, -8.0, -1, 0, 0, false, false, false)
									AttachEntityToEntity(vassouspawn,GetPlayerPed(PlayerId()),GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422),-0.005,0.0,0.0,360.0,360.0,0.0,1,1,0,1,0,1)
									cleaning_net = netid
								end)

								ESX.SetTimeout(10000, function()
									disable_actions = false
									DetachEntity(NetToObj(cleaning_net), 1, 1)
									DeleteEntity(NetToObj(cleaning_net))
									cleaning_net = nil
									ClearPedTasks(PlayerPedId())
								end)
						end

						if (tmp_action.type == "gardening") then
							local cSCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
							local spatulaspawn = CreateObject(GetHashKey(gardeningmodel), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
							local netid = ObjToNet(spatulaspawn)

							TaskStartScenarioInPlace(PlayerPedId(), "world_human_gardener_plant", 0, false)
							AttachEntityToEntity(spatulaspawn,GetPlayerPed(PlayerId()),GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422),-0.005,0.0,0.0,190.0,190.0,-50.0,1,1,0,1,0,1)
							gardening_net = netid

							ESX.SetTimeout(14000, function()
								disable_actions = false
								DetachEntity(NetToObj(gardening_net), 1, 1)
								DeleteEntity(NetToObj(gardening_net))
								gardening_net = nil
								ClearPedTasks(PlayerPedId())
							end)
						end
						goto start_over
					end
				end
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

function RemoveAction(action)
	local action_pos = -1

	for i=1, #availableActions do
		if action.coords.x == availableActions[i].coords.x and action.coords.y == availableActions[i].coords.y and action.coords.z == availableActions[i].coords.z then
			action_pos = i
		end
	end

	if action_pos ~= -1 then
		table.remove(availableActions, action_pos)
	else
		print("User tried to remove an unavailable action")
	end
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function DrawAvailableActions()
	for i = 1, #availableActions do
		DrawMarker(21, availableActions[i].coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 50, 50, 204, 100, false, true, 2, true, false, false, false)
	end
end

function DisableViolentActions()
	local playerPed = PlayerPedId()

	if disable_actions == true then
		DisableAllControlActions(0)
	end

	RemoveAllPedWeapons(playerPed, true)

	DisableControlAction(2, 37, true) -- disable weapon wheel (Tab)
	DisablePlayerFiring(playerPed,true) -- Disables firing all together if they somehow bypass inzone Mouse Disable

	if IsDisabledControlJustPressed(2, 37) then 
		SetCurrentPedWeapon(playerPed,GetHashKey("WEAPON_UNARMED"),true) -- if tab is pressed it will set them to unarmed (this is to cover the vehicle glitch until I sort that all out)
	end

	if IsDisabledControlJustPressed(0, 106) then
		SetCurrentPedWeapon(playerPed,GetHashKey("WEAPON_UNARMED"),true) -- If they click it will set them to unarmed
	end
end

function ApplyPrisonerSkin()
	local playerPed = PlayerPedId()

	if DoesEntityExist(playerPed) then
		Citizen.CreateThread(function()
			TriggerEvent('skinchanger:getSkin', function(skin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms['prison_wear'].male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms['prison_wear'].female)
				end
			end)

		SetPedArmour(playerPed, 0)
		ClearPedBloodDamage(playerPed)
		ResetPedVisibleDamage(playerPed)
		ClearPedLastWeaponDamage(playerPed)
		ResetPedMovementClipset(playerPed, 0)

		end)
	end
end

function draw2dText(text, pos)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.45, 0.45)
	SetTextColour(255, 255, 255, 255)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(table.unpack(pos))
end