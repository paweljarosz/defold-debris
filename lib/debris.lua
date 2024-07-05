local M = {}

M.emitted_particles = {}

local TRANSPARENT = vmath.vector4(1,1,1,0)

-- config
-- config.amount - amount of created particles
-- config.scale_min - minimum scale factor (between 0 and scale_max)
-- config.scale_max - maximum scale factor (between scale_min and infinity)
function M.dynamic(factory_url, config)
	factory_url = factory_url or "#blood"
	config = config or {}
	config.position = config.position or go.get_world_position()
	config.offset_position = config.offset_position or go.get_world_position()
	config.scale_min = config.scale_min or 1
	config.scale_max = config.scale_max or 10
	config.scale_factor = config.scale_factor or 0.1
	config.min_x_spread = (config.min_x_spread or -12) * (config.x_spread_factor or 1000)
	config.max_x_spread = (config.max_x_spread or 12) * (config.x_spread_factor or 1000)
	config.min_y_spread = (config.min_y_spread or 20) * (config.y_spread_factor or 1000)
	config.max_y_spread = (config.max_y_spread or 35) * (config.y_spread_factor or 1000)
	config.min_time = config.min_time or 6
	config.max_time = config.max_time or 10
	config.time_factor = config.time_factor or 1
	config.amount = config.amount or 50
	config.particlefx_url = config.particlefx_url or false

	local particle_batch_number = #(M.emitted_particles) + 1
	M.emitted_particles[particle_batch_number] = {}

	for i = 1, config.amount do
		local scale = math.random(config.scale_min, config.scale_max) * config.scale_factor
		local id = factory.create(factory_url, _, _, _, vmath.vector3(scale, scale, scale))
		M.emitted_particles[particle_batch_number][i] = id

		local co_url = msg.url(nil,id,"collisionobject")
		local x_spread = math.random(config.min_x_spread, config.max_x_spread)
		local y_spread = math.random(config.min_y_spread, config.max_y_spread)
		msg.post(co_url, "apply_force", {force = vmath.vector3(x_spread, y_spread, 0), position = config.position + config.offset_position})

		local sprite_url = msg.url(_, id, "sprite")
		if config.sprite_anim_variants then
			sprite.play_flipbook(sprite_url, config.sprite_anim_variants[math.random(1,#(config.sprite_anim_variants))])
		end

		local pfx_url
		if config.particlefx_url then
			pfx_url = msg.url(nil,id,config.particlefx_url)
			particlefx.play(pfx_url)
		end

		local lifetime = math.random(config.min_time,config.max_time) * config.time_factor
		timer.delay(lifetime, false, function()
			if go.exists(id) then
				go.animate(sprite_url, "tint", go.PLAYBACK_ONCE_FORWARD, TRANSPARENT, go.EASING_INOUTSINE, 2, 0, function()
					if config.particlefx_url then
						particlefx.stop(pfx_url)
					end
					go.delete(id)
					if M.emitted_particles[particle_batch_number] then
						table.remove(M.emitted_particles[particle_batch_number], i)
					end
					if M.emitted_particles[particle_batch_number] and (#(M.emitted_particles[particle_batch_number]) == 0) then
						table.remove(M.emitted_particles, particle_batch_number)
					end
				end)
			end
		end)
	end
end

return M