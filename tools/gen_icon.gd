extends SceneTree
## Procedural app icon (phase 8): the fork's stand-in sprite on the deep-grape ground with a pink rim, drawn
## from the same sprite grid as the game (res://data/art.json). Writes every size the exports need
## into res://assets/icon/. Run: tools/icon.sh. Deterministic.

const OUT := "res://assets/icon/"


func _initialize() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art.json"))
	var pal := {}
	for c: String in art["palette"]:
		var hex: String = art["palette"][c]
		pal[c] = Color(0, 0, 0, 0) if hex == "transparent" else Color.html(hex)
	var bb: Dictionary = art["sprites"]["magicianStandIn"]
	var rows: Array = bb["frames"][0]
	# 64x64 art canvas: grape ground, a pink ring, the sprite centred.
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	img.fill(pal["U"])
	for y in n:
		for x in n:
			var dx := x - n / 2.0 + 0.5
			var dy := y - n / 2.0 + 0.5
			var r := sqrt(dx * dx + dy * dy)
			if r > 26.0 and r <= 29.0:
				img.set_pixel(x, y, pal["q"])
			elif r > 29.0 and r <= 30.0:
				img.set_pixel(x, y, pal["Q"])
	var w := int(bb["w"])
	var h := int(bb["h"])
	var ox := (n - w) / 2
	var oy := (n - h) / 2 + 1
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row[x]
			if ch != "." and pal.has(ch) and pal[ch].a > 0.0:
				img.set_pixel(ox + x, oy + y, pal[ch])
	var sizes := {"icon_1024.png": 1024, "pwa_512.png": 512, "pwa_180.png": 180, "pwa_144.png": 144, "android_192.png": 192}
	for f: String in sizes:
		var o := img.duplicate() as Image
		o.resize(sizes[f], sizes[f], Image.INTERPOLATE_NEAREST)
		o.save_png(OUT + f)
	# Android adaptive: the background is flat grape, the foreground is the sprite alone (66% safe zone).
	var bg := Image.create_empty(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(pal["U"])
	bg.save_png(OUT + "android_bg_432.png")
	var fg := Image.create_empty(108, 108, false, Image.FORMAT_RGBA8)
	var fox := (108 - w) / 2
	var foy := (108 - h) / 2
	for y in h:
		var row2: String = rows[y]
		for x in w:
			var ch2 := row2[x]
			if ch2 != "." and pal.has(ch2) and pal[ch2].a > 0.0:
				fg.set_pixel(fox + x, foy + y, pal[ch2])
	fg.resize(432, 432, Image.INTERPOLATE_NEAREST)
	fg.save_png(OUT + "android_fg_432.png")
	print("icons written")
	quit(0)
