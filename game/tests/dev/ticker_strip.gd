extends SceneTree
## Dev tool (animator, M1): a deterministic frame strip of the ticker's page change, rendered by the
## engine itself in 16 ms steps (the browser capture in tools/web/motion_web.mjs is too coarse on a
## loaded machine to catch a 240 ms roll reliably). A three-page headline at the 324 clip; frames from
## 32 ms before the first page change to 32 ms after it, motion and reduced motion, at logical px
## (1 art px = 4 px), plus a JSON index {frames: [{t, file}]} for the contact sheet.
##   xvfb-run -a godot --path game -s res://tests/dev/ticker_strip.gd -- --out=<dir>

const HEAD := "ההייטקיסטים יוצאים לרחובות שוב, והפעם עם שלטים חדשים ועם כובע של קוסם ישן מהטלוויזיה"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var out := "user://ticker_strip"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	Content.load_from(Content.PATH)
	var TickerS: GDScript = load("res://scripts/ui/ticker.gd")
	for reduced: bool in [false, true]:
		var sv := SubViewport.new()
		sv.size = Vector2i(L.W, 84)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sv.transparent_bg = false
		root.add_child(sv)
		var t: Node2D = TickerS.new()
		sv.add_child(t)
		await process_frame
		t.call("set_reduced_motion", reduced)
		t.call("defer_until", 0.0)
		t.call("enqueue", "flavor", HEAD)
		t.call("update_view", 16.0)
		var dwell: float = float(t.get("_dwell"))
		t.call("update_view", dwell - 48.0)
		var tag := "rm" if reduced else "roll"
		var frames: Array = []
		var ms := -32.0
		var end := (float(TickerS.get("FADE_MS")) if reduced else float(TickerS.get("ROLL_MS"))) + 32.0
		while ms <= end:
			t.call("update_view", 16.0)
			await RenderingServer.frame_post_draw
			var img := sv.get_texture().get_image()
			var file := "%s/ticker-strip-%s-%03d.png" % [out, tag, frames.size()]
			img.save_png(file)
			frames.append({"t": int(ms), "file": file})
			ms += 16.0
		var f := FileAccess.open("%s/ticker-strip-%s.json" % [out, tag], FileAccess.WRITE)
		f.store_string(JSON.stringify({"frames": frames, "note": "t = ms from the page change's f0; logical px"}))
		f.close()
		print("%s: %d frames (first-page dwell %.0f ms)" % [tag, frames.size(), dwell])
		sv.queue_free()
	quit(0)
