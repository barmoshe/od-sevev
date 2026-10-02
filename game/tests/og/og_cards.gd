extends RefCounted
## The share platform's offline renders (tools/og.sh; needs a renderer: a display, or xvfb-run on a
## headless Linux). Two modes:
##   --mode=og       every /s/<variant>/ stub's link-preview JPEG (1200×630, ShareCards' OG layout)
##                   into --out (default res://web/og/, the build copies them; ≤ 250 KB each)
##   --mode=preview  every card kind × square / story × as-is / family-safe on a made-up veteran
##                   round, as PNGs into --out (the design loop; not shipped)
## The OG headlines are the OG_S_* / OG_N_* strings (the same copy as the stubs' og:title).

var tree: SceneTree
var out_dir := "res://web/og/"
var mode := "og"
var only := ""


func start(t: SceneTree) -> void:
	tree = t
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--only="):
			only = a.substr(7)
	if not out_dir.ends_with("/"):
		out_dir += "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir)
	Content.load_from(Content.PATH)
	Politics.install()
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("gen_cards: no renderer (run with a display or xvfb-run, see tools/og.sh)")
		tree.quit(2)
		return
	var n := 0
	if mode == "preview":
		n = await _previews()
	else:
		n = await _ogs()
	print("gen_cards: %d images in %s" % [n, out_dir])
	tree.quit(0)


static func og_variants() -> Dictionary:
	return ShareKit.og_variants()


func _ogs() -> int:
	var n := 0
	var vs := og_variants()
	for name: String in vs:
		if only != "" and not name.contains(only):
			continue
		var img := await _render("og", "og", vs[name])
		var path := out_dir + name + ".jpg"
		var q := 0.86
		var buf := img.save_jpg_to_buffer(q)
		while buf.size() > 250 * 1024 and q > 0.5:
			q -= 0.06
			buf = img.save_jpg_to_buffer(q)
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_buffer(buf)
		f.close()
		n += 1
	# the stubs' manifest (tools/lib/gen_share_stubs.py): every variant's og:title and leader
	if only == "":
		var mf := FileAccess.open(out_dir + "variants.json", FileAccess.WRITE)
		mf.store_string(JSON.stringify(vs, "\t", true))
		mf.close()
	return n


func _render(kind: String, fmt: String, m: Dictionary, s: GameState = null) -> Image:
	var vp := SubViewport.new()
	vp.size = ShareCards.size_of(fmt)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var root_n := Node2D.new()
	vp.add_child(root_n)
	if fmt == "og":
		ShareCards.build(root_n, kind, m, "og")
	else:
		ShareDesk.build_card(root_n, kind, m, fmt, s, Economy.derive(s) if s != null else null)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	vp.queue_free()
	return img


## A veteran's round: Smotrich's... no, the leader in --only (default bibi), 4 past rounds, a seeded
## chat, the gate reached at 7:42.
func _veteran(leader: String) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, leader)
	s.evolutions = 4
	s.run_time_sec = 640.0
	s.run_bananas = 4.2e6
	s.all_time_bananas = 9.9e7
	for id in Content.producer_ids().slice(0, 5):
		s.owned[id] = 12
	ShareDesk.seed_demo_chat(s)
	s.round_log = {"gateSec": 462.0, "court0": 0, "left0": 0}
	s.investigation["courtDays"] = 2
	s.investigation["postponements"] = 3
	var ids: Array = ShareKit.STUB_LEADERS
	for i in 4:
		s.history.append({"n": i + 1, "leader": ids[(i * 3) % ids.size()], "sec": 900.0 - 60.0 * i, "gate": 700.0 - 90.0 * i,
			"earned": 1.0e7 * (i + 1), "top": Content.producer_ids()[i], "topPct": 0.45 + 0.04 * i, "paid": 4 + i,
			"mvp": "smotrich", "left": i % 2, "court": i % 3, "post": i})
	s.stats["hazardDays"] = 6.0
	return s


func _previews() -> int:
	var leader := only if only != "" else "bibi"
	var s := _veteran(leader)
	var d := Economy.derive(s)
	var n := 0
	var exts := {"challenge": {"leader": leader, "secs": 462.0, "seed": 1234, "url_hash": "s=1234&t=462"},
		"daily": {"n": 17, "grid_text": "🟩🟩🟨🟥🟩\n🟨🟩🟩🟩🟥\n🟩🟩🟩🟩🟩", "url_hash": "d=17"}}
	for kind: String in ["leak", "breaking", "term", "career", "challenge", "daily", "receipt", "result"]:
		for fmt: String in ["sq", "story"]:
			for neutral: bool in [false, true]:
				if neutral and (kind == "receipt" or kind == "result" or kind == "daily"):
					continue
				var m := ShareKit.model(kind, s, d, exts.get(kind, {}), {"neutral": neutral})
				var img := await _render(kind, fmt, m, s)
				img.save_png(out_dir + "%s-%s%s.png" % [kind, fmt, "-n" if neutral else ""])
				n += 1
	for name: String in ["bibi-61", "smotrich-leak", "all-term", "daily", "bengvir-challenge"]:
		var img2 := await _render("og", "og", og_variants()[name])
		img2.save_png(out_dir + "og-%s.png" % name)
		n += 1
	return n
