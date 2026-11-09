"""
Test cho tools/release.py bằng unittest (stdlib), không cần cài thêm gì:
    python -m unittest tools.test_release -v
hoặc
    python tools/test_release.py
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional, Sequence

sys.path.insert(0, str(Path(__file__).resolve().parent))
import release  # noqa: E402
from release import Ports, ProcessResult, ReleaseError  # noqa: E402

TODAY = date(2026, 11, 9)

CHANGELOG = """# Changelog

---

## [Unreleased]

### Đã sửa (Fixed)
- Sửa lỗi A.

---

## [0.1.0] - 2026-10-30

### Đã thêm (Added)
- Bản đầu.
"""


class FakeGit:
    """Giả lập git: ghi lại lệnh, trả kết quả theo kịch bản."""

    def __init__(self, status: str = "", branch: str = "main", local_tag: str = "", remote_tag: str = "") -> None:
        self.status = status
        self.branch = branch
        self.local_tag = local_tag
        self.remote_tag = remote_tag
        self.calls: List[List[str]] = []

    def __call__(self, cmd: Sequence[str], cwd: Path, capture: bool = False) -> ProcessResult:
        cmd = list(cmd)
        self.calls.append(cmd)
        if cmd[0] != "git":
            return ProcessResult(0)
        sub = cmd[1]
        if sub == "status":
            return ProcessResult(0, self.status)
        if sub == "rev-parse":
            return ProcessResult(0, self.branch + "\n")
        if sub == "tag" and cmd[2] == "-l":
            return ProcessResult(0, self.local_tag)
        if sub == "remote":
            return ProcessResult(0, "origin\n")
        if sub == "ls-remote":
            return ProcessResult(0, self.remote_tag)
        return ProcessResult(0)


def make_ports(answers: Sequence[str], git: FakeGit, which: Optional[Dict[str, Optional[str]]] = None):
    answers_iter = iter(answers)
    echoed: List[str] = []
    which = which if which is not None else {"git": "git", "flutter": "flutter", "gh": None}
    ports = Ports(
        ask=lambda prompt: next(answers_iter),
        echo=echoed.append,
        run=git,
        which=lambda name: which.get(name),
    )
    return ports, echoed


class TempRepo:
    def __init__(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="release-test-")
        self.root = Path(self._tmp.name)

    def add_kit(self, name: str, version: str = "0.1.0", changelog: Optional[str] = CHANGELOG) -> Path:
        kit = self.root / name
        kit.mkdir()
        (kit / "pubspec.yaml").write_text(
            f"name: {name}\ndescription: test\nversion: {version}\npublish_to: \"none\"\n", encoding="utf-8"
        )
        if changelog is not None:
            (kit / "CHANGELOG.md").write_text(changelog, encoding="utf-8")
        return kit

    def cleanup(self) -> None:
        self._tmp.cleanup()


class PureFunctionTests(unittest.TestCase):
    def test_calculate_next_version(self) -> None:
        self.assertEqual(release.calculate_next_version("0.2.1", "patch"), "0.2.2")
        self.assertEqual(release.calculate_next_version("0.2.1", "minor"), "0.3.0")
        self.assertEqual(release.calculate_next_version("0.2.1", "major"), "1.0.0")
        with self.assertRaises(ReleaseError):
            release.calculate_next_version("0.2", "patch")
        with self.assertRaises(ReleaseError):
            release.calculate_next_version("0.2.1", "huge")

    def test_tag_name(self) -> None:
        self.assertEqual(release.tag_name("pda_broadcast_kit", "0.2.1"), "pda_broadcast_kit-v0.2.1")

    def test_release_changelog_moves_unreleased_into_version(self) -> None:
        new_text, has_content = release.release_changelog(CHANGELOG, "0.1.1", TODAY)
        self.assertTrue(has_content)
        self.assertIn("## [Unreleased]\n\n---\n\n## [0.1.1] - 2026-11-09\n\n### Đã sửa (Fixed)\n- Sửa lỗi A.", new_text)
        self.assertEqual(new_text.count("## [Unreleased]"), 1)
        self.assertIn("## [0.1.0] - 2026-10-30", new_text)

    def test_release_changelog_reports_empty_unreleased(self) -> None:
        text = "# Changelog\n\n## [Unreleased]\n\n---\n\n## [0.1.0] - 2026-10-30\n- x\n"
        _, has_content = release.release_changelog(text, "0.1.1", TODAY)
        self.assertFalse(has_content)

    def test_release_changelog_requires_unreleased(self) -> None:
        with self.assertRaises(ReleaseError):
            release.release_changelog("# Changelog\n\n## [0.1.0] - 2026-10-30\n", "0.1.1", TODAY)

    def test_changelog_notes(self) -> None:
        new_text, _ = release.release_changelog(CHANGELOG, "0.1.1", TODAY)
        self.assertEqual(release.changelog_notes(new_text, "0.1.1"), "### Đã sửa (Fixed)\n- Sửa lỗi A.")
        self.assertIsNone(release.changelog_notes(new_text, "9.9.9"))


class PubspecTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repo = TempRepo()
        self.addCleanup(self.repo.cleanup)

    def test_read_and_write_version(self) -> None:
        kit = self.repo.add_kit("alpha_kit", version="0.2.1")
        pubspec = kit / "pubspec.yaml"
        self.assertEqual(release.read_pubspec_version(pubspec), "0.2.1")
        release.write_pubspec_version(pubspec, "0.3.0")
        self.assertEqual(release.read_pubspec_version(pubspec), "0.3.0")
        self.assertIn("name: alpha_kit\n", pubspec.read_text(encoding="utf-8"))

    def test_list_kits_only_dirs_with_pubspec(self) -> None:
        self.repo.add_kit("b_kit")
        self.repo.add_kit("a_kit")
        (self.repo.root / "docs").mkdir()
        (self.repo.root / ".hidden").mkdir()
        (self.repo.root / ".hidden" / "pubspec.yaml").write_text("version: 1.0.0\n", encoding="utf-8")
        self.assertEqual(release.list_kits(self.repo.root), ["a_kit", "b_kit"])

    def test_check_pubspec_ascii(self) -> None:
        kit = self.repo.add_kit("ascii_kit")
        release.check_pubspec_ascii(kit / "pubspec.yaml")  # không ném
        (kit / "pubspec.yaml").write_text("name: ascii_kit\ndescription: Bộ thư viện\nversion: 0.1.0\n", encoding="utf-8")
        with self.assertRaisesRegex(ReleaseError, "ngoài ASCII.*dòng 2"):
            release.check_pubspec_ascii(kit / "pubspec.yaml")

    def test_non_ascii_pubspec_stops_before_any_change(self) -> None:
        kit = self.repo.add_kit("viet_kit")
        (kit / "pubspec.yaml").write_text("name: viet_kit\ndescription: Bộ thư viện\nversion: 0.1.0\n", encoding="utf-8")
        git = FakeGit()
        ports, _ = make_ports([], git)
        with self.assertRaisesRegex(ReleaseError, "ngoài ASCII"):
            release.run_release(self.repo.root, ports, requested_kit="viet_kit", today=TODAY)
        self.assertEqual(release.read_pubspec_version(kit / "pubspec.yaml"), "0.1.0")
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in git.calls))

    def test_resolve_kit_rejects_unknown(self) -> None:
        self.repo.add_kit("a_kit")
        ports, _ = make_ports([], FakeGit())
        with self.assertRaises(ReleaseError):
            release.resolve_kit(self.repo.root, "nope_kit", ports)


class RunReleaseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repo = TempRepo()
        self.addCleanup(self.repo.cleanup)
        self.kit = self.repo.add_kit("alpha_kit", version="0.1.0")
        self.repo.add_kit("beta_kit", version="0.2.1")

    def test_happy_path_without_push(self) -> None:
        git = FakeGit()
        # bump=minor, test=yes (Enter), thực hiện=Enter, push=Enter (No)
        ports, echoed = make_ports(["2", "", "", ""], git)

        code = release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)

        self.assertEqual(code, 0)
        self.assertEqual(release.read_pubspec_version(self.kit / "pubspec.yaml"), "0.2.0")
        self.assertIn("## [0.2.0] - 2026-11-09", (self.kit / "CHANGELOG.md").read_text(encoding="utf-8"))
        self.assertIn(["flutter", "test"], git.calls)
        self.assertIn(["git", "add", "--", "alpha_kit/pubspec.yaml", "alpha_kit/CHANGELOG.md"], git.calls)
        self.assertIn(["git", "commit", "-m", "chore(release): bump alpha_kit to 0.2.0"], git.calls)
        self.assertIn(["git", "tag", "-a", "alpha_kit-v0.2.0", "-m", "Release alpha_kit v0.2.0"], git.calls)
        self.assertFalse(any(c[:2] == ["git", "push"] for c in git.calls))
        self.assertTrue(any("Chưa push" in line for line in echoed))
        # kit khác không bị đụng tới
        self.assertEqual(release.read_pubspec_version(self.repo.root / "beta_kit" / "pubspec.yaml"), "0.2.1")

    def test_menu_selects_kit_when_not_given(self) -> None:
        git = FakeGit()
        # chọn kit=2 (beta_kit), bump=patch, test=n, thực hiện=y, push=n
        ports, _ = make_ports(["2", "1", "n", "y", "n"], git)
        release.run_release(self.repo.root, ports, today=TODAY)
        self.assertEqual(release.read_pubspec_version(self.repo.root / "beta_kit" / "pubspec.yaml"), "0.2.2")
        self.assertNotIn(["flutter", "test"], git.calls)
        self.assertIn(["git", "tag", "-a", "beta_kit-v0.2.2", "-m", "Release beta_kit v0.2.2"], git.calls)

    def test_push_runs_git_push_for_head_and_tag(self) -> None:
        git = FakeGit()
        ports, _ = make_ports(["1", "n", "y", "y"], git)
        release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)
        self.assertIn(["git", "push", "origin", "HEAD"], git.calls)
        self.assertIn(["git", "push", "origin", "alpha_kit-v0.1.1"], git.calls)

    def test_dirty_worktree_refused(self) -> None:
        ports, _ = make_ports([], FakeGit(status=" M x.dart\n"))
        with self.assertRaisesRegex(ReleaseError, "chưa sạch"):
            release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)

    def test_non_main_branch_asks_and_stops_on_no(self) -> None:
        ports, _ = make_ports([""], FakeGit(branch="feature/x"))
        with self.assertRaisesRegex(ReleaseError, "nhánh main"):
            release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)

    def test_existing_tag_refused(self) -> None:
        ports, _ = make_ports(["1"], FakeGit(local_tag="alpha_kit-v0.1.1\n"))
        with self.assertRaisesRegex(ReleaseError, "đã tồn tại ở local"):
            release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)
        ports, _ = make_ports(["1"], FakeGit(remote_tag="abc\trefs/tags/alpha_kit-v0.1.1\n"))
        with self.assertRaisesRegex(ReleaseError, "đã có trên remote"):
            release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)

    def test_failed_tests_restore_files_and_do_not_commit(self) -> None:
        class FailingFlutterGit(FakeGit):
            def __call__(self, cmd, cwd, capture=False):
                if list(cmd)[0] == "flutter":
                    self.calls.append(list(cmd))
                    return ProcessResult(1)
                return super().__call__(cmd, cwd, capture)

        git = FailingFlutterGit()
        ports, _ = make_ports(["1", "y", "y"], git)
        with self.assertRaisesRegex(ReleaseError, "flutter test thất bại"):
            release.run_release(self.repo.root, ports, requested_kit="alpha_kit", today=TODAY)
        self.assertIn(["git", "checkout", "--", "alpha_kit/pubspec.yaml", "alpha_kit/CHANGELOG.md"], git.calls)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in git.calls))

    def test_missing_changelog_refused_before_commit(self) -> None:
        self.repo.add_kit("gamma_kit", changelog=None)
        git = FakeGit()
        ports, _ = make_ports(["1", "n", "y"], git)
        with self.assertRaisesRegex(ReleaseError, "CHANGELOG.md"):
            release.run_release(self.repo.root, ports, requested_kit="gamma_kit", today=TODAY)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in git.calls))


if __name__ == "__main__":
    unittest.main(verbosity=2)
