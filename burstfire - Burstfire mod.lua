if string.lower(RequiredScript) == "lib/units/weapons/newraycastweaponbase" then

	local init_original = NewRaycastWeaponBase.init
	local _update_stats_values_original = NewRaycastWeaponBase._update_stats_values
	local fire_original = NewRaycastWeaponBase.fire
	local toggle_firemode_original = NewRaycastWeaponBase.toggle_firemode
	
	function NewRaycastWeaponBase:init(...)
		init_original(self, ...)
		if not self:is_npc() then
			self._burst_mode = false
			self._burst_rounds_remaining = 0
		end
	end
	
	function NewRaycastWeaponBase:_update_stats_values(...)
		_update_stats_values_original(self, ...)
		
		if not self:is_npc() then
			local tweak = self:weapon_tweak_data()
			self._burst_size = tweak.burst_size or tweak.category == "akimbo" and 2 or 3
			self._fire_rate = tweak.fire_mode_data.fire_rate
			self._has_auto = not self._locked_fire_mode and (self:can_toggle_firemode() or tweak.FIRE_MODE == "auto") and true or false
			self._can_use_burst = not tweak.FORBIDS_BURST_FIRE and (self:can_toggle_firemode() or tweak.HAS_BURST_FIRE or tweak.category == "akimbo") and true or false
		end
	end
	
	function NewRaycastWeaponBase:fire(...)
		local result = fire_original(self, ...)
		
		if result and self:in_burst_mode() and not (self:weapon_tweak_data().category == "akimbo") then
			if self:clip_empty() then
				self._burst_rounds_remaining = 0
			else
				self._burst_rounds_remaining = (self._burst_rounds_remaining <= 0 and self._burst_size or self._burst_rounds_remaining) - 1
				self._burst_expire_t = Application:time() + self._fire_rate / self:fire_rate_multiplier() + 0.1
			end
		end
		
		return result
	end

	function NewRaycastWeaponBase:toggle_firemode(...)
		return self._can_use_burst and not self._locked_fire_mode and self:_check_toggle_burst() or toggle_firemode_original(self, ...)
	end
	
	function NewRaycastWeaponBase:_check_toggle_burst()
		if self:in_burst_mode() then
			self:_set_burst_mode(false)
			return true
		elseif (self._fire_mode == Idstring("single")) or (self._fire_mode == Idstring("auto") and not self:can_toggle_firemode()) then
			self:_set_burst_mode(true)
			return true
		end
	end

	function NewRaycastWeaponBase:_set_burst_mode(status)
		self._in_burst_mode = status
		self._fire_mode = Idstring(status and "single" or self._has_auto and "auto" or "single")
		self._sound_fire:post_event(status and "wp_auto_switch_on" or self._has_auto and "wp_auto_switch_on" or "wp_auto_switch_off")
		self:cancel_burst()
	end
	
	function NewRaycastWeaponBase:can_use_burst_burst()
		return self._can_use_burst
	end
	
	function NewRaycastWeaponBase:cancel_burst()
		self._burst_rounds_remaining = 0
	end

	function NewRaycastWeaponBase:in_burst_mode()
		return self._fire_mode == Idstring("single") and self._in_burst_mode
	end

	function NewRaycastWeaponBase:burst_rounds_remaining()
		return self._burst_rounds_remaining > 0 and self._burst_rounds_remaining or false
	end
	
	function NewRaycastWeaponBase:burst_expire_t()
		return self._burst_expire_t
	end
	
elseif string.lower(RequiredScript) == "lib/units/weapons/akimboweaponbase" then

	local reload_speed_multiplier_original = AkimboWeaponBase.reload_speed_multiplier
	local init_original = AkimboWeaponBase.init

	function AkimboWeaponBase:init(...)
		init_original(self, ...)
		
		local fire_mode_data = tweak_data.weapon[self._name_id].fire_mode_data
		if fire_mode_data then
			fire_mode_data.original_fire_rate = fire_mode_data.original_fire_rate or fire_mode_data.fire_rate
			fire_mode_data.fire_rate = fire_mode_data.original_fire_rate / 2
		end
	end

	function AkimboWeaponBase:fire(...)
		self._second_turn = not self._second_turn
		local result
		
		if not self._second_turn then
			result = AkimboWeaponBase.super.fire(self, ...)
		elseif alive(self._second_gun) then
			result = self._second_gun:base().super.fire(self._second_gun:base(), ...)
			if result then
				self._second_gun:base():_fire_sound()
				managers.hud:set_ammo_amount(self:selection_index(), self:ammo_info())
				self._second_gun:base():tweak_data_anim_play("fire")
			end
		end
		
		if result and self:in_burst_mode() then
			if self:clip_empty() then
				self._burst_rounds_remaining = 0
			else			
				self._burst_rounds_remaining = (self._burst_rounds_remaining <= 0 and self._burst_size or self._burst_rounds_remaining) - 1
				self._burst_expire_t = Application:time() + self._fire_rate / self:fire_rate_multiplier() + 0.1
			end
		end
		
		return result
	end
	
	function AkimboWeaponBase:reload_speed_multiplier(...)
		return reload_speed_multiplier_original(self, ...) * (self:get_ammo_remaining_in_clip() == self:calculate_ammo_max_per_clip() - 1 and 2 or 1)
	end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then

	local update_original = PlayerStandard.update

	function PlayerStandard:update(t, ...)
		update_original(self, t, ...)
		self:_update_burst_fire(t)
	end

	function PlayerStandard:_update_burst_fire(t)
		if alive(self._equipped_unit) then
			local wbase = self._equipped_unit:base()
			if wbase:burst_rounds_remaining() then
				if wbase:burst_expire_t() < Application:time() then
					wbase:cancel_burst()
				else
					self:_check_action_primary_attack(t, { btn_primary_attack_state = true, btn_primary_attack_press = true })
				end
			end
		end
	end
	
	--Override
	function PlayerStandard:_check_action_weapon_firemode(t, input)
		local wbase = self._equipped_unit:base()
		if input.btn_weapon_firemode_press and wbase.toggle_firemode then
			self:_check_stop_shooting()
			if wbase:toggle_firemode() then
				if wbase:in_burst_mode() then
					managers.hud:set_teammate_weapon_firemode_burst(self._unit:inventory():equipped_selection())
				else
					managers.hud:set_teammate_weapon_firemode(HUDManager.PLAYER_PANEL, self._unit:inventory():equipped_selection(), wbase:fire_mode())
				end
			end
		end
	end
	
elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	
	HUDManager._USE_BURST_MODE = true	--Custom HUD compatibility

	function HUDManager:set_teammate_weapon_firemode_burst(id)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_weapon_firemode_burst(id)
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammate" then
	
	if not HUDTeammate.set_weapon_firemode_burst then	--Custom HUD compatibility
		function HUDTeammate:set_weapon_firemode_burst(id, firemode, burst_fire)
		
			log("firemode burst entering")
			local is_secondary = id == 1
			local secondary_weapon_panel = self._player_panel:child("weapons_panel"):child("secondary_weapon_panel")
			--local primary_weapon_panel = self._player_panel:child("weapons_panel"):child("primary_weapon_panel")
			
	local primary_weapon_panel = self._player_panel:child("weapons_panel"):child("primary_weapon_panel")
	local weapon_selection = is_secondary and self._panel:child("weapon_selection_second") or self._panel:child("weapon_selection_primary")
	--		local weapon_selection = is_secondary and secondary_weapon_panel:child("weapon_selection") or primary_weapon_panel:child("weapon_selection")
			
				local firemode_single = weapon_selection:child("firemode_single")
				local firemode_auto = weapon_selection:child("firemode_auto")
				local firemode_burst = weapon_selection:child("firemode_burst")
				firemode_burst:show()
				firemode_single:hide()
				firemode_auto:hide()
			if alive(weapon_selection) then
			log("inside if 1")
				if alive(firemode_single) and alive(firemode_auto) then
					log("inside if 2")
				end
			end
		end
	end
	
end