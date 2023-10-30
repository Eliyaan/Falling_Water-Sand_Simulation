module main

import gg
import gx
import rand as rd // do not remove, using default_rng from it
import math.bits
import math

const (
	win_width  = 740
	win_height = 740
	bg_color   = gx.rgb(148, 226, 213)

	pixel_size = 1
	nb_tiles   = 680
	refresh    = 65000
	sim_size   = pixel_size * nb_tiles
	text_cfg   = gx.TextCfg{
		color: gx.green
		size: 20
		align: .left
		vertical_align: .top
	}
	x_offset = 30
	y_offset = 30
	blue     = u32(0xFFFF_B700)
	blue_ni  = int(0x00B7_FFFF) // non inverted
	black    = u32(0xFF00_0000)
	black_ni = int(0x0000_00FF) // non inverted
	orange   = u32(0xFF42_87F5)
	white    = u32(0xFFFF_FFFF)
)

[inline]
fn u32n(max u32) int {
	mask := (u32(1) << (bits.len_32(max) + 1)) - 1
	for {
		value := default_rng.u32() & mask
		if value < max {
			return int(value)
		}
	}
	return 0
}

[inline]
fn custom_int_in_range(min int, max int) int {
	output := min + u32n(u32(max - min))
	assert output < max
	assert output >= min
	return output
}

struct App {
mut:
	gg                 &gg.Context = unsafe { nil }
	tiles_states       [nb_tiles][nb_tiles]u8 = [nb_tiles][nb_tiles]u8{init: [nb_tiles]u8{init: u8(0)}}
	// [Ligne][colonne]
	istream_idx        int
	screen_pixels      [nb_tiles][nb_tiles]u32 = [nb_tiles][nb_tiles]u32{init: [nb_tiles]u32{init: u32(white)}}
	water_tiles_coords [][]int
	wall_tiles_coords  [][]int
	mouse_held         bool
	mouse_coords       [2]int
	paint_type         int = 1
	paint_size         int = 20
}

fn main() {
	mut app := &App{
		gg: 0
	}
	app.gg = gg.new_context(
		width: win_width
		height: win_height
		create_window: true
		window_title: 'Water/Sand simulation'
		user_data: app
		bg_color: bg_color
		init_fn: graphics_init
		frame_fn: on_frame
		event_fn: on_event
	)

	// lancement du programme/de la fenêtre
	app.gg.run()
}

fn on_frame(mut app App) {
	// painting
	app.paint_tiles()

	// Process
	app.process_tiles()

	// Draw
	app.gg.begin()

	// white square around the paint type chooser
	app.gg.draw_square_filled(3, 35 * (app.paint_type), 24, gx.white)
	app.gg.draw_square_filled(35 * (app.paint_size / 4), 3, 24, gx.white)

	app.gg.draw_square_filled(5, 37, 20, gx.hex(blue_ni))
	app.gg.draw_square_filled(5, 72, 20, gx.hex(black_ni))

	app.gg.draw_circle_filled(37 + 10, 15, 2, gx.black)
	app.gg.draw_circle_filled(72 + 10, 15, 4, gx.black)
	app.gg.draw_circle_filled(107 + 10, 15, 6, gx.black)
	app.gg.draw_circle_filled(107 + 10, 15, 8, gx.black)
	app.gg.draw_circle_filled(142 + 10, 15, 10, gx.black)
	app.gg.draw_circle_filled(177 + 10, 15, 12, gx.black)
	app.draw()

	// app.gg.show_fps()
	// app.gg.draw_text(40, 0, "Paint size: ${app.paint_size/2}, Paint type: ${app.paint_type}, Nb water particles: ${app.water_tiles_coords.len}", text_cfg)
	app.gg.end()
}

[direct_array_access; inline]
fn (mut app App) update_water_tile(nb int, i_delta int, j_delta int) {
	i := app.water_tiles_coords[nb][0]
	j := app.water_tiles_coords[nb][1]
	app.tiles_states[i][j] = 0
	app.screen_pixels[i][j] = white
	app.tiles_states[i + i_delta][j + j_delta] = 1
	app.screen_pixels[i + i_delta][j + j_delta] = blue
	app.water_tiles_coords[nb][0] += i_delta
	app.water_tiles_coords[nb][1] += j_delta
}

[direct_array_access]
fn (mut app App) process_tiles() {
	for nb, mut w_coo in app.water_tiles_coords {
		i := w_coo[0]
		j := w_coo[1]
		if i + 1 < nb_tiles && app.tiles_states[i + 1][j] == 0 { // bas libre
			if i != 0 && app.tiles_states[i - 1][j] == 0 { // Haut libre = descendre
				if i + 2 < nb_tiles && app.tiles_states[i + 2][j] == 0 {
					app.update_water_tile(nb, 2, 0)
				} else if i + 1 < nb_tiles {
					app.update_water_tile(nb, 1, 0)
				}
			} else { // haut plein
				if j > 0 && app.tiles_states[i][j - 1] == 0 { // gauche libre
					if j + 1 < nb_tiles && app.tiles_states[i][j + 1] == 0 { // deux cotés libres = descendre
						if i + 2 < nb_tiles && app.tiles_states[i + 2][j] == 0 {
							app.update_water_tile(nb, 2, 0)
						} else {
							app.update_water_tile(nb, 1, 0)
						}
					} else { // droite oqp et gauche libre et haut plein
						if custom_int_in_range(0, 2) == 0 {
							app.update_water_tile(nb, 1, 0)
						} else if custom_int_in_range(0, 2) == 0 {
							app.update_water_tile(nb, 0, -1)
						}
					}
				} else { // gauche oqp
					if j != nb_tiles - 1 && app.tiles_states[i][j + 1] == 0 { // droite libre et gauche oqp et haut plein
						if custom_int_in_range(0, 2) == 0 {
							app.update_water_tile(nb, 1, 0)
						} else if custom_int_in_range(0, 2) == 0 {
							app.update_water_tile(nb, 0, 1)
						}
					} else { // gauche et droite oqp et haut plein descendre parfois
						app.update_water_tile(nb, 1, 0)
					}
				}
			}
		} else { // bas plein
			if j > 0 && app.tiles_states[i][j - 1] == 0 { // gauche libre
				if j + 1 < nb_tiles && app.tiles_states[i][j + 1] == 0 { // deux cotés libres
					if i + 1 < nb_tiles && app.tiles_states[i + 1][j + 1] == 0 { // diag bas droite libre
						if app.tiles_states[i + 1][j - 1] == 0 { // diag bas gauche libre
							if custom_int_in_range(0, 2) == 0 {
								app.update_water_tile(nb, 1, 1)
							} else {
								app.update_water_tile(nb, 1, -1)
							}
						} else { // que diag bas droite libre
							app.update_water_tile(nb, 1, 1)
						}
					} else {
						if i + 1 < nb_tiles && app.tiles_states[i + 1][j - 1] == 0 { // que diag bas gauche libre
							app.update_water_tile(nb, 1, -1)
						} else { // aucune diag libre mais 2 cotés libres
							if custom_int_in_range(0, 2) == 0 {
								app.update_water_tile(nb, 0, 1)
							} else {
								app.update_water_tile(nb, 0, -1)
							}
						}
					}
				} else { // que gauche
					app.update_water_tile(nb, 0, -1)
				}
			} else { // pas gauche
				if j != nb_tiles - 1 && app.tiles_states[i][j + 1] == 0 { // que droite libre
					app.update_water_tile(nb, 0, 1)
				}
			}
		}
	}
}

fn (mut app App) paint_tiles() {
	if app.mouse_held {
		for l in -app.paint_size .. 1 + app.paint_size {
			for c in -app.paint_size .. 1 + app.paint_size {
				if l * l + c * c < (app.paint_size * app.paint_size) {
					if app.mouse_coords[0] + c < nb_tiles && app.mouse_coords[0] + c >= 0
						&& app.mouse_coords[1] + l < nb_tiles && app.mouse_coords[1] + l >= 0 {
						if app.paint_type == 1
							&& app.tiles_states[app.mouse_coords[1] + l][app.mouse_coords[0] + c] == 0 {
							app.tiles_states[app.mouse_coords[1] + l][app.mouse_coords[0] + c] = 1
							app.screen_pixels[app.mouse_coords[1] + l][app.mouse_coords[0] + c] = blue
							if app.water_tiles_coords.len == 0 {
								app.water_tiles_coords << [
									[app.mouse_coords[1] + l, app.mouse_coords[0] + c],
								]
							} else {
								rnd := custom_int_in_range(0, app.water_tiles_coords.len)
								switch_tmp := app.water_tiles_coords[rnd]
								app.water_tiles_coords[rnd] = [app.mouse_coords[1] + l, 
									app.mouse_coords[0] + c]
								app.water_tiles_coords << switch_tmp
							}
						} else if app.paint_type == 2
							&& app.tiles_states[app.mouse_coords[1] + l][app.mouse_coords[0] + c] == 0 {
							app.tiles_states[app.mouse_coords[1] + l][app.mouse_coords[0] + c] = 2
							app.screen_pixels[app.mouse_coords[1] + l][app.mouse_coords[0] + c] = black
							app.wall_tiles_coords << [
								[app.mouse_coords[1] + l, app.mouse_coords[0] + c],
							]
						}
					}
				}
			}
		}
	}
}

fn (mut app App) draw() {
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(unsafe { &u8(&app.screen_pixels) })
	app.gg.draw_image(x_offset, y_offset, nb_tiles, nb_tiles, istream_image)
}

fn graphics_init(mut app App) {
	app.istream_idx = app.gg.new_streaming_image(nb_tiles, nb_tiles, 4, pixel_format: .rgba8)
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { app.gg.quit() }
				.up { app.paint_type += 1 }
				.down { app.paint_type -= 1 }
				else {}
			}
		}
		.mouse_up {
			match e.mouse_button {
				.left {
					app.mouse_held = false
				}
				else {}
			}
		}
		.mouse_down {
			match e.mouse_button {
				.left {
					if in_rect(e.mouse_x, e.mouse_y, x_offset, y_offset, nb_tiles + x_offset,
						nb_tiles + y_offset)
					{
						app.mouse_held = true
					}
					if in_rect(e.mouse_x, e.mouse_y, 5, 37, 29, 61) {
						app.paint_type = 1
					} else if in_rect(e.mouse_x, e.mouse_y, 5, 72, 29, 96) {
						app.paint_type = 2
					}
					if in_rect(e.mouse_x, e.mouse_y, 37, 5, 61, 29) {
						app.paint_size = 4
					} else if in_rect(e.mouse_x, e.mouse_y, 72, 5, 96, 29) {
						app.paint_size = 8
					} else if in_rect(e.mouse_x, e.mouse_y, 107, 5, 131, 29) {
						app.paint_size = 12
					} else if in_rect(e.mouse_x, e.mouse_y, 142, 5, 166, 29) {
						app.paint_size = 16
					} else if in_rect(e.mouse_x, e.mouse_y, 177, 5, 201, 29) {
						app.paint_size = 20
					}
				}
				else {}
			}
		}
		.mouse_scroll {
			app.paint_size += int(math.sign(e.scroll_y)) * 4
		}
		else {}
	}
	if app.mouse_held {
		app.mouse_coords[0] = int(e.mouse_x) - x_offset
		app.mouse_coords[1] = int(e.mouse_y) - y_offset
	}
}

fn in_rect(input_x f64, input_y f64, x f64, y f64, x1 f64, y1 f64) bool {
	if input_x >= x && input_x <= x1 && input_y >= y && input_y <= y1 {
		return true
	} else {
		return false
	}
}
