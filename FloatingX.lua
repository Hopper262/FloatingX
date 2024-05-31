-- FloatingX_HUD version 1.4.1
-- by Hopper and TychoVII

-- Distance from the corners
margin_amount = 20

-- Net stats distance from the corners
net_margin_amount = 40

-- widest game aspect ratio allowed (2 == 2:1 width:height)
max_aspect_ratio = 2
-- narrowest game aspect ratio allowed
min_aspect_ratio = 1.6

-- add additional transparency to motion sensor and weapons backgrounds
-- 0 = no additional transparency, 1 = completely transparent
background_transparency = 0

-- largest scale factor for the graphics
max_scale_factor = 2.3
-- smallest scale factor for the graphics
min_scale_factor = 0.6
-- screen width at which the graphics are drawn at 1:1 scale
scale_width = 1280
-- scaling rate
scale_rate = 0.75

-- time in ticks for weapons readout to show new weapon
anim_wepscroll = 5
-- leave a buffer between old and new weapon graphics,
-- by skipping this many ticks of the old weapon scrolloff
anim_wepbuffer = 5
-- opacity for static in buffer between weapon graphics
anim_wepbuffer_static = .6
-- time in ticks for net standings row to show new player
anim_netscroll = 10
-- time in ticks for net standings rows to switch places
anim_netswap = 10

-- dim new weapons until old weapon is put away
dim_weapon = false


Triggers = {}
function Triggers.draw()
  if TexturePalette.draw() then return end
  
  -- net stats
  if #Game.players > 1 then
    local net_w = netheader.width
    local net_h = math.floor(45*scale)
    local net_x = sx + sw - net_margin_amount*scalemargin - net_w
    local net_y = sy + net_margin_amount*scalemargin
    
    local gametype = Game.type
    if gametype == "netscript" then
      gametype = Game.scoring_mode
    end
    netrow_header(net_x, net_y, net_w, net_h, gametype)
    
    local one, two = top_two()
    local ly = net_h
    local ny = 2*net_h
    local lplayer = one
    local nplayer = two
    if not one.local_ then
      ly = 2*net_h
      ny = net_h
      lplayer = two
      nplayer = one
    end
    
    netrow_nonlocal(net_x, net_y + ny, net_w, net_h, gametype, nplayer)
    netrow_local(net_x, net_y + ly, net_w, net_h, gametype, lplayer)
  end

  if Player.dead then
    wep = nil
    return
  end
      
  env_light_setup()
  
  local left_x = sx + math.floor(margin_amount*scalemargin)
  local left_y = sy + sh - left_overlay.height - math.floor(margin_amount*scalemargin)
  
  -- motion sensor
  if Player.motion_sensor.active then
    env_draw(left_underlay, left_x, left_y)
    
    if not env_damage_hide then
      env_draw_glow(grid, left_x, left_y)
      local sens_rad = 56 * scale
      local sens_brad = player[0].width
      sens_rad = sens_rad + sens_brad/2
      local sens_xcen = left_x + (85 * scale)
      local sens_ycen = left_y + (77 * scale)
      
      local compass_xoff = left_x + (47 * scale)
      local compass_yoff = left_y + (39 * scale)
      if Player.compass.nw then
        compass.crop_rect.x = 0
        compass.crop_rect.y = 0
        if Player.compass.ne then
          compass.crop_rect.width = compass.width
        else
          compass.crop_rect.width = compass.width / 2
        end
        if Player.compass.sw then
          compass.crop_rect.height = compass.height
        else
          compass.crop_rect.height = compass.height / 2
        end
        env_draw_glow(compass, compass_xoff, compass_yoff)
      elseif Player.compass.ne then
        compass.crop_rect.x = compass.width / 2
        compass.crop_rect.y = 0
        compass.crop_rect.width = compass.width / 2
        if Player.compass.se then
          compass.crop_rect.height = compass.height
        else
          compass.crop_rect.height = compass.height / 2
        end
        env_draw_glow(compass, compass_xoff + compass.width/2, compass_yoff)
      elseif Player.compass.sw then
        compass.crop_rect.x = 0
        compass.crop_rect.y = compass.height / 2
        if Player.compass.se then
          compass.crop_rect.width = compass.width
        else
          compass.crop_rect.width = compass.width / 2
        end
        compass.crop_rect.height = compass.height / 2
        env_draw_glow(compass, compass_xoff, compass_yoff + compass.height/2)
      elseif Player.compass.se then
        compass.crop_rect.x = compass.width / 2
        compass.crop_rect.y = compass.height / 2
        compass.crop_rect.width = compass.width / 2
        compass.crop_rect.height = compass.height / 2
        env_draw_glow(compass, compass_xoff + compass.width/2, compass_yoff + compass.height/2)
      end
      
      
      for i = 1,#Player.motion_sensor.blips do
        local blip = Player.motion_sensor.blips[i - 1]
        local mult = blip.distance * sens_rad / 8
        local rad = math.rad(blip.direction)
        local xoff = sens_xcen + math.cos(rad) * mult
        local yoff = sens_ycen + math.sin(rad) * mult
        
        local alpha = 1
        local int = blip.intensity
        if int > 0 then
          alpha = 1 / (int + 1)
        end
        local img = player[int]
        if blip.type == "alien" then
          img = alien[int]
        end
        if blip.type == "hostile player" then
          img = hostile[int]
        end
        img.tint_color = { 1, 1, 1, alpha }
        env_draw_glow(img, xoff - math.floor(img.width/2), yoff - math.floor(img.height/2))
      end
    end
    
    if interlace then
      interlace.crop_rect.width = math.floor(108*scale)
      interlace.crop_rect.height = math.floor(108*scale)
      env_draw_glow(interlace, left_x + math.ceil(30*scale), left_y + math.ceil(23*scale))
    end
  end

  if Player.microphone_active and (not env_damage_hide) then
    env_draw(mic, left_x, left_y)
  else
    env_draw(left_midlay, left_x, left_y)
  end
  
  -- oxygen bar
  do
    local otwo_x = left_x + (159 * scale)
    local otwo_y = left_y + (134 * scale)
    
    draw_bar(otwo, otwocap, otwo_x, otwo_y, Player.oxygen, 10800)
  end
  
  -- health bar
  do
    local life_x = left_x + (176 * scale)
    local life_y = left_y + (115 * scale)
    
    local life_amt = Player.life
    if life_amt > 0 then
      draw_bar(life1, life1cap, life_x, life_y, math.min(150, life_amt), 150)
    end
    if life_amt > 150 then
      draw_bar(life2, nil, life_x, life_y, math.min(150, life_amt - 150), 150)
    end
    if life_amt > 300 then
      draw_bar(life3, nil, life_x, life_y, math.min(150, life_amt - 300), 150)
    end
  end
  
  env_draw(left_overlay, left_x, left_y)
  
  if not Player.motion_sensor.active then
    env_draw(shield, left_x, left_y)
  end

  local right_x = sx + sw - right_underlay.width - math.floor(margin_amount*scalemargin)
  local right_y = sy + sh - right_underlay.height - math.floor(margin_amount*scalemargin)
  env_draw(right_underlay, right_x, right_y)

  if env_damage_static > 0.01 then
    wstatic[env_wstatic].tint_color = { 1, 1, 1, env_damage_static }
    env_draw_glow(wstatic[env_wstatic], right_x, right_y)
  end
  
  if (Player.items["uplink chip"].count > 0) and (not env_damage_hide) then
    env_draw_glow(chip, right_x + math.floor(321*scale), right_y + math.floor(31*scale))
  end
  
  -- ammo/weapons
  local weapon = Player.weapons.desired
  if weapon then
    if not wep then
      wep = { }
      wep[1] = { p = weapon, t = Game.ticks }
    end
    if not (wep[#wep].p == weapon) then
      wep[#wep].t = wep[#wep].t - anim_wepbuffer
      table.insert(wep, { p = weapon, t = Game.ticks })
    else
      wep[#wep].t = Game.ticks
    end
    while (Game.ticks - wep[1].t) >= (anim_wepscroll + anim_wepbuffer) do
      table.remove(wep, 1)
    end
  
    local h = right_underlay.height
    local sty = h
    local frac = h
    if anim_wepscroll > 0 then frac = h / anim_wepscroll end
    for i,v in ipairs(wep) do
      local t = Game.ticks - v.t
      local edy = math.floor(t*frac)
      if edy < sty then
        Screen.clip_rect.y = right_y + edy
        Screen.clip_rect.height = sty - edy
        draw_weapons(v.p, right_x, right_y)
      end
      sty = edy - math.floor(anim_wepbuffer*frac)
      if (anim_wepbuffer_static > 0.05) and (anim_wepbuffer > 0) then
        Screen.clip_rect.y = right_y + sty
        Screen.clip_rect.height = math.floor(anim_wepbuffer*frac)
        local img = wstatic[1 + (Game.ticks % #wstatic)]
        if img then
          img.tint_color = { 1, 1, 1, anim_wepbuffer_static }
          env_draw_glow(img, right_x, right_y)
        end
      end
    end
  
    Screen.clip_rect.y = 0
    Screen.clip_rect.height = Screen.height
  
  end
  
  if interlace then
    interlace.crop_rect.width = math.floor(332*scale)
    interlace.crop_rect.height = math.floor(104*scale)
    env_draw_glow(interlace, right_x + math.ceil(4*scale), right_y + math.ceil(29*scale))
  end
  
  env_draw(right_overlay, right_x, right_y)
    
end

function Triggers.resize()
  if TexturePalette.resize() then return end

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.x = 0
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.y = 0

  Screen.map_rect.width = Screen.width
  Screen.map_rect.x = 0
  Screen.map_rect.height = Screen.height
  Screen.map_rect.y = 0
  
  local h = math.min(Screen.height, Screen.width / min_aspect_ratio)
  local w = math.min(Screen.width, h*max_aspect_ratio)
  Screen.world_rect.width = w
  Screen.world_rect.x = (Screen.width - w)/2
  Screen.world_rect.height = h
  Screen.world_rect.y = (Screen.height - h)/2
    
  if Screen.map_overlay_active then
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
  end

  sx = Screen.world_rect.x
  sy = Screen.world_rect.y
  sw = Screen.world_rect.width
  sh = Screen.world_rect.height

  scalemargin = 1 + (sw - scale_width)*scale_rate/scale_width

  scale = math.min(max_scale_factor, math.max(min_scale_factor, scalemargin))

  rescale(left_overlay)
  rescale(left_midlay)
  rescale(left_underlay)
  rescale(grid)
  rescale(compass)
  rescale(alien[0])
  rescale(player[0])
  rescale(hostile[0])
  rescale(life1)
  rescale(life1cap)
  rescale(life2)
  rescale(life2cap)
  rescale(life3)
  rescale(life3cap)
  rescale(otwo)
  rescale(otwocap)
  rescale(mic)
  rescale(shield)
  rescale(right_underlay)
  rescale(right_overlay)
  rescale(chip)
  
  for k in pairs(ammo) do
    rescale(ammo[k])
  end
  for k in pairs(weapons) do
    rescale(weapons[k])
  end
  for k in pairs(wstatic) do
    rescale(wstatic[k])
  end
  
  if not opengl then
    for i = 1,5 do
      rescale(alien[i])
      rescale(player[i])
      rescale(hostile[i])
    end
    for k in pairs(ammo_disabled) do
      rescale(ammo_disabled[k])
    end
    for k in pairs(weapons_disabled) do
      rescale(weapons_disabled[k])
    end
  end
  
  if interlace then
    interlace.tint_color = { 1, 1, 1, math.min(1, scale) }
  end
  
  rescale(netheader)
  for k in pairs(netplayers) do
    rescale(netplayers[k])
  end
  for k in pairs(netteams) do
    rescale(netteams[k])
  end
    
  bgf = Fonts.new{file = "squarishsans/Squarish Sans CT Regular SC.ttf", size = (20*scale), style = 0}
  netf = Fonts.new{file = "squarishsans/Squarish Sans CT Regular SC.ttf", size = (18*scale), style = 0}

  local th = math.max(320, math.floor(sh - 192*scale))
  local tw = math.max(640, sw)
  h = math.min(tw / 2, th)
  w = h*2
  Screen.term_rect.width = w
  Screen.term_rect.x = sx + (sw - w)/2
  Screen.term_rect.height = h
  Screen.term_rect.y = sy + (th - h)/2
  
end

function Triggers.init()
  
  -- align weapon and item mnemonics
  ItemTypes["knife"].mnemonic = "fist"

  opengl = false
  if Screen.renderer == "opengl" then
    opengl = true
  end
  
  left_overlay = Images.new{path = "resources/HUD_Left_Elements/health-oxygen_glass.png"}
  left_midlay = Images.new{path = "resources/HUD_Left_Elements/background_left.png"}
  left_underlay = Images.new{path = "resources/HUD_Left_Elements/background_radar.png"}
  if left_underlay then
    left_underlay.tint_color = { 1, 1, 1, 1 - background_transparency }
  end
  grid = Images.new{path = "resources/HUD_Left_Elements/background_radar_detail.png"}
  compass = Images.new{path = "resources/HUD_Left_Elements/objective_circle.png"}
  
  alien = { }
  alien[0] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy.png"}
  if opengl then
    alien[1] = alien[0]
    alien[2] = alien[0]
    alien[3] = alien[0]
    alien[4] = alien[0]
    alien[5] = alien[0]
  else
    alien[1] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy_fade1.png"}
    alien[2] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy_fade2.png"}
    alien[3] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy_fade3.png"}
    alien[4] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy_fade4.png"}
    alien[5] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy_fade5.png"}
  end
  player = { }
  player[0] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player.png"}
  if opengl then
    player[1] = player[0]
    player[2] = player[0]
    player[3] = player[0]
    player[4] = player[0]
    player[5] = player[0]
  else
    player[1] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player_fade1.png"}
    player[2] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player_fade2.png"}
    player[3] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player_fade3.png"}
    player[4] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player_fade4.png"}
    player[5] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_player_fade5.png"}
  end
  
  hostile = { }
  hostile[0] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player.png"}
  if opengl then
    hostile[1] = hostile[0]
    hostile[2] = hostile[0]
    hostile[3] = hostile[0]
    hostile[4] = hostile[0]
    hostile[5] = hostile[0]
  else
    hostile[1] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player_fade1.png"}
    hostile[2] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player_fade2.png"}
    hostile[3] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player_fade3.png"}
    hostile[4] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player_fade4.png"}
    hostile[5] = Images.new{path = "resources/HUD_Left_Elements/radar_blip_enemy-player_fade5.png"}
  end

  life1 = Images.new{path = "resources/HUD_Left_Elements/health1_body.png"}
  life1cap = Images.new{path = "resources/HUD_Left_Elements/health1_cap.png"}
  life2 = Images.new{path = "resources/HUD_Left_Elements/health2_body.png"}
  life2cap = Images.new{path = "resources/HUD_Left_Elements/health2_cap.png"}
  life3 = Images.new{path = "resources/HUD_Left_Elements/health3_body.png"}
  life3cap = Images.new{path = "resources/HUD_Left_Elements/health3_cap.png"}
  otwo = Images.new{path = "resources/HUD_Left_Elements/oxygen_body.png"}
  otwocap = Images.new{path = "resources/HUD_Left_Elements/oxygen_cap.png"}

  mic = Images.new{path = "resources/HUD_Left_Elements/microphone_ON.png"}
  shield = Images.new{path = "resources/HUD_Left_Elements/radar_shield.png"}
  
  right_underlay = Images.new{path = "resources/HUD_Right_Elements/weapons_readout_background.png"}
  if right_underlay then
    right_underlay.tint_color = { 1, 1, 1, 1 - background_transparency }
  end
  right_overlay = Images.new{path = "resources/HUD_Right_Elements/background_right.png"}
  chip = Images.new{path = "resources/HUD_Right_Elements/data_disk.png"}
  
  ammo = { }
  ammo["energy box"] = Images.new{path = "resources/HUD_Right_Elements/ammo_energy_container.png"}
  ammo["energy ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_energy_filler.png"}  
  ammo["shotgun ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_shotgun_shell.png"}  
  ammo["pistol ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_magnum_bullet.png"}  
  ammo["smg ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_smg_bullet.png"}  
  ammo["assault rifle ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_ar_bullet.png"}  
  ammo["assault rifle grenades"] = Images.new{path = "resources/HUD_Right_Elements/ammo_ar_grenade.png"}  
  ammo["missile launcher ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_spnkr_rocket.png"}
  
  ammo_disabled = { }
  if not opengl then
    ammo_disabled["shotgun ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_shotgun_shell_empty.png"}  
    ammo_disabled["pistol ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_magnum_bullet_empty.png"}  
    ammo_disabled["smg ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_smg_bullet_empty.png"}  
    ammo_disabled["assault rifle ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_ar_bullet_empty.png"}  
    ammo_disabled["assault rifle grenades"] = Images.new{path = "resources/HUD_Right_Elements/ammo_ar_grenade_empty.png"}  
    ammo_disabled["missile launcher ammo"] = Images.new{path = "resources/HUD_Right_Elements/ammo_spnkr_rocket_empty.png"}
  end
  
  weapons = { }
  weapons["fist"] = Images.new{path = "resources/HUD_Right_Elements/weapon_fist_right.png"}
  weapons["fist2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_fist_left.png"}
  weapons["flamethrower"] = Images.new{path = "resources/HUD_Right_Elements/weapon_flamethrower.png"}
  weapons["pistol"] = Images.new{path = "resources/HUD_Right_Elements/weapon_magnum_right.png"}
  weapons["pistol2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_magnum_left.png"}
  weapons["shotgun"] = Images.new{path = "resources/HUD_Right_Elements/weapon_shotgun_front.png"}
  weapons["shotgun2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_shotgun_back.png"}
  weapons["smg"] = Images.new{path = "resources/HUD_Right_Elements/weapon_smg.png"}
  weapons["assault rifle"] = Images.new{path = "resources/HUD_Right_Elements/weapon_ar.png"}
  weapons["fusion pistol"] = Images.new{path = "resources/HUD_Right_Elements/weapon_fusionpistol.png"}  
  weapons["missile launcher"] = Images.new{path = "resources/HUD_Right_Elements/weapon_spnkr.png"}
  weapons["alien weapon"] = Images.new{path = "resources/HUD_Right_Elements/weapon_alien.png"}
  
  weapons_disabled = { }
  if not opengl then
    weapons_disabled["fist"] = Images.new{path = "resources/HUD_Right_Elements/weapon_fist_right_empty.png"}
    weapons_disabled["fist2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_fist_left_empty.png"}
    weapons_disabled["pistol"] = Images.new{path = "resources/HUD_Right_Elements/weapon_magnum_right_empty.png"}
    weapons_disabled["pistol2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_magnum_left_empty.png"}
    weapons_disabled["shotgun"] = Images.new{path = "resources/HUD_Right_Elements/weapon_shotgun_front_empty.png"}
    weapons_disabled["shotgun2"] = Images.new{path = "resources/HUD_Right_Elements/weapon_shotgun_back_empty.png"}
  end
  
  
  wstatic = { }
  wstatic[1] = Images.new{path = "resources/HUD_Right_Elements/static1.png"}
  wstatic[2] = Images.new{path = "resources/HUD_Right_Elements/static2.png"}
  wstatic[3] = Images.new{path = "resources/HUD_Right_Elements/static3.png"}
  wstatic[4] = Images.new{path = "resources/HUD_Right_Elements/static4.png"}
  wstatic[5] = Images.new{path = "resources/HUD_Right_Elements/static5.png"}
  wstatic[6] = Images.new{path = "resources/HUD_Right_Elements/static6.png"}
  wstatic[7] = wstatic[5]
  wstatic[8] = wstatic[4]
  wstatic[9] = wstatic[3]
  wstatic[10] = wstatic[2]
  
  env_wstatic = 1
  alien_wstatic = 1
  alien_wstatic2 = 1

  interlace = Images.new{path = "resources/interlace.png"}
  
  netheader = Images.new{path = "resources/HUD_Netstats/backdrop_black.png"}
  
  netplayers = { }
  netplayers["blue"] = Images.new{path = "resources/HUD_Netstats/backdrop_blue.png"}
  netplayers["green"] = Images.new{path = "resources/HUD_Netstats/backdrop_green.png"}
  netplayers["orange"] = Images.new{path = "resources/HUD_Netstats/backdrop_orange.png"}
  netplayers["red"] = Images.new{path = "resources/HUD_Netstats/backdrop_red.png"}
  netplayers["slate"] = Images.new{path = "resources/HUD_Netstats/backdrop_slate.png"}
  netplayers["violet"] = Images.new{path = "resources/HUD_Netstats/backdrop_violet.png"}
  netplayers["white"] = Images.new{path = "resources/HUD_Netstats/backdrop_white.png"}
  netplayers["yellow"] = Images.new{path = "resources/HUD_Netstats/backdrop_yellow.png"}
    
  netteams = { }
  netteams["blue"] = Images.new{path = "resources/HUD_Netstats/team_blue.png"}
  netteams["green"] = Images.new{path = "resources/HUD_Netstats/team_green.png"}
  netteams["orange"] = Images.new{path = "resources/HUD_Netstats/team_orange.png"}
  netteams["red"] = Images.new{path = "resources/HUD_Netstats/team_red.png"}
  netteams["slate"] = Images.new{path = "resources/HUD_Netstats/team_slate.png"}
  netteams["violet"] = Images.new{path = "resources/HUD_Netstats/team_violet.png"}
  netteams["white"] = Images.new{path = "resources/HUD_Netstats/team_white.png"}
  netteams["yellow"] = Images.new{path = "resources/HUD_Netstats/team_yellow.png"}
    
  Triggers.resize()
end

function rescale(img)
  if not img then return end
  local w = math.max(1, math.floor(img.unscaled_width * scale))
  local h = math.max(1, math.floor(img.unscaled_height * scale))
  img:rescale(w, h)
end

function draw_weapons(weapon, right_x, right_y)
  if not weapon then return end
  if env_damage_hide then return end
  local wp = weapon.primary
  local ws = weapon.secondary
  local primary_ammo = nil
  local secondary_ammo = nil
  
  if wp and wp.ammo_type then
    primary_ammo = wp.ammo_type
  end
  
  if ws and ws.ammo_type then
    secondary_ammo = ws.ammo_type
    if secondary_ammo == primary_ammo then
      if Player.items[weapon.type.mnemonic].count < 2 then
        secondary_ammo = nil
        ws = nil
      end
    end
  end
  
  local force_primary = false
  local force_secondary = false
  if not dim_weapon then
    if not (weapon == Player.weapons.current) then
      if (wp and wp.rounds > 0) or (primary_ammo and Player.items[primary_ammo].count > 0) then
        force_primary = true
      elseif ws and ws.rounds > 0 then
        force_secondary = true
      end
    end
  end
  
  local item = nil
  if primary_ammo then
    item = Player.items[primary_ammo]
  end
  local item2 = nil
  if secondary_ammo then
    item2 = Player.items[secondary_ammo]
  end
  
  local img = player
  local img2 = player
  
  img = weapons[weapon.type.mnemonic]
  if img then
    if wp.weapon_drawn or force_primary then
      img.tint_color = { 1, 1, 1, 1 }
    else
      if weapons_disabled[weapon.type.mnemonic] then
        img = weapons_disabled[weapon.type.mnemonic]
      end
      img.tint_color = { 1, 1, 1, 0.35 }
    end
    env_draw_glow(img, right_x, right_y)
  end
  
  if primary_ammo == secondary_ammo then
    img2 = weapons[weapon.type.mnemonic .. "2"]
    if img2 and (ws or force_secondary) then
      if ws.weapon_drawn or force_secondary then
        img2.tint_color = { 1, 1, 1, 1 }
      else
        if weapons_disabled[weapon.type.mnemonic .. "2"] then
          img2 = weapons_disabled[weapon.type.mnemonic .. "2"]
        end
        img2.tint_color = { 1, 1, 1, 0.35 }
      end
      env_draw_glow(img2, right_x, right_y)
    end
  end
  
  local bullet = nil
  if primary_ammo then
    bullet = primary_ammo.mnemonic
  end
  local bullet2 = nil
  if secondary_ammo then
    bullet2 = secondary_ammo.mnemonic
  end
  
  
  if weapon.type == "pistol" then
    draw_bullet(bullet, right_x, right_y, 208, 104, wp.rounds, wp.total_rounds, true)
    if ws then
      draw_bullet(bullet2, right_x, right_y, 75, 104, ws.rounds, ws.total_rounds)
    end
    if secondary_ammo then
      draw_reserve(item, right_x, right_y, 170, 102)
    else
      draw_reserve(item, right_x, right_y, 40, 102)
    end
  elseif weapon.type == "shotgun" then
    draw_bullet(bullet, right_x, right_y, 184, 104, wp.rounds, 1)
    if ws then
      draw_bullet(bullet2, right_x, right_y, 126, 104, ws.rounds, 1)
    end
    draw_reserve(item, right_x, right_y, 40, 102)
  elseif weapon.type == "fusion pistol" then
    draw_energy(right_x, right_y, 75, 43, wp.rounds, wp.total_rounds)
    draw_reserve(item, right_x, right_y, 40, 102)
  elseif weapon.type == "flamethrower" then
    draw_energy(right_x, right_y, 75, 43, wp.rounds, wp.total_rounds)
    draw_reserve(item, right_x, right_y, 40, 102)
  elseif weapon.type == "missile launcher" then
    draw_bullet(bullet, right_x, right_y, 18, 45, wp.rounds, wp.total_rounds)
    draw_reserve(item, right_x, right_y, 110, 102)
  elseif weapon.type == "assault rifle" then
    local r = math.floor(16 * scale) / scale
    draw_bullet(bullet, right_x, right_y, 13, 36, wp.rounds, 13)
    draw_bullet(bullet, right_x, right_y, 13, 36 + r, wp.rounds - 13, 13)
    draw_bullet(bullet, right_x, right_y, 13, 36 + 2*r, wp.rounds - 26, 13)
    draw_bullet(bullet, right_x, right_y, 13, 36 + 3*r, wp.rounds - 39, 13)
    draw_bullet(bullet2, right_x, right_y, 11, 110, ws.rounds, ws.total_rounds)
    draw_reserve(item,  right_x, right_y, 110, 88)
    draw_reserve(item2, right_x, right_y, 110, 106)
  elseif weapon.type == "smg" then
    local r = math.floor(15 * scale) / scale
    draw_bullet(bullet, right_x, right_y, 65, 43, wp.rounds, 8)
    draw_bullet(bullet, right_x, right_y, 65, 43 + r, wp.rounds - 8, 8)
    draw_bullet(bullet, right_x, right_y, 65, 43 + 2*r, wp.rounds - 16, 8)
    draw_bullet(bullet, right_x, right_y, 65, 43 + 3*r, wp.rounds - 24, 8)
    draw_reserve(item, right_x, right_y, 40, 102)
  elseif weapon.type == "alien weapon" then
    if opengl then
      if math.random() < 0.6 then
        alien_wstatic = math.random(6)
      end
      wstatic[alien_wstatic].tint_color = { 1, 1, 1, 0.2 }
      env_draw_glow(wstatic[alien_wstatic], right_x, right_y)
      if math.random() < 0.6 then
        alien_wstatic2 = math.random(6)
      end
      wstatic[alien_wstatic2].tint_color = { 1, 1, 1, 0.1 }
      env_draw_glow(wstatic[alien_wstatic2], right_x, right_y)
    end
  end
end

function draw_bar(bar, cap, x, y, cur, max)
  if cur == max then
    -- draw completely full bar, cap is ignored
    bar.crop_rect.width = bar.width
    env_draw_halfglow(bar, x, y)
  elseif cur > 0 then
    local w = math.floor(bar.width * cur / max)
    if not cap then
      -- if no cap, just crop bar directly
      bar.crop_rect.width = w
      env_draw_halfglow(bar, x, y)
    elseif w >= cap.width*2 then
      -- add cap onto end of cropped bar
      bar.crop_rect.width = w - cap.width
      env_draw_halfglow(bar, x, y)
      cap.crop_rect.width = cap.width
      cap.crop_rect.x = 0
      env_draw_halfglow(cap, x + w - cap.width, y)
    else
      -- crop both bar and cap equally
      local lh = math.floor(w / 2)
      local rh = w - lh
      if lh then
        bar.crop_rect.width = lh
        env_draw_halfglow(bar, x, y)
      end
      cap.crop_rect.width = rh
      cap.crop_rect.x = cap.width - rh
      env_draw_halfglow(cap, x + lh, y)
    end
  end
end

function draw_energy(xstart, ystart, xoff, yoff, cur, max)
  local box = ammo["energy box"]
  if not box then return end
  
  local x = xstart + xoff*scale
  local y = ystart + yoff*scale
  env_draw_glow(box, x, y)
  
  if cur <= 0 then return end
  local fill = ammo["energy ammo"]
  if not fill then return end
  
  local w = box.width
  local h = box.height
  if cur == max then
    fill:rescale(w, h)
  else
    local fh = math.floor(h * cur / max)
    if fh <= 0 then return end
    fill:rescale(w, fh)
  end
  env_draw_glow(fill, x, y + h - fill.height)
end

function draw_bullet(item, xstart, ystart, xoff, yoff, cur, max, reverse)
  local img_act = ammo[item]
  if not img_act then return end
  local img_dis = ammo_disabled[item]
  if not img_dis then img_dis = img_act end
  local x = xstart + xoff*scale
  local y = ystart + yoff*scale
  for i = 1,max do
    local active = false
    local img = nil
    if reverse and (i > (max - cur)) then
      active = true
    elseif (not reverse) and (i <= cur) then
      active = true
    end
    if active then
      img = img_act
      img.tint_color = { 1, 1, 1, 1 }
    else
      img = img_dis
      img.tint_color = { 1, 1, 1, 0.35 }
    end
    env_draw_glow(img, x, y)
    x = x + img.width
  end
end

function draw_reserve(item, xstart, ystart, xoff, yoff)
  if not item then return end
  local txt = item.count .. "x"
  local tw, th = bgf:measure_text(txt)
  bgf:draw_text(txt,
                xstart + xoff*scale - tw/2,
                ystart + yoff*scale,
                env_adjust_glow({ 0.25, 1, 0.1, 1 }))
end

function env_light_setup()
  local ambient = Lighting.ambient_light
  local weapon = Lighting.weapon_flash
  local combined = math.min(1, ambient*2 + weapon)
  if weapon > ambient then
    combined = math.min(1, weapon*2 + ambient)
  end
  env_level = 0.5 + combined/2
  env_level_glow = 1 -- 0.75 + combined/4
  env_level_halfglow = 0.67 + combined/3
  
  env_color = nil
  env_color_glow = nil
  env_color_halfglow = nil
  if Lighting.liquid_fader.active and (Lighting.liquid_fader.type == "soft tint") then
    env_color = Lighting.liquid_fader.color
    env_color.a = env_color.a*0.67
    env_level = env_level * (1 - env_color.a)
    env_color.r = env_color.r * env_color.a
    env_color.g = env_color.g * env_color.a
    env_color.b = env_color.b * env_color.a
    
    env_color_glow = Lighting.liquid_fader.color
    env_color_glow.a = env_color_glow.a*0.33
    env_level_glow = env_level_glow * (1 - env_color_glow.a)
    env_color_glow.r = env_color_glow.r * env_color_glow.a
    env_color_glow.g = env_color_glow.g * env_color_glow.a
    env_color_glow.b = env_color_glow.b * env_color_glow.a

    env_color_halfglow = Lighting.liquid_fader.color
    env_color_halfglow.a = env_color_halfglow.a*0.5
    env_level_halfglow = env_level_halfglow * (1 - env_color_halfglow.a)
    env_color_halfglow.r = env_color_halfglow.r * env_color_halfglow.a
    env_color_halfglow.g = env_color_halfglow.g * env_color_halfglow.a
    env_color_halfglow.b = env_color_halfglow.b * env_color_halfglow.a
  end
  
  env_damage_hide = false
  env_damage_static = 0
  if Lighting.damage_fader.active then
    local dcolor = Lighting.damage_fader.color
    local dtype = Lighting.damage_fader.type.mnemonic
    
    if not ((dtype == "tint") and (dcolor.r == 0) and (dcolor.g == 1) and (dcolor.b == 0)) then
    
      env_wstatic = env_wstatic + 1
      if not wstatic[env_wstatic] then
        env_wstatic = 1
      end
      
      if (dtype == "tint") or (dtype == "soft tint") then
        env_damage_static = math.min(1, dcolor.a*1.3)
        if math.random() < (dcolor.a) then
          env_damage_hide = true
        end
      elseif (dtype == "negate") then
        env_damage_static = math.min(1, dcolor.a*1.3)
        if math.random() < (dcolor.a*1.5) then
          env_damage_hide = true
        end
      elseif (dtype == "dodge") or (dtype == "burn") then
        env_damage_static = dcolor.a*dcolor.a
        if math.random() < (dcolor.a/3) then
          env_damage_hide = true
        end
      elseif (dtype == "randomize") then
        env_damage_static = math.min(1, dcolor.a*2)
        if math.random() < (dcolor.a*3) then
          env_damage_hide = true
        end
      end
    
    end
  end
end

function env_draw(img, x, y)
  if not img then return end
  tint_color = img.tint_color
  img.tint_color = env_adjust({ tint_color.r, tint_color.g, tint_color.b, tint_color.a })
  if img.tint_color.a > 0.01 then
    img:draw(x, y)
  end
  img.tint_color = tint_color
end
function env_draw_glow(img, x, y)
  if not img then return end
  tint_color = img.tint_color
  img.tint_color = env_adjust_glow({ tint_color.r, tint_color.g, tint_color.b, tint_color.a })
  if img.tint_color.a > 0.01 then
    img:draw(x, y)
  end
  img.tint_color = tint_color
end
function env_draw_halfglow(img, x, y)
  if not img then return end
  tint_color = img.tint_color
  img.tint_color = env_adjust_halfglow({ tint_color.r, tint_color.g, tint_color.b, tint_color.a })
  if img.tint_color.a > 0.01 then
    img:draw(x, y)
  end
  img.tint_color = tint_color
end

function env_adjust(color)
  color[1] = color[1] * env_level
  color[2] = color[2] * env_level
  color[3] = color[3] * env_level
  if env_color then
    color[1] = color[1] + env_color.r
    color[2] = color[2] + env_color.g
    color[3] = color[3] + env_color.b
  end
  return color
end

function env_adjust_glow(color)
  color[1] = color[1] * env_level_glow
  color[2] = color[2] * env_level_glow
  color[3] = color[3] * env_level_glow
  if env_color_glow then
    color[1] = color[1] + env_color_glow.r
    color[2] = color[2] + env_color_glow.g
    color[3] = color[3] + env_color_glow.b
  end
  return color
end

function env_adjust_halfglow(color)
  color[1] = color[1] * env_level_halfglow
  color[2] = color[2] * env_level_halfglow
  color[3] = color[3] * env_level_halfglow
  if env_color_halfglow then
    color[1] = color[1] + env_color_halfglow.r
    color[2] = color[2] + env_color_halfglow.g
    color[3] = color[3] + env_color_halfglow.b
  end
  return color
end

function format_time(ticks)
   local secs = math.ceil(ticks / 30)
   return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function net_gamename(gametype)
  if not gamename then
    gamename = { }
    gamename["kill monsters"] = "EMFH"
    gamename["cooperative play"] = "Co-op"
    gamename["capture the flag"] = "CTF"
    gamename["king of the hill"] = "KOTH"
    gamename["kill the man with the ball"] = "KTMWTB"
    gamename["rugby"] = "Rugby"
    gamename["tag"] = "Tag"
    gamename["defense"] = "Defense"
    
    gamename["most points"] = "Netscript"
    gamename["least points"] = "Netscript"
    gamename["most time"] = "Netscript"
    gamename["least time"] = "Netscript"
  end
  
  return gamename[gametype.mnemonic]
end

function net_gamelimit()
  if Game.time_remaining then
    return format_time(Game.time_remaining)
  end
  if Game.kill_limit then
    local max_kills = 0
    for i = 1,#Game.players do
      max_kills = math.max(max_kills, Game.players[i - 1].kills)
    end
    return string.format("%d", Game.kill_limit - max_kills)
  end
  return nil
end

function ranking_text(gametype, ranking)
  if (gametype == "kill monsters") or
     (gametype == "capture the flag") or
     (gametype == "rugby") or
     (gametype == "most points") then
    return string.format("%d", ranking)
  end
  if (gametype == "least points") then
    return string.format("%d", -ranking)
  end
  if (gametype == "cooperative play") then
    return string.format("%d%%", ranking)
  end
  if (gametype == "most time") or
     (gametype == "least time") or
     (gametype == "king of the hill") or
     (gametype == "kill the man with the ball") or
     (gametype == "defense") or
     (gametype == "tag") then
    return format_time(math.abs(ranking))
  end
  
  -- unknown
  return nil
end

function comp_player(a, b)
  if a.ranking > b.ranking then
    return true
  end
  if a.ranking < b.ranking then
    return false
  end
  if a.name < b.name then
    return true
  end
  return false
end

function sorted_players()
  local tbl = {}
  for i = 1,#Game.players do
    table.insert(tbl, Game.players[i - 1])
  end
  table.sort(tbl, comp_player)
  return tbl
end

function top_two()
  local tbl = sorted_players()
  local one = tbl[1]
  local two = tbl[2]
  local i = 2
  while (not one.local_) and two and (not two.local_) do
    i = i + 1
    two = tbl[i]
  end
  return one, two
end

function netrow_header(x, y, w, h, gametype)
  netheader:draw(x, y + 14*scale)
  local lt = net_gamename(gametype)
  local rt = net_gamelimit()
  if lt and rt then
    lt = lt .. ":"
  end
  netrow_text(x, y, w, h, lt, rt)
end

function netrow_player(x, y, w, h, gametype, player)
  if not player then return end
  
  local img = netplayers[player.color.mnemonic]
  img:draw(x, y + 8*scale)
  netteams[player.team.mnemonic]:draw(x + img.width, y + 8*scale)
  netrow_text(x, y, w, h, player.name, ranking_text(gametype, player.ranking))
end

function netrow_text(x, y, w, h, left_text, right_text)
  if left_text then
    local lw, lh = netf:measure_text(left_text)
    local lx = x + 60*scale
    local ly = math.floor(y + (h - lh)/2) - 2
    netf:draw_text(left_text, lx, ly, { 1, 1, 1, 1 })
  end
  if right_text then
    local lw, lh = netf:measure_text(right_text)
    local lx = x + (w - lw) - 30*scale
    local ly = math.floor(y + (h - lh)/2) - 2
    netf:draw_text(right_text, lx, ly, { 1, 1, 1, 1 })
  end
end

function netrow_local(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not netlocaly then
    netlocaly = target_y
  end
  local y = target_y
  if y > (netlocaly + frac) then
    y = netlocaly + frac
  elseif y < (netlocaly - frac) then
    y = netlocaly - frac
  end
  netlocaly = y
  netrow_player(x, y, w, h, gametype, player)
end

function netrow_nonlocal(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not nonlocaly then
    nonlocaly = target_y
  end
  local y = target_y
  if y > (nonlocaly + frac) then
    y = nonlocaly + frac
  elseif y < (nonlocaly - frac) then
    y = nonlocaly - frac
  end
  nonlocaly = y
  
  -- update player list for animation
  if not nonlocalp then
    nonlocalp = { }
    nonlocalp[1] = { p = player, t = Game.ticks }
  end
  if not (nonlocalp[#nonlocalp].p == player) then
    table.insert(nonlocalp, { p = player, t = Game.ticks })
  else
    nonlocalp[#nonlocalp].t = Game.ticks
  end
  while (Game.ticks - nonlocalp[1].t) >= anim_netscroll do
    table.remove(nonlocalp, 1)
  end

  local sty = 0
  frac = h
  if anim_netscroll > 0 then frac = h/anim_netscroll end
  for i,v in ipairs(nonlocalp) do
    local t = Game.ticks - v.t
    local edy = math.floor(h - t*frac)

    Screen.clip_rect.y = y + sty
    Screen.clip_rect.height = edy - sty

    netrow_player(x, y, w, h, gametype, v.p)
    
    sty = edy
  end

  Screen.clip_rect.y = 0
  Screen.clip_rect.height = Screen.height
end


-- BEGIN texture palette utility
--
-- Use: in Triggers.draw: "if TexturePalette.draw() then return end"
--    in Triggers.resize: "if TexturePalette.resize() then return end"

TexturePalette = {}
TexturePalette.active = false

function TexturePalette.check_active()
  local old_active = TexturePalette.active
  local new_active = false
  if Player.texture_palette.size > 0 then new_active = true end
  TexturePalette.active = new_active
  
  if old_active and not new_active then
    Screen.crosshairs.lua_hud = TexturePalette.saved_crosshairs_lua_hud
    Triggers.resize()
  elseif new_active and not old_active then
    TexturePalette.palette_cache = {}
    TexturePalette.saved_crosshairs_lua_hud = Screen.crosshairs.lua_hud
    Screen.crosshairs.lua_hud = false
    TexturePalette.resize()
  end
  return TexturePalette.active
end

function TexturePalette.get_shape(slot)
  local key = string.format("%d %d", slot.collection, slot.texture_index)
  local shp = TexturePalette.palette_cache[key]
  if not shp then
    shp = Shapes.new{collection = slot.collection, texture_index = slot.texture_index, type = slot.type}
    TexturePalette.palette_cache[key] = shp
  end
  return shp
end

function TexturePalette.draw_shape(slot, x, y, size)
  local shp = TexturePalette.get_shape(slot)
  if not shp then return end
  if shp.width > shp.height then
    shp:rescale(size, shp.unscaled_height * size / shp.unscaled_width)
    shp:draw(x, y + (size - shp.height)/2)
  else
    shp:rescale(shp.unscaled_width * size / shp.unscaled_height, size)
    shp:draw(x + (size - shp.width)/2, y)
  end
end

function TexturePalette.draw(hr)
  if not TexturePalette.check_active() then return false end
  
  local hr = TexturePalette.hud_rect
  local tcount = Player.texture_palette.size
  local size
  if     tcount <=   5 then size = 128
  elseif tcount <=  16 then size =  80
  elseif tcount <=  36 then size =  53
  elseif tcount <=  64 then size =  40
  elseif tcount <= 100 then size =  32
  elseif tcount <= 144 then size =  26
  else                      size =  20
  end
  size = size * hr.scale
  
  local rows = math.floor(hr.height/size)
  local cols = math.floor(hr.width/size)
  local x_offset = hr.x + (hr.width - cols * size)/2
  local y_offset = hr.y + (hr.height - rows * size)/2
  
  for i = 0,tcount - 1 do
    TexturePalette.draw_shape(
      Player.texture_palette.slots[i],
      (i % cols) * size + x_offset + hr.scale/2,
      math.floor(i / cols) * size + y_offset + hr.scale/2,
      size - hr.scale)
  end
  
  if Player.texture_palette.highlight then
    local i = Player.texture_palette.highlight
    Screen.frame_rect(
      (i % cols) * size + x_offset,
      math.floor(i / cols) * size + y_offset,
      size, size,
      InterfaceColors["inventory text"],
      hr.scale)
  end
  
  return true
end

function TexturePalette.resize()
  if not TexturePalette.check_active() then return false end
  
  local ww = Screen.width
  local wh = Screen.height
  
  -- calculate HUD area
  TexturePalette.hud_rect = {}
  local hudsize = Screen.hud_size_preference
  TexturePalette.hud_rect.width = 640
  if hudsize == SizePreferences["double"] then
    if wh >= 960 and ww >= 1280 then
      TexturePalette.hud_rect.width = 1280
    end
  elseif hudsize == SizePreferences["largest"] then
    TexturePalette.hud_rect.width = math.min(ww, math.max(640, (4 * wh) / 3));
  end
  
  TexturePalette.hud_rect.height = TexturePalette.hud_rect.width / 4
  TexturePalette.hud_rect.x = math.floor((ww - TexturePalette.hud_rect.width) / 2)
  TexturePalette.hud_rect.y = math.floor(wh - TexturePalette.hud_rect.height)
  
  TexturePalette.hud_rect.scale = TexturePalette.hud_rect.width / 640

  -- remove HUD height from rest of calculations
  wh = TexturePalette.hud_rect.y
  
  -- calculate terminal area
  local termsize = Screen.term_size_preference
  Screen.term_rect.width = 640
  if termsize == SizePreferences["double"] then
    if wh >= 640 and ww >= 1280 then
      Screen.term_rect.width = 1280
    end
  elseif termsize == SizePreferences["largest"] then
    Screen.term_rect.width = math.min(ww, math.max(640, 2 * wh))
  end
  
  Screen.term_rect.height = Screen.term_rect.width / 2
  Screen.term_rect.x = math.floor((ww - Screen.term_rect.width) / 2)
  Screen.term_rect.y = math.floor((wh - Screen.term_rect.height) / 2)
  
  -- calculate world-view area
  Screen.world_rect.width = math.min(ww, math.max(640, 2 * wh))
  Screen.world_rect.height = Screen.world_rect.width / 2
  Screen.world_rect.x = math.floor((ww - Screen.world_rect.width) / 2)
  Screen.world_rect.y = math.floor((wh - Screen.world_rect.height) / 2)
  
  -- calculate map area
  if Screen.map_overlay_active then
    -- overlay just matches world-view
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
  else
    Screen.map_rect.width = ww
    Screen.map_rect.height = wh
    Screen.map_rect.x = 0
    Screen.map_rect.y = 0
  end
  
  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.x = 0
  Screen.clip_rect.y = 0

  return true
end

-- END texture palette utility
