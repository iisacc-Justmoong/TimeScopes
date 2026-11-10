import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import uuid
import ii_file_provider as fp

ROOT = Path(__file__).resolve().parents[1]

class BuildLayoutTests(unittest.TestCase):
    def test_xcode_build_configurations_disable_index_store(self):
        project = ROOT / "Time Scopes.xcodeproj/project.pbxproj"
        result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(project)],
                                check=True, capture_output=True, text=True)
        objects = json.loads(result.stdout)["objects"].values()
        configurations = [item["buildSettings"] for item in objects if item.get("isa") == "XCBuildConfiguration"]
        self.assertTrue(configurations)
        for settings in configurations:
            self.assertEqual(settings.get("COMPILER_INDEX_STORE_ENABLE"), "NO")

    def test_ci_records_results_outside_build_and_uses_project_build(self):
        state = ROOT / "resources/.state"
        fp.mkdir(state, parents=True, exist_ok=True)
        stamp = "layout-test-" + uuid.uuid4().hex
        result = ROOT / "resources/.state/test-results" / ("TimeScopes-" + stamp + ".xcresult")
        old_result = ROOT / "build/TestResults" / result.name
        with tempfile.TemporaryDirectory(dir=state) as temporary:
            tools = Path(temporary)
            capture = tools / "arguments.json"
            programs = {
                "date": "#!/bin/sh\nprintf '%s\\n' " + stamp + "\n",
                "xcrun": "#!/bin/sh\nprintf '%s\\n' '{\"targets\":[{\"name\":\"Time Scopes.app\",\"lineCoverage\":0.9}]}'\n",
                "xcodebuild": "#!/usr/bin/env python3\nimport json, os, sys\nfrom pathlib import Path\nimport ii_file_provider as fp\na=sys.argv[1:]\np=Path(a[a.index('-resultBundlePath')+1])\nfp.mkdir(p, parents=True, exist_ok=True)\nfp.write_text(os.environ['LAYOUT_CAPTURE'], json.dumps(a))\n",
            }
            for name, content in programs.items():
                file = tools / name
                fp.write_text(file, content)
                file.chmod(0o755)
            env = os.environ.copy()
            for key in ("DERIVED_DATA_PATH", "RESULTS_DIR", "RESULT_BUNDLE_PATH"):
                env.pop(key, None)
            env.update(PATH=str(tools) + os.pathsep + env.get("PATH", ""),
                       DESTINATION="platform=iOS Simulator,name=fixture", LAYOUT_CAPTURE=str(capture))
            try:
                subprocess.run([str(ROOT / "scripts/ci/run_tests_with_coverage.sh")], env=env,
                               cwd=ROOT, check=True, capture_output=True, text=True)
                args = json.loads(capture.read_text())
                self.assertEqual(args[args.index("-derivedDataPath")+1], str(ROOT / "build"))
                self.assertEqual(args[args.index("-resultBundlePath")+1], str(result))
            finally:
                for path in (result, old_result):
                    if path.exists(): shutil.rmtree(path)
