scene = {}
cameras = {}
player = nil
layer_flags = {
	bg = 1,
	normal = 2,
	fg = 4,
}
parallax_depths = {
	bg = 2.5,
	normal = 1,
	fg = 0.25,
}

function _init()
	-- create player
	local player_anims = {
		idle = { 32, 32, 32, 32, 33, 33, 33, 33 },
		walk = { 33, 34, 36, 35, }
	}
	player = make_game_object(utils.cell_to_world(make_vec2(4, 12)))
	attach_anim_spr_controller(player, 8, player_anims, "idle", 0)
	player.draw = function (self, cam, layers)
		draw_anim_spr_controller(self.anim_controller, self.position, cam, layers)
	end
	player.update = function (self)
		update_anim_spr_controller(self.anim_controller, self)
	end

	attach_renderable(player, 32)
	add(scene, player);

	-- create security camera
	local security_cam_anims = {
		pan = { 23, 25, 23, 24, }
	}
	local security_cam = make_game_object(utils.cell_to_world(make_vec2(8, 1)))
	attach_anim_spr_controller(security_cam, 32, security_cam_anims, "pan", 0)
	security_cam.draw = function (self, cam, layers)
		draw_anim_spr_controller(self.anim_controller, self.position, cam, layers)
	end
	security_cam.update = function (self)
		update_anim_spr_controller(self.anim_controller, self)
	end
	attach_renderable(security_cam, 23)
	add(scene, security_cam)

	-- Make some servers
	add(scene, make_server(26, make_vec2(1, 6), 32, 0))
	add(scene, make_server(26, make_vec2(3, 6), 32, 4))
	add(scene, make_server(21, make_vec2(13, 6), 16, 3))
	add(scene, make_server(21, make_vec2(2, 5), 16, 11))

	-- create cameras

	-- Main camera
	add(cameras, make_camera(make_vec2(0, 0), 128, 128, make_vec2(0, 0), 1))

	-- Security camera
	local follow_cam = make_camera(utils.cell_to_world(make_vec2(5, 2)), 6 * config.cell_width, 4 * config.cell_height, make_vec2(0, 0), 1)
	follow_cam.target = player
	attach_scanlines(follow_cam, 27, 8, 3, 11)
	add(cameras, follow_cam)

	-- Near parallax camera
	local near_parallax_cam = make_camera(make_vec2(0, 0), 128, 128, make_vec2(0, 0), 1, "fg_near");
	near_parallax_cam.target = player
	-- @INPROGRESS add(cameras, near_parallax_cam)
	-- @TODO Change to be attachment of main camera instead of separate camera.
end

function _update()
	local move_speed = 1
	local player_dir = make_vec2(0, 0)
	if btn(0) then
		player_dir.x -= move_speed
	end
	if btn(1) then
		player_dir.x += move_speed
	end
	if btn(2) then
		player_dir.y -= move_speed
	end
	if btn(3) then
		player_dir.y += move_speed
	end

	if (player_dir.x < 0) then
		player.anim_controller.flip_x = true
	elseif (player_dir.x > 0) then
		player.anim_controller.flip_x = false
	end
	player.position += player_dir

	if (vec2_magnitude(player_dir) > 0) then
		if (player.anim_controller.current_animation != "walk") then
			set_anim_spr_animation(player.anim_controller, "walk")
		end
	else
		if (player.anim_controller.current_animation != "idle") then
			set_anim_spr_animation(player.anim_controller, "idle")
		end
	end

	for game_obj in all(scene) do
		if (game_obj.update) then 
			game_obj.update(game_obj)
		end
	end

	for cam in all(cameras) do
		camera_update(cam)
	end
end

function _draw()
	cls()
	g_renderer.render()
	print("cpu: "..stat(1))
end

function _draw_old()
	cls()

	for cam in all(cameras) do
		camera_draw_start(cam)
		
		local layers = 0
		if (cam.parallax_name) then
			layers = layer_flags[cam.parallax_name]
		end
		map(0, 0, 0, 0, 128, 64, layers) -- draw the whole map and let the clipping region remove unnecessary bits

		for game_obj in all(scene) do
			if (game_obj.draw) then
				game_obj.draw(game_obj, cam, layers)
			end
		end
		camera_draw_end(cam)
	end
	
	print("cpu: "..stat(1))
end

function attach_scanlines(cam, sprite, duration, colour, highlight_colour) 
	local camera_palettes = {
		{0, colour, 0, 0, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 2, 3, 4 },
		{0, 0, colour, 0, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 3, 4 },
		{0, 0, 0, highlight_colour, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 4 },
		{0, 0, 0, 0, colour, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3 },
	}
	attach_anim_pal_controller(cam, sprite, duration, camera_palettes, 0)
	cam.effect_update = function(self)
		update_anim_pal_controller(self.anim_controller, self)
	end
	cam.effect_draw = function (self)
		palt()

		-- Set the palette
		for i = 0, 15 do
			pal(i, self.anim_controller.palettes[self.anim_controller.current_palette][i + 1])
		end

		-- Set the palette transparencies
		for i = 17, #self.anim_controller.palettes[self.anim_controller.current_palette] do
			palt(self.anim_controller.palettes[self.anim_controller.current_palette][i], true)
		end

		local start_pos = utils.world_to_cell(cam.draw_pos)
		local end_pos = utils.world_to_cell(cam.draw_pos + make_vec2(cam.draw_width, cam.draw_height)) - make_vec2(1, 1)

		-- Draw the sprite
		for y = start_pos.y, end_pos.y do
			for x = start_pos.x, end_pos.x do 
				local pos = utils.cell_to_world(make_vec2(x, y))
				spr(self.anim_controller.sprite, pos.x, pos.y)
			end
		end

		-- Reset the palette
		pal()
		palt()
	end
end

function make_server(sprite, position, blink_duration, start_frame_offset)
	local server_palettes = {
		{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 8, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 8, 11, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
	}
	local server = make_game_object(utils.cell_to_world(position))
	attach_anim_pal_controller(server, sprite, blink_duration, server_palettes, start_frame_offset)
	server.draw = function (self, cam, layers)
		draw_anim_pal_controller(self.anim_controller, self.position, cam, layers)
	end
	server.update = function (self)
		update_anim_pal_controller(self.anim_controller, self)
	end
	attach_renderable(server, sprite)
	return server
end

function make_game_object(position)
	local game_obj = {
		position = position
	}
	return game_obj
end

-- Animated sprite controller
function attach_anim_spr_controller(game_obj, frames_per_cell, animations, start_anim, start_frame_offset)
	game_obj.anim_controller = {
		current_animation = start_anim,
		current_cell = 1,
		frames_per_cell = frames_per_cell,
		current_frame = 1 + start_frame_offset,
		animations = animations,
		flip_x = false,
		flip_y = false,
	}
	return game_obj
end

function update_anim_spr_controller(controller, renderable)
	controller.current_frame += 1
	if (controller.current_frame > controller.frames_per_cell) then
		controller.current_frame = 1

		if (controller.current_animation != nil and controller.current_cell != nil) then
			controller.current_cell += 1
			if (controller.current_cell > #controller.animations[controller.current_animation]) then
				controller.current_cell = 1
			end
		end
	end

	if (renderable and controller.current_animation != nil and controller.current_cell != nil) then
		renderable.sprite = controller.animations[controller.current_animation][controller.current_cell]
	else
		renderable.sprite = nil
	end
end

function set_anim_spr_animation(controller, animation)
	controller.current_frame = 0
	controller.current_cell = 1
	controller.current_animation = animation
end

function draw_anim_spr_controller(controller, position, cam, layers)
	-- color(7)
	-- print("frame: "..controller.current_frame.." / "..controller.frames_per_cell)

	if (controller.current_animation != nil and controller.current_cell != nil and layers == 0) then
		-- print("cell: "..controller.animations[controller.current_animation][controller.current_cell].." ("..controller.current_cell.." / "..#controller.animations[controller.current_animation]..")")
		g_renderer.draw_sprite(controller.animations[controller.current_animation][controller.current_cell], 1, 1, position, cam.zoom, controller.flip_x, controller.flip_y) 
	end
end

-- Animated palette controller
function attach_anim_pal_controller(game_obj, sprite, frames_per_palette, palettes, start_frame_offset)
	game_obj.anim_controller = {
		sprite = sprite,
		current_palette = 1,
		frames_per_palette = frames_per_palette,
		current_frame = 1 + start_frame_offset,
		palettes = palettes,
		flip_x = false,
		flip_y = false,
	}
	return game_obj
end

function update_anim_pal_controller(controller, renderable)
	controller.current_frame += 1
	if (controller.current_frame > controller.frames_per_palette) then
		controller.current_frame = 1

		if (controller.current_palette != nil) then
			controller.current_palette += 1
			if (controller.current_palette > #controller.palettes) then
				controller.current_palette = 1
			end
		end
	end

	if (renderable and controller.current_palette != nil) then
		renderable.palette = controller.palettes[controller.current_palette];
	else
		renderable.palette = nil
	end
end

function draw_anim_pal_controller(controller, position, cam, layers)
	-- color(7)
	-- print("frame: "..controller.current_frame.." / "..controller.frames_per_palette)

	if (controller.sprite != nil and controller.current_palette != nil and layers == 0) then
		-- print("pal: "..controller.current_palette.." / "..#controller.palettes)

		-- Set the palette
		for i = 0, 15 do
			pal(i, controller.palettes[controller.current_palette][i + 1])
		end

		-- Draw the sprite
		g_renderer.draw_sprite(controller.sprite, 1, 1, position, cam.zoom, controller.flip_x, controller.flip_y) 

		-- Reset the palette
		pal()
	end
end

--
-- Camera
--
function make_camera(draw_pos, draw_width, draw_height, shoot_pos, zoom)
	local t = {
 		draw_pos = draw_pos,
 		draw_width = draw_width,
 		draw_height = draw_height,
 		shoot_pos = shoot_pos,
 		zoom = zoom,
 		target = nil
 	}
	return t
end
function camera_draw_start(cam, layer_name)
	local parallax_scale = parallax_depths[layer_name]
	local cam_x = (cam.shoot_pos.x - cam.draw_pos.x) / parallax_scale
	local cam_y = (cam.shoot_pos.y - cam.draw_pos.y) / parallax_scale

	camera(cam_x, cam_y)
	clip(cam.draw_pos.x, cam.draw_pos.y, cam.draw_width, cam.draw_height)
end

function camera_draw_end(cam)
	camera()
	clip()

	if (cam.effect_draw) then
		cam.effect_draw(cam)
	end
end

function camera_update(cam)
 if cam.target != nil then
  -- centre the camera on the target
  cam.shoot_pos.x = cam.target.position.x - flr(cam.draw_width / 2)
  cam.shoot_pos.y = cam.target.position.y - flr(cam.draw_height / 2)
 end

 if cam.effect_update then
 	cam.effect_update(cam)
 end
end

--
-- 2d Vector
--
local vec2_meta = {}
function vec2_meta.__add(a, b)
	return make_vec2(a.x + b.x, a.y + b.y)
end

function vec2_meta.__sub(a, b)
	return make_vec2(a.x - b.x, a.y - b.y)
end

function vec2_meta.__mul(a, b)
	if type(a) == "number" then
		return make_vec2(a * b.x, a * b.y)
	elseif type(b) == "number" then
		return make_vec2(b * a.x, b * a.y)
	else
		return make_vec2(a.x * b.x, a.y * b.y)
	end
end

function vec2_meta.__div(a, b) 
	make_vec2(a.x / b, a.y / b)
end

function vec2_meta.__eq(a, b) 
	return a.x == b.x and a.y == b.y
end

function make_vec2(x, y) 
	local table = {
		x = x,
		y = y,
	}
	setmetatable(table, vec2_meta)
	return table;
end

function vec2_magnitude(v)
	return sqrt(v.x ^ 2 + v.y ^ 2)
end

function vec2_normalized(v) 
	local mag = vec2_magnitude(v)
	return make_vec2(v.x / mag, v.y / mag)
end

function vec2_str(v)
	return "("..v.x..", "..v.y..")"
end

--
-- Renderable maker.
--
function attach_renderable(game_obj, sprite)
	local renderable = {
		sprite = sprite,
		flip_x = false,
		flip_y = false,
		sprite_width = 1,
		sprite_height = 1,
		palette = nil
	}

	-- Default rendering function
	renderable.render = function(renderable, position)

		-- Set the palette
		if (renderable.palette) then
			-- Set colours
			for i = 0, 15 do
				pal(i, renderable.palette[i + 1])
			end

			-- Set transparencies
			for i = 17, #self.anim_controller.palettes[self.anim_controller.current_palette] do
				palt(self.anim_controller.palettes[self.anim_controller.current_palette][i], true)
			end
		end

		-- Draw
		g_renderer.spr(renderable.sprite, position.x, position.y, renderable.sprite_width, renderable.sprite_height, renderable.flip_x, renderable.flip_y)

		-- Reset the palette
		if (renderable.palette) then
			pal()
			palt()
		end
	end

	game_obj.renderable = renderable;
	return game_obj;
end

--
-- Renderer subsystem.
--
g_renderer = {
	spr = nil,
	map = nil,
	active_camera = nil,
}

--
-- Main render pipeline
--
g_renderer.render = function()
	-- Collect renderables and post-processing effects
	-- @TODO Organize into layer lists?
	local renderables = {};
	local post_renderables = {};
	for game_obj in all(scene) do
		if (game_obj.renderable) then
			add(renderables, game_obj)
		end

		if (game_obj.post_render) then
			add(post_renderables, game_obj)
		end
	end

	-- @TODO Y-sort renderables

	-- Draw the scene for each camera
	for camera in all(cameras) do
		g_renderer.active_camera = camera

		-- Render each layer
		for layer_name, layer_id in pairs(layer_flags) do
			-- Load the camera settings
			camera_draw_start(camera, layer_name)

			-- @TODO rectfill the clipped screen first?

			-- Draw the map
			g_renderer.map(0, 0, 0, 0, 128, 64, layer_id) -- draw the whole map and let the clipping region remove unnecessary bits

			for game_obj in all(renderables) do
				-- Only render sprites on the active layer
				if (fget(game_obj.renderable.sprite, layer_id)) then
					game_obj.renderable.render(game_obj.renderable, game_obj.position)
				end
			end

			-- Clean up the camera settings
			camera_draw_end(camera, layer_name)
		end
	end
	g_renderer.active_camera = nil

	-- Apply post-processing effects
	for game_obj in all(post_renderables) do
		game_obj.post_render()
	end
end

--
-- Gets the current scale amount based on the current camera (or 1 otherwise)
--
g_renderer.get_scale = function()
	if (g_renderer.active_camera and g_renderer.active_camera.zoom != 1) then
		return g_renderer.active_camera.zoom
	else
		return 1
	end
end

--
-- Wraps the spr function to support zoom.
--
g_renderer.spr = function(sprite, dest_x, dest_y, sprite_width, sprite_height, flip_x, flip_y)
	local scale = g_renderer.get_scale()

	if (scale == 1) then
		spr(sprite, dest_x, dest_y, sprite_width, sprite_height, flip_x, flip_y)
	else
		local sprite_x = config.cell_width * (sprite % config.sprites_per_row)
		local sprite_y = config.cell_height * (flr(sprite / config.sprites_per_row))

		sspr(sprite_x, sprite_y, sprite_width * config.cell_width, sprite_height * config.cell_height, dest_x, dest_y, sprite_width * config.cell_width * scale, sprite_height * config.cell_height * scale, flip_x, flip_y)
	end
end

--
-- Wraps the map function to support zoom.
--
g_renderer.map = function(cell_x, cell_y, dest_x, dest_y, cell_width, cell_height, layer)
	local scale = g_renderer.get_scale()

	if (scale == 1) then
		map(cell_x, cell_y, dest_x, dest_y, cell_width, cell_height, layer)
	else
		-- @TODO Custom map for zoom support
		map(cell_x, cell_y, dest_x, dest_y, cell_width, cell_height, layer)
	end
end

--
-- Deprecated.
--
g_renderer.draw_sprite = function(sprite, sprite_width, sprite_height, dest, scale, flip_x, flip_y) 
	if (scale == 1) then
		spr(sprite, dest.x, dest.y, sprite_width, sprite_height, flip_x, flip_y)
	else
		local sx = config.cell_width * (sprite % config.sprites_per_row)
		local sy = config.cell_height * (flr(sprite / config.sprites_per_row))

		sspr(sx, sy, sprite_width * config.cell_width, sprite_height * config.cell_height, dest.x, dest.y, sprite_width * config.cell_width * scale, sprite_height * config.cell_height * scale, flip_x, flip_y)
	end
end

-- General utilities.
utils = {}

-- converts a world position to map cell coords
utils.world_to_cell = function(world)
	return make_vec2(flr(world.x / config.cell_width), flr(world.y / config.cell_height))
end

-- converts a map cell coord to four world positions corresponding to its corners
utils.cell_to_world = function(cell)
	return make_vec2(cell.x * config.cell_width, cell.y * config.cell_height)
end

-- world configuration info
config = {
	cell_width = 8,
	cell_height = 8,
	sprites_per_row = 16,
}