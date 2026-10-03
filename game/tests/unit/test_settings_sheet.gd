extends RefCounted
## The settings sheet (O7) after the manual test of 2026-09-30:
## A6 every row is reachable on every phone: on the SE and taller phones the whole sheet shows with no
##    scroll (the sheet may rise to Row A's bottom), on the short 375×548 the group headers tighten, and
##    past that the body scrolls with a visible thumb and every row can be brought wholly into view;
## A8 the switch shows its state: ON = flag fill, knob left (RTL mirror), "פועל"; OFF = grey, knob
##    right, "כבוי".
## The real scene is booted at phone backing stores in a SubViewport (as test_mobile_layout.gd).

var runner: Object
var tree: SceneTree
var dir := ""
var sv: SubViewport
var m: Node
var _saved := {}

const ROWS := ["sfx", "music", "reducedMotion", "largeText", "help", "about", "reset"]


func setup(r: Object) -> void:
	tree = r as SceneTree
	dir = "user://test_settings_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	_saved = {"S": L.stage_h, "P": L.panel_h, "n": L.rows_whole, "cw": L.cw, "tabs": L.tabs_up}


func teardown() -> void:
	_free()
	Display.update(Vector2(720, 1280))
	L.stage_h = _saved["S"]
	L.panel_h = _saved["P"]
	L.rows_whole = _saved["n"]
	L.set_width(_saved["cw"])
	L.tabs_up = _saved["tabs"]
	PxText.large_text = false
	TestFixture.use_game_content()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _free() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
	if sv and is_instance_valid(sv):
		sv.get_parent().remove_child(sv)
		sv.queue_free()
	sv = null
	m = null


func _boot(dev: Vector2i) -> void:
	_free()
	TestFixture.use_game_content()
	sv = SubViewport.new()
	sv.size = dev
	tree.root.add_child(sv)
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	sv.add_child(m)
	for i in 3:
		await tree.process_frame


func _open() -> Overlay:
	m._open_settings()
	for i in 2:
		await tree.process_frame
	var o: Overlay = m.overlays.top()
	return o if o != null and o.id == "SETTINGS" else null


func _row(o: Overlay, id: String) -> PxButton:
	for b: PxButton in o.body_focusables:
		if str(b.get_meta("row", "")) == id:
			return b
	return null


## A row's hit is wholly inside the clip at the current scroll (panel coordinates).
func _in_clip(o: Overlay, b: PxButton) -> bool:
	var top := b.hit.position.y - o.scroll
	var bottom := b.hit.end.y - o.scroll
	return top >= o.clip_rect.position.y - 0.5 and bottom <= o.clip_rect.end.y + 0.5


## Every row, whole, either now or at some scroll; the fixed "סגור" on screen under the clip.
func _check_reach(o: Overlay, name: String, want_no_scroll: bool) -> void:
	var ids: Array = o.body_focusables.map(func(b: PxButton) -> String: return str(b.get_meta("row", "")))
	runner.check(ROWS.all(func(k: String) -> bool: return ids.has(k)), "%s: every row is built (%s)" % [name, str(ids)])
	if want_no_scroll:
		var hidden: Array = ids.filter(func(k: String) -> bool: return not _in_clip(o, _row(o, k)))
		runner.check(o.max_scroll() == 0.0 and hidden.is_empty(), "%s: the whole sheet shows, no scroll (max %d; hidden %s)" % [name, o.max_scroll(), str(hidden)])
	var unreachable: Array = []
	for k: String in ids:
		var b := _row(o, k)
		o.set_scroll(b.hit.end.y - o.clip_rect.end.y)   # bring its bottom to the clip's bottom (clamped)
		if not _in_clip(o, b):
			o.set_scroll(b.hit.position.y - o.clip_rect.position.y)
		if not _in_clip(o, b):
			unreachable.append(k)
	o.set_scroll(0.0)
	runner.check(unreachable.is_empty(), "%s: every row can be brought wholly into view (%s)" % [name, str(unreachable)])
	var vis_h := float(m._vs.y) - float(m._ovl_y)
	var close: PxButton = null
	for b: PxButton in o.focusables:
		if b.label != null and b.label.text == Strings.s("SYS_CLOSE"):
			close = b
	runner.check(close != null and close.visual.position.y >= o.clip_rect.end.y and close.visual.end.y <= vis_h + 0.5,
		"%s: the fixed \"סגור\" on screen under the rows (%s; screen bottom %d)" % [name, close.visual if close else "none", vis_h])
	runner.check(o.panel_rect.position.y >= float(m._top_y) + float(L.ROW_A_H) - float(m._ovl_y) - 0.5, "%s: the sheet never covers Row A" % name)


func test_the_se_shows_every_row_without_scrolling() -> void:
	await _boot(Vector2i(750, 1334))
	var o := await _open()
	runner.check(o != null, "SE: the sheet opens")
	if o != null:
		_check_reach(o, "SE 375×667@2", true)
		runner.check(not (o as Overlays.SettingsOverlay).compact, "SE: the roomy group headers still fit")


func test_the_390_is_unchanged() -> void:
	await _boot(Vector2i(1170, 2532))
	var o := await _open()
	if o != null:
		_check_reach(o, "390×844@3", true)
		var content := o.content_bottom - o.clip_rect.position.y + 104.0 + 112.0 + 8.0
		runner.check(o.panel_rect.size.y <= floorf(0.70 * float(m._vs.y) / 4.0) * 4.0 + float(m.bottom_inset()), "390: the sheet stays within 70%% (%d; content %d)" % [o.panel_rect.size.y, content])


func test_the_short_375x548_tightens_and_every_row_fits() -> void:
	await _boot(Vector2i(750, 1096))
	var o := await _open()
	runner.check(o != null, "375×548: the sheet opens")
	if o != null:
		# 2026-10-03: the "איך זה עובד" row makes the shortest phone scroll; every row stays reachable
		_check_reach(o, "375×548@2", false)
		runner.check((o as Overlays.SettingsOverlay).compact, "375×548: the group headers tighten")
		var short_rows: Array = o.body_focusables.filter(func(b: PxButton) -> bool: return b.hit.size.y < 88.0)
		runner.check(short_rows.is_empty(), "375×548: every row keeps its 88 touch height (44 CSS)")


func test_large_text_on_the_short_screen_scrolls_with_a_thumb() -> void:
	await _boot(Vector2i(750, 1096))
	m.set_setting("largeText", true)
	await tree.process_frame
	var o := await _open()
	if o == null:
		runner.check(false, "the sheet opens")
		return
	runner.check(o.max_scroll() > 0.0, "large text at 375×548: the body scrolls (%d)" % o.max_scroll())
	o.tick(16.0)
	runner.check(o._thumb != null and o._thumb.visible and o._thumb.position.x < 40.0, "a scroll thumb shows on the left edge (RTL)")
	_check_reach(o, "375×548@2 large", false)


func test_the_switch_shows_its_state() -> void:
	await _boot(Vector2i(750, 1334))
	var o := await _open()
	if o == null:
		runner.check(false, "the sheet opens")
		return
	var so := o as Overlays.SettingsOverlay
	for key: String in ["music", "sfx"]:
		for want: bool in [true, false]:
			if m.setting_on(key) != want:
				m.toggle_setting(key)
			so.sync()
			var sw: Dictionary = so._switches[key]
			var v: Overlays.SettingSwitch = sw["view"]
			var st: PxText = sw["state"]
			var k := v.knob_rect()
			if want:
				runner.check(v.on and k.get_center().x < v.SIZE.x / 2.0 and st.text == Strings.s("SET_ON") and st.tint == Overlays.SettingSwitch.C_ON,
					"%s ON: flag fill, knob left (RTL mirror), \"%s\" in flag" % [key, st.text])
			else:
				runner.check(not v.on and k.get_center().x > v.SIZE.x / 2.0 and st.text == Strings.s("SET_OFF") and st.tint == Overlays.SettingSwitch.C_OFF_TEXT,
					"%s OFF: grey, knob right, \"%s\" in slate" % [key, st.text])
	runner.check(Strings.s("SET_ON") == "פועל" and Strings.s("SET_OFF") == "כבוי", "the state words")
	var on_px := Overlays.SettingSwitch.new()
	runner.check(on_px.knob_rect().size == Vector2(44, 44) and fmod(on_px.knob_rect().position.x, 4.0) == 0.0, "the knob on the 4-px grid")
	on_px.free()
