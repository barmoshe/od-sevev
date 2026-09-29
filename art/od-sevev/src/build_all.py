"""Rebuild every od-sevev graphic-tier asset, the manifest, and the proofs:  python3 build_all.py"""
import palette  # noqa: F401  (writes nothing on import)
import ui_chat, ui_controls, ui_meters, ui_widgets, wordmark, ui_events, props, ui_share, wave2, sources, dubi_small, wave5, wave6, wave7, leaders, keyart, proofs
from kit import write_manifest, REGISTRY

if __name__ == "__main__":
    import runpy, os
    runpy.run_path(os.path.join(os.path.dirname(__file__), "palette.py"), run_name="__main__")
    for m in (ui_chat, ui_controls, ui_meters, ui_widgets, wordmark, ui_events, props, ui_share, wave2, sources, dubi_small, wave5, wave6, wave7, leaders):
        m.build()
    print(write_manifest(), len(REGISTRY), "pieces")
    print(wave7.proof())
    keyart.build()
    fails, over = proofs.build()
    print("contrast fails:", fails, "| receipt overflow:", over)
