"""One command rebuilds every deliverable and proof from source: python3 build_all.py"""
import runpy, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
for m in ["palette", "hebfont", "wordmark", "lineup", "locations", "title", "icon", "proofs", "dodont", "bibi_variants", "bibi_v2_sheet", "squint"]:
    runpy.run_module(m, run_name="__main__")
