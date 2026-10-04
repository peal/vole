"""Assisted-by: OpenAI Codex (GPT-6), benchmark failure-path tests."""
import os
from pathlib import Path
import subprocess
import shlex
import tempfile
import unittest

import normalisers


class BenchmarkTests(unittest.TestCase):
    def test_non_object_input_is_rejected(self):
        with self.assertRaises(ValueError):
            normalisers.validate_instance([])

    def test_unknown_oracle_is_not_verification(self):
        observation = {"status": "finished", "result": {
            "valid_subgroup": True, "oracle_available": False}}
        self.assertEqual(normalisers.verification_status(observation), "oracle_unavailable")

    def test_equal_order_wrong_group_is_wrong(self):
        observation = {"status": "finished", "result": {
            "valid_subgroup": True, "oracle_available": True,
            "order_matches": True, "equal": False}}
        self.assertEqual(normalisers.verification_status(observation), "wrong")

    def test_invalid_subgroup_is_wrong_without_oracle(self):
        observation = {"status": "finished", "result": {
            "valid_subgroup": False, "oracle_available": False}}
        self.assertEqual(normalisers.verification_status(observation), "wrong")

    def test_explicit_degree_preserves_fixed_points(self):
        normalisers.validate_instance({"id": "fixed", "degree": 4,
            "generators": [[2, 1, 3, 4]]})
        with self.assertRaises(ValueError):
            normalisers.validate_instance({"id": "truncated", "degree": 4,
                "generators": [[2, 1]]})

    @unittest.skipUnless(os.name == "posix", "POSIX process groups required")
    def test_timeout_kills_descendants(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            child_pid = directory / "child.pid"
            executable = directory / "fake-gap"
            executable.write_text(
                "#!/bin/sh\n"
                "/bin/sleep 30 &\n"
                f"echo $! > {shlex.quote(str(child_pid))}\n"
                "wait\n")
            executable.chmod(0o755)
            observation = normalisers.run_worker(
                str(executable), {}, 0.5, directory, "timeout")
            self.assertEqual(observation["status"], "timeout")
            self.assertTrue(child_pid.exists())
            # A killed orphan can briefly remain a zombie; it must not run.
            probe = subprocess.run(["ps", "-o", "stat=", "-p", child_pid.read_text()],
                capture_output=True, text=True)
            self.assertTrue(not probe.stdout.strip() or probe.stdout.strip().startswith("Z"))


if __name__ == "__main__":
    unittest.main()
