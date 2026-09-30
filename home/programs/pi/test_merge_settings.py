import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "merge_settings", Path(__file__).with_name("merge-settings.py")
)
merge_settings = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge_settings)


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "shared.json"
        self.agent = self.root / "agent"
        self.agent.mkdir()
        self.settings = self.agent / "settings.json"

    def deploy(self, shared):
        self.source.write_text(json.dumps(shared))
        merge_settings.deploy(self.source, self.agent)
        return json.loads(self.settings.read_text())

    def test_fresh_install_is_writable_and_idempotent(self):
        self.assertEqual(self.deploy({"quietStartup": True}), {"quietStartup": True})
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual(stat.S_IMODE(self.settings.stat().st_mode), 0o600)
        modified = self.settings.stat().st_mtime_ns
        self.deploy({"quietStartup": True})
        self.assertEqual(self.settings.stat().st_mtime_ns, modified)

    def test_provider_state_and_unmanaged_preferences_survive(self):
        local = {
            "defaultProvider": "local-provider",
            "defaultModel": "local-model",
            "enabledModels": ["local-provider/*"],
            "lastChangelogVersion": "example",
            "terminal": {"showImages": True, "clearOnShrink": True},
            "skills": ["local-skill"],
        }
        self.settings.write_text(json.dumps(local))
        for name in ["auth.json", "models.json", "models-store.json"]:
            (self.agent / name).write_text("private state")
        shared = {"terminal": {"showImages": False}, "skills": ["shared-skill"]}
        result = self.deploy(shared)
        expected = dict(local)
        expected["terminal"] = {"showImages": False, "clearOnShrink": True}
        expected["skills"] = ["shared-skill"]
        self.assertEqual(result, expected)
        for name in ["auth.json", "models.json", "models-store.json"]:
            self.assertEqual((self.agent / name).read_text(), "private state")
        self.assertEqual(self.deploy({}), {
            key: value for key, value in local.items() if key not in ["terminal", "skills"]
        } | {"terminal": {"clearOnShrink": True}})

    def test_activation_restores_managed_preferences_after_pi_edits(self):
        self.deploy({"quietStartup": True})
        self.settings.write_text('{"quietStartup": false, "defaultModel": "new-model"}')
        self.assertEqual(self.deploy({"quietStartup": True}), {
            "quietStartup": True, "defaultModel": "new-model"
        })

    def test_invalid_local_json_is_preserved(self):
        self.settings.write_text("{invalid")
        with self.assertRaises(json.JSONDecodeError):
            self.deploy({"quietStartup": True})
        self.assertEqual(self.settings.read_text(), "{invalid")
        self.assertFalse((self.agent / "settings.json.lock").exists())

    def test_shared_provider_settings_are_rejected_before_writing(self):
        self.settings.write_text('{"theme": "dark"}')
        for key in merge_settings.PROVIDER_SETTINGS:
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.deploy({key: "must stay local"})
        self.assertEqual(self.settings.read_text(), '{"theme": "dark"}')

    def test_existing_pi_lock_prevents_overwriting_settings(self):
        self.settings.write_text('{"theme": "dark"}')
        lock = self.agent / "settings.json.lock"
        lock.mkdir()
        with self.assertRaises(RuntimeError):
            self.deploy({"quietStartup": True})
        self.assertEqual(self.settings.read_text(), '{"theme": "dark"}')
        self.assertTrue(lock.exists())

    def test_store_symlink_is_preserved(self):
        original = self.root / "original.json"
        original.write_text('{"theme": "dark"}')
        self.settings.symlink_to(original)
        with self.assertRaises(ValueError):
            self.deploy({"quietStartup": True})
        self.assertTrue(self.settings.is_symlink())
        self.assertEqual(original.read_text(), '{"theme": "dark"}')


if __name__ == "__main__":
    unittest.main()
