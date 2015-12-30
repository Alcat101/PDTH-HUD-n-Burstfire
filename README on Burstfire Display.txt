THIS DOC IS CREATED TO PRESERVE THE CODE ON HOW THE PDTH HUD AND BURSTFIRE LUA MOD COULD WORK TOGETHER
IN THE FORM OF PDTH HUD SHOWING THE FIREMODE HUD DISPLAY TEXT A TRUE 'BURST', INSTEAD OF A 2ND SINGLE, WHEN THE FIREMODE ARE CYCLED TO BURST.
PDTH HUD IS A MOD THAT RECREATE THE PDTH HUD LOOK IN PAYDAY 2 GAME
BURSTFIRE IS A MOD TO CREATE AN EXTRA FIREMODE WHERE IT SIMULATE A 3 ROUND RAPID SHOT AS BURST IN THE FORM OF 3 RAPID PAYDAY2-SINGLE-SHOT FUNCTION
(PDTH HUD WILL ORIGINALLY CYCLE THE FIREMODE AS AUTO -> SINGLE -> SINGLE(BURST) AND BACK AGAIN, AS IT IS ORDERED BY CUSTOM HUD COMPATIBILITY FUNCTION IN BURSTFIRE)

THANKS TO ALETHER AND FRACTALIA



--------------------------
add:
local firemode_burst = weapon_selection_panel:text({
			name = "firemode_burst",
			--texture = "guis/textures/pd2/weapons",
			--texture_rect = texture_rect,
			--x = 2,
			blend_mode = "normal",
			font = tweak_data.menu.small_font,
			font_size = 12 * pdth_hud.loaded_options.Ingame.Hud_scale,
			text = "BURST",
			align = "center",
			halign = "center",
			vertical = "bottom",
			hvertical = "bottom",
			layer = 1
		})
		firemode_burst:set_y(firemode_burst:y() - (3 * pdth_hud.loaded_options.Ingame.Hud_scale))
		firemode_burst:hide()
		
to function create_primary_weapon_firemode
and create_secondary_weapon_firemode
after the line-> local firemode_auto

this is to initialize, there are firemode burst to be later on used by PDTH Hud firemode cylcing.


-------------------------
add:
local firemode_burst = weapon_selection:child("firemode_burst")

to function HUDTeammate: set_weapon_firemode(id, firemode)
after the line-> local firemode_auto

this is to call firemode burst (after its initialized in function create_primary/secondary_weapon_firemode) in function HUDTeammate


-------------------------
add:
firemode_burst:hide()

to function HUDTeammate: set_weapon_firemode(id, firemode)
inside the if else firemode==single function
after the last firemode_auto line-

this is to hide the BURST text display on the HUD when changing firemode to AUTO or SINGLE



!=======================================================================================================!
=======================================================================================================
The latest PDTH Hud update changes the structure of the mod
So the above changes still work, albeit with more modification to make
User now must also add the above code to HudTM.lua at the Hooks folder on the PDTH mod folder.
=======================================================================================================
!=======================================================================================================!



on Burstfire.lua
===================================

change the content of 
if not HUDTeammate.set_weapon_firemode_burst then	--Custom HUD compatibility
into:
if not HUDTeammate.set_weapon_firemode_burst then	--Custom HUD compatibility
		function HUDTeammate:set_weapon_firemode_burst(id, firemode, burst_fire)
		
			
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
			-- if alive(weapon_selection) then
			-- log("inside if 1")
				-- if alive(firemode_single) and alive(firemode_auto) then
					-- log("inside if 2")
				-- end
			-- end
		end
	end
	
	
(the comment are preserved for the sake of doc)
this is for when the game cycle the firemode to burst, it will show the BURST text and hide the AUTO and SINGLE text in HUD

