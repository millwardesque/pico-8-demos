scene = {}
player = nil

function _init()
	-- create player
	local player_anims = {
		idle = { 32, 32, 32, 32, 33, 33, 33, 33 },
		walk = { 33, 34, 36, 35, }
	}
	player = make_game_object(utils.cell_to_world(make_vec2(4, 12)))
	attach_anim_spr_controller(player, 8, player_anims, "idle")
	player.draw = function (self)
		draw_anim_spr_controller(self.anim_controller, self.position)
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
	attach_anim_spr_controller(security_cam, 32, security_cam_anims, "pan")
	security_cam.draw = function (self)
		draw_anim_spr_controller(self.anim_controller, self.position)
	end
	security_cam.update = function (self)
		update_anim_spr_controller(self.anim_controller)
	end
	add(scene, security_cam)

	local server_palettes = {
		{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 8, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 8, 11, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
		{ 0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
	}
	local server = make_game_object(utils.cell_to_world(make_vec2(6, 12)))
	attach_anim_pal_controller(server, 26, 32, server_palettes)
	server.draw = function (self)
		draw_anim_pal_controller(self.anim_controller, self.position)
	end
	server.update = function (self)
		update_anim_pal_controller(self.anim_controller)
	end
	add(scene, server)
end

function _update()
	for game_obj in all(scene) do
		if (game_obj.update) then 
			game_obj.update(game_obj)
		end
	end
end

function _draw()
	cls()

	map(0, 0, 0, 0, 128, 64) -- draw the whole map and let the clipping region remove unnecessary bits

	for game_obj in all(scene) do
		if (game_obj.draw) then
			game_obj.draw(game_obj)
		end
	end
	
	print("cpu: "..stat(1))
end

function make_game_object(position)
	local game_obj = {
		position = position
	}
	return game_obj
end

-- Animated sprite controller
function attach_anim_spr_controller(game_obj, frames_per_cell, animations, start_anim)
	game_obj.anim_controller = {
		current_animation = start_anim,
		current_cell = 1,
		frames_per_cell = frames_per_cell,
		current_frame = 1,
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

function draw_anim_spr_controller(controller, position)
	color(7)
	print("frame: "..controller.current_frame.." / "..controller.frames_per_cell)

	if (controller.current_animation != nil and controller.current_cell != nil) then
		print("cell: "..controller.animations[controller.current_animation][controller.current_cell].." ("..controller.current_cell.." / "..#controller.animations[controller.current_animation]..")")
		spr(controller.animations[controller.current_animation][controller.current_cell], position.x, position.y)
	end
end

-- Animated palette controller
function attach_anim_pal_controller(game_obj, sprite, frames_per_palette, palettes)
	game_obj.anim_controller = {
		sprite = sprite,
		current_palette = 1,
		frames_per_palette = frames_per_palette,
		current_frame = 1,
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

function draw_anim_pal_controller(controller, position)
	color(7)
	print("frame: "..controller.current_frame.." / "..controller.frames_per_palette)

	if (controller.sprite != nil and controller.current_palette != nil) then
		print("pal: "..controller.current_palette.." / "..#controller.palettes)

		-- Set the palette
		for i = 0, 15 do
			pal(i, controller.palettes[controller.current_palette][i + 1])
		end

		-- Draw the sprite
		spr(controller.sprite, position.x, position.y)

		-- Reset the palette
		pal()
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
}