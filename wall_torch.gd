extends Node3D

@export var light: OmniLight3D
@export var noise: FastNoiseLite

# Interval to generate random flickering.
@export var min_delay = 5.0
@export var max_delay = 10.0
# Length of flickering.
@export var flicker_length = 0.1
# Fraction of the light energy that noise affects.
@export_range(0.0, 1.0) var noise_fraction = 0.75

var flicker = false
var next_flicker_set = false
var rng = RandomNumberGenerator.new()

func _process(delta):
	if not next_flicker_set:
		next_flicker_set = true
		await prepare_flicker()
	if not flicker:
		light.light_energy = 1.0
	else:
		var sampled_noise = noise.get_noise_1d(Time.get_ticks_msec())
		# This gives a number between 0 and 1.
		sampled_noise = sampled_noise / 2.0 + 0.5
		var base_light = 1.0 - noise_fraction
		var noise_light = sampled_noise * noise_fraction
		light.light_energy = base_light + noise_light

func prepare_flicker():
	await get_tree().create_timer(rng.randf_range(min_delay, max_delay)).timeout
	flicker = true
	await get_tree().create_timer(flicker_length).timeout
	flicker = false
	next_flicker_set = false
