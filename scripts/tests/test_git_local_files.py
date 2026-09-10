import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1]


class GitLocalFilesTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name) / "repo"
        self.repo.mkdir()
        self.env = {
            key: value for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        self.env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        self.write("AGENTS.md", "original\n")
        self.write(".agents/tracked.md", "original\n")
        self.write("unrelated.md", "original\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Initial files")
        self.exclude = self.repo / ".git/info/exclude"

    def run_command(self, args, cwd=None, check=True, input=None):
        return subprocess.run(
            args, cwd=cwd or self.repo, env=self.env,
            text=True, capture_output=True, check=check, input=input,
        )

    def git(self, *args, cwd=None):
        return self.run_command(["git", *args], cwd=cwd).stdout

    def script(self, action, *paths, cwd=None, check=True, input=None):
        return self.run_command(
            [str(SCRIPTS / f"git-local-{action}"), *paths],
            cwd=cwd, check=check, input=input,
        )

    def write(self, name, content):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def test_round_trip_preserves_edits_and_unrelated_rules(self):
        self.exclude.write_text("# Custom rules\n/keep-me\n")
        self.git("update-index", "--skip-worktree", "unrelated.md")
        self.write("AGENTS.md", "edited\n")
        self.write(".agents/new.md", "new\n")
        self.write("docs/agents/domain.md", "new docs\n")
        original_index = self.git("ls-files", "--stage")
        original_status = self.git("status", "--porcelain")
        paths = ("AGENTS.md", ".agents", "docs/agents")
        self.script("ignore", *paths)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertIn("S AGENTS.md", self.git("ls-files", "-v"))
        self.script("restore", *paths)
        self.assertEqual(self.git("status", "--porcelain"), original_status)
        self.assertEqual(self.git("ls-files", "--stage"), original_index)
        self.assertEqual((self.repo / "AGENTS.md").read_text(), "edited\n")
        self.assertEqual((self.repo / "docs/agents/domain.md").read_text(), "new docs\n")
        self.assertIn("S unrelated.md", self.git("ls-files", "-v"))
        self.assertIn("# Custom rules\n/keep-me\n", self.exclude.read_text())

    def test_repeated_calls_and_legacy_patterns(self):
        self.exclude.write_text("/AGENTS.md\n/.agents/\n/docs/agents/\n")
        paths = ("AGENTS.md", ".agents", "docs/agents")
        before = self.exclude.read_bytes()
        self.script("ignore", *paths)
        self.script("ignore", *paths)
        self.assertEqual(self.exclude.read_bytes(), before)
        self.script("restore", *paths)
        self.script("restore", *paths)
        self.assertEqual(self.exclude.read_text(), "")

    def test_paths_from_subdirectory_and_absolute_paths(self):
        subdirectory = self.repo / ".agents"
        self.write("AGENTS.md", "edited\n")
        self.write(".agents/tracked.md", "edited\n")
        paths = ("../AGENTS.md", str(subdirectory))
        self.script("ignore", *paths, cwd=subdirectory)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.script("restore", *paths, cwd=subdirectory)
        self.assertIn("H AGENTS.md", self.git("ls-files", "-v"))
        self.assertIn("H .agents/tracked.md", self.git("ls-files", "-v"))

    def test_special_characters_are_literal(self):
        names = ("a*b", "a?b", "[ab]", "with space ", "back\\slash", "!file", "#file", ":(glob)*")
        for name in names:
            self.write(name, "original\n")
        self.git("add", "--all")
        self.git("commit", "-qm", "Special paths")
        for name in names:
            self.write(name, "edited\n")
        self.script("ignore", *names)
        self.assertEqual(self.git("status", "--porcelain"), "")
        for name in names:
            self.git("check-ignore", "--quiet", "--no-index", "--", f"./{name}")
        neighbor = self.write("axb", "not ignored\n")
        self.assertNotEqual(self.run_command(["git", "check-ignore", "--", str(neighbor)], check=False).returncode, 0)
        self.script("restore", *names)
        self.assertNotIn("S ", self.git("ls-files", "-v"))
        self.assertNotEqual(self.git("status", "--porcelain"), "")

    def test_deleted_tracked_files_stay_deleted(self):
        (self.repo / "AGENTS.md").unlink()
        self.script("ignore", "AGENTS.md")
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.script("restore", "AGENTS.md")
        self.assertFalse((self.repo / "AGENTS.md").exists())
        self.assertIn(" D AGENTS.md", self.git("status", "--porcelain"))

    def test_invalid_paths_fail_before_mutating_metadata(self):
        original_exclude = self.exclude.read_bytes()
        original_flags = self.git("ls-files", "-v")
        for path in ("..", ".", ".git", ".git/config", "line\nbreak", "line\rbreak"):
            with self.subTest(path=path):
                result = self.script("ignore", "AGENTS.md", path, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.exclude.read_bytes(), original_exclude)
                self.assertEqual(self.git("ls-files", "-v"), original_flags)

    def test_help_missing_arguments_and_option_like_paths(self):
        for action in ("ignore", "restore", "show"):
            self.assertIn("Usage:", self.script(action, "--help").stdout)
            self.assertNotEqual(self.script(action, "--", check=False).returncode, 0)
        self.assertNotEqual(self.script("ignore", check=False).returncode, 0)
        self.script("ignore", "--", "--help")
        self.assertIn("/--help", self.exclude.read_text())
        self.script("restore", "--", "--help")
        self.assertNotIn("/--help", self.exclude.read_text())

    def test_sparse_checkout_and_non_repository_are_refused(self):
        self.git("config", "core.sparseCheckout", "true")
        for action in ("ignore", "restore"):
            result = self.script(action, "AGENTS.md", check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("sparse checkout", result.stderr)
            self.assertNotEqual(self.script(action, "AGENTS.md", cwd=self.repo.parent, check=False).returncode, 0)

    def test_linked_worktree_uses_its_index_and_shared_excludes(self):
        worktree = self.repo.parent / "linked"
        self.git("worktree", "add", "-qb", "linked", str(worktree))
        self.script("ignore", "AGENTS.md", cwd=worktree)
        self.assertIn("/AGENTS.md", self.exclude.read_text())
        self.assertIn("S AGENTS.md", self.git("ls-files", "-v", cwd=worktree))
        self.assertIn("H AGENTS.md", self.git("ls-files", "-v"))
        self.script("restore", "AGENTS.md", cwd=worktree)
        self.assertNotIn("/AGENTS.md", self.exclude.read_text())
        self.assertIn("H AGENTS.md", self.git("ls-files", "-v", cwd=worktree))

    def test_future_paths_and_missing_exclude_file(self):
        self.exclude.unlink()
        self.script("restore", "future")
        self.assertFalse(self.exclude.exists())
        self.script("ignore", "future")
        self.write("future", "new\n")
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.script("restore", "future")
        self.assertIn("?? future", self.git("status", "--porcelain"))

    def test_show_lists_local_excludes_and_all_skipped_paths(self):
        self.exclude.write_text("# Local rules\n/.agents/\n*.log\n/cache/*\n")
        self.script("ignore", "AGENTS.md", "future dir")
        self.git("update-index", "--skip-worktree", "unrelated.md")
        self.git("update-index", "--assume-unchanged", "unrelated.md")
        self.assertEqual(
            self.script("show").stdout.splitlines(),
            [".agents", "AGENTS.md", "future dir", "unrelated.md"],
        )
        self.assertEqual(
            self.script("show", cwd=self.repo / ".agents").stdout.splitlines(),
            [".", "../AGENTS.md", "../future dir", "../unrelated.md"],
        )

    def test_show_pipes_to_restore_from_subdirectory(self):
        self.write("AGENTS.md", "edited\n")
        self.write(".agents/tracked.md", "edited\n")
        (self.repo / "unrelated.md").unlink()
        names = ("--help", "with space ", "literal*", "back\\slash", "future")
        self.script("ignore", "AGENTS.md", ".agents", "unrelated.md", *names)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.run_command(
            ["bash", "-o", "pipefail", "-c", '"$1" | "$2"', "test",
             str(SCRIPTS / "git-local-show"), str(SCRIPTS / "git-local-restore")],
            cwd=self.repo / ".agents",
        )
        self.assertEqual(self.script("show").stdout, "")
        self.assertEqual((self.repo / "AGENTS.md").read_text(), "edited\n")
        self.assertEqual((self.repo / ".agents/tracked.md").read_text(), "edited\n")
        self.assertFalse((self.repo / "unrelated.md").exists())
        for name in names:
            self.assertFalse((self.repo / name).exists())
        self.assertNotEqual(self.git("status", "--porcelain"), "")

    def test_show_decodes_untracked_literal_paths(self):
        names = ("literal*", "with space ", "back\\slash", "[ab]", "q?", "--help")
        self.script("ignore", "--", *names)
        self.assertEqual(set(self.script("show").stdout.splitlines()), set(names))
        self.script("restore", input=self.script("show").stdout)
        self.assertEqual(self.script("show").stdout, "")

    def test_restore_empty_input_is_a_noop(self):
        self.exclude.unlink()
        self.assertEqual(self.script("show").stdout, "")
        flags = self.git("ls-files", "-v")
        self.script("restore", input="\n\n")
        self.assertEqual(self.git("ls-files", "-v"), flags)
        self.assertFalse(self.exclude.exists())

    def test_restore_reads_all_input_before_mutating(self):
        self.script("ignore", "AGENTS.md")
        excludes = self.exclude.read_bytes()
        flags = self.git("ls-files", "-v")
        result = self.script("restore", input="AGENTS.md\n../outside\n", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.exclude.read_bytes(), excludes)
        self.assertEqual(self.git("ls-files", "-v"), flags)
        self.script("restore", input="AGENTS.md")
        self.assertEqual(self.script("show").stdout, "")

    def test_show_in_linked_worktree(self):
        worktree = self.repo.parent / "linked"
        self.git("worktree", "add", "-qb", "linked", str(worktree))
        self.script("ignore", "AGENTS.md", cwd=worktree)
        self.git("update-index", "--skip-worktree", "unrelated.md", cwd=worktree)
        self.assertEqual(self.script("show", cwd=worktree).stdout, "AGENTS.md\nunrelated.md\n")
        self.assertEqual(self.script("show").stdout, "AGENTS.md\n")

    def test_show_refuses_sparse_checkout_and_non_repository(self):
        self.git("config", "core.sparseCheckout", "true")
        result = self.script("show", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sparse checkout", result.stderr)
        self.assertNotEqual(self.script("show", cwd=self.repo.parent, check=False).returncode, 0)

    def test_staged_changes_are_not_hidden(self):
        self.write("AGENTS.md", "staged\n")
        self.git("add", "AGENTS.md")
        self.script("ignore", "AGENTS.md")
        self.assertIn("M  AGENTS.md", self.git("status", "--porcelain"))


if __name__ == "__main__":
    unittest.main()
