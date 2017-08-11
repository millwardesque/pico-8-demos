scene = {}
cameras = {}
player = nil

function _init()
	-- create player
	local player_anims = {
		idle = { 32, 32, 32, 32, 33, 33, 33, 33 },
		walk = { 33, 34, 36, 35, }
	}
	player = make_game_object(utils.cell_to_world(make_vec2(4, 12)))
	attach_anim_spr_controller(player, 8, player_anims, "idle", 0)
	player.draw = function (self, cam)
		draw_anim_spr_controller(self.anim_controller, self.position, cam)
	end
	player.update = function (self)
		update_anim_spr_controller(self.anim_controller)
	end

	add(scene, player);

	-- create security camera
	local security_cam_anims = {
		pan = { 23, 25, 23, 24, }
	}
	local security_cam = make_game_object(utils.cell_to_world(make_vec2(8, 1)))
	attach_anim_spr_controller(security_cam, 32, security_cam_anims, "pan", 0)
	security_cam.draw = function (self, cam)
		draw_anim_spr_controller(self.anim_controller, self.position, cam)
	end
	security_cam.update = function (self)
		update_anim_spr_controller(self.anim_controller)
	end
	add(scene, security_cam)

	-- Make some servers
	add(scene, make_server(26, make_vec2(1, 6), 32, 0))
	add(scene, make_server(26, make_vec2(3, 6), 32, 4))
	add(scene, make_server(21, make_vec2(13, 6), 16, 3))
	add(scene, make_server(21, make_vec2(2, 5), 16, 11))

	-- create cameras
	add(cameras, make_camera(make_vec2(0, 0), 128, 128, make_vec2(0, 0), 1))

	local follow_cam = make_camera(utils.cell_to_world(make_vec2(5, 2)), 6 * config.cell_width, 4 * config.cell_height, make_vec2(0, 0), 1)
	follow_cam.target = player.position
	add(cameras, follow_cam)
end

function _update()
	local move_speed = 1
	if btn(0) then
		player.position.x -= move_speed
	end
	if btn(1) then
		player.position.x += move_speed
	end
	if btn(2) then
		player.position.y -= move_speed
	end
	if btn(3) then
		player.position.y += move_speed
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

	for cam in all(cameras) do
		camera_draw_start(cam)
		
		map(0, 0, 0, 0, 128, 64) -- draw the whole map and let the clipping region remove unnecessary bits

		for game_obj in all(scene) do
			if (game_obj.draw) then
				game_obj.draw(game_obj, cam)
			end
		end
		camera_draw_end(cam)
	end
	
	print("cpu: "..stat(1))
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
	server.draw = function (self, cam)
		draw_anim_pal_controller(self.anim_controller, self.position, cam)
	end
	server.update = function (self)
		update_anim_pal_controller(self.anim_controller)
	end
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
		animations = animations
	}
	return game_obj
end

function update_anim_spr_controller(controller)
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
end

function draw_anim_spr_controller(controller, position, cam)
	-- color(7)
	-- print("frame: "..controller.current_frame.." / "..controller.frames_per_cell)

	if (controller.current_animation != nil and controller.current_cell != nil) then
		-- print("cell: "..controller.animations[controller.current_animation][controller.current_cell].." ("..controller.current_cell.." / "..#controller.animations[controller.current_animation]..")")
		render.draw_sprite(controller.animations[controller.current_animation][controller.current_cell], 1, 1, position, cam.zoom, false, false) 
	end
end

-- Animated palette controller
function attach_anim_pal_controller(game_obj, sprite, frames_per_palette, palettes, start_frame_offset)
	game_obj.anim_controller = {
		sprite = sprite,
		current_palette = 1,
		frames_per_palette = frames_per_palette,
		current_frame = 1 + start_frame_offset,
		palettes = palettes
	}
	return game_obj
end

function update_anim_pal_controller(controller)
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
end

function draw_anim_pal_controller(controller, position, cam)
	-- color(7)
	-- print("frame: "..controller.current_frame.." / "..controller.frames_per_palette)

	if (controller.sprite != nil and controller.current_palette != nil) then
		-- print("pal: "..controller.current_palette.." / "..#controller.palettes)

		-- Set the palette
		for i = 0, 15 do
			pal(i, controller.palettes[controller.current_palette][i + 1])
		end

		-- Draw the sprite
		render.draw_sprite(controller.sprite, 1, 1, position, cam.zoom, false, false) 

		-- Reset the palette
		pal()
	end
end

-- Camera
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
function camera_draw_start(cam)
 camera(cam.shoot_pos.x - cam.draw_pos.x, cam.shoot_pos.y - cam.draw_pos.y)
 clip(cam.draw_pos.x, cam.draw_pos.y, cam.draw_width, cam.draw_height)
end

function camera_draw_end(cam)
 camera()
 clip()
end

function camera_update(cam)
 if cam.target != nil then
  -- centre the camera on the target
  cam.shoot_pos.x = cam.target.x - flr(cam.draw_width / 2)
  cam.shoot_pos.y = cam.target.y - flr(cam.draw_height / 2)
 end
end

-- 2d vector
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

-- Render utilities
render = {}
render.draw_sprite = function(sprite, sprite_width, sprite_height, dest, scale, flip_x, flip_y) 
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