class_name TestFixture
extends RefCounted
## od-sevev: the fork's unit tests (economy, meta, story, save, pacing, fmt) pin the Monkey
## Bananas v2.1.0 content they were written against (tests/fixtures/content.fork.json), so they
## keep testing the engine while design/content.json is rewritten in Hebrew with new ids and
## numbers. The Hebrew content is exercised by the integration test (test_input boots the real
## scene), tools/balance.sh and the content's own sim tests.

const FORK_CONTENT := "res://tests/fixtures/content.fork.json"


static func use_fork_content() -> void:
	Content.load_from(FORK_CONTENT)


static func use_game_content() -> void:
	Content.load_from(Content.PATH)
