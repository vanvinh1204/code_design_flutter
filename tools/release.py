"""
Phát hành một kit trong repo code_design_flutter: nâng version trong pubspec.yaml của kit,
chốt CHANGELOG của kit, chạy flutter test trong kit, commit, tag <kit>-vX.Y.Z,
rồi hỏi mới push (và tạo GitHub Release nếu có gh).

Cách dùng (không có cờ, mọi lựa chọn hỏi trong CLI):
    python tools/release.py                   # chọn kit trong menu
    python tools/release.py pda_broadcast_kit # chỉ định kit

Quy trình:
    1. Kiểm: git sạch, đang ở nhánh main (không thì hỏi), pubspec.yaml của kit thuần ASCII,
       tag <kit>-vX.Y.Z chưa có ở local/remote.
    2. Chọn patch / minor / major, chọn có chạy test không, xem tóm tắt rồi xác nhận.
    3. Ghi version vào <kit>/pubspec.yaml; đổi mục [Unreleased] trong <kit>/CHANGELOG.md thành
       [X.Y.Z] - <ngày>; chạy `flutter test` trong thư mục kit. Lỗi ở bước này thì trả file về như cũ.
    4. Commit "chore(release): bump <kit> to X.Y.Z" + tag <kit>-vX.Y.Z.
    5. Hỏi push (mặc định Không). Có gh thì tạo GitHub Release với ghi chú từ CHANGELOG của kit.

Tương đương tools/release.py của core_kit (code_design_python) nhưng nhận tên kit, vì repo này
chứa nhiều package và mỗi package có version + CHANGELOG + tag riêng.
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Callable, List, Optional, Sequence, Tuple

ROOT_DIR = Path(__file__).resolve().parent.parent
UNRELEASED_HEADING = "## [Unreleased]"
BUMPS = (("1", "patch"), ("2", "minor"), ("3", "major"))
VERSION_LINE = re.compile(r"^version:\s*([0-9A-Za-z.+-]+)\s*$", re.MULTILINE)


class ReleaseError(Exception):
    """Lỗi người dùng/môi trường: in thông điệp và thoát mã 1, không in traceback."""


@dataclass(frozen=True)
class ProcessResult:
    returncode: int
    stdout: str = ""
    stderr: str = ""


@dataclass(frozen=True)
class Ports:
    """Cổng ra ngoài: test truyền bản giả, `real_ports()` dùng bản thật."""

    ask: Callable[[str], str]
    echo: Callable[[str], None]
    # capture=True: thu stdout/stderr (git, gh); capture=False: in thẳng ra console (flutter test).
    run: Callable[..., ProcessResult]
    which: Callable[[str], Optional[str]]


# ---------------------------------------------------------------------------
# Cổng thật
# ---------------------------------------------------------------------------
def _run(cmd: Sequence[str], cwd: Path, capture: bool = False) -> ProcessResult:
    try:
        if capture:
            done = subprocess.run(
                list(cmd), cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace"
            )
            return ProcessResult(done.returncode, done.stdout or "", done.stderr or "")
        return ProcessResult(subprocess.run(list(cmd), cwd=cwd).returncode)
    except FileNotFoundError as exc:
        raise ReleaseError(f"Không chạy được '{cmd[0]}': {exc}") from exc


def _echo(message: str = "") -> None:
    print(message, flush=True)


def real_ports() -> Ports:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            try:
                stream.reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass
    return Ports(ask=input, echo=_echo, run=_run, which=shutil.which)


# ---------------------------------------------------------------------------
# Hỏi đáp trong CLI
# ---------------------------------------------------------------------------
def _ask(ports: Ports, prompt: str) -> str:
    try:
        return ports.ask(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        raise ReleaseError("Đã hủy.") from None


def choose(ports: Ports, title: str, options: Sequence[Tuple[str, str]], default: str) -> str:
    """Hiện menu `key) nhãn`, trả về key được chọn; Enter = `default`, nhập sai thì hỏi lại."""
    keys = [key for key, _ in options]
    ports.echo(title)
    for key, label in options:
        ports.echo(f"  {key}) {label}")
    while True:
        answer = _ask(ports, f"Lựa chọn [{default}]: ")
        if not answer:
            return default
        if answer in keys:
            return answer
        ports.echo(f"  Lựa chọn không hợp lệ: '{answer}'. Nhập một trong: {', '.join(keys)}.")


def confirm(ports: Ports, question: str, default: bool) -> bool:
    hint = "[Y/n]" if default else "[y/N]"
    while True:
        answer = _ask(ports, f"{question} {hint}: ").lower()
        if not answer:
            return default
        if answer in ("y", "yes", "c", "co", "có"):
            return True
        if answer in ("n", "no", "k", "khong", "không"):
            return False
        ports.echo("  Trả lời y hoặc n.")


# ---------------------------------------------------------------------------
# Kit và version
# ---------------------------------------------------------------------------
def list_kits(root: Path) -> List[str]:
    """Các thư mục con cấp 1 có pubspec.yaml (không tính thư mục ẩn)."""
    return sorted(
        p.name for p in root.iterdir()
        if p.is_dir() and not p.name.startswith(".") and (p / "pubspec.yaml").is_file()
    )


def resolve_kit(root: Path, requested: Optional[str], ports: Ports) -> str:
    kits = list_kits(root)
    if not kits:
        raise ReleaseError(f"Không tìm thấy kit nào (thư mục có pubspec.yaml) trong {root}.")
    if requested:
        if requested not in kits:
            raise ReleaseError(f"Không có kit '{requested}'. Các kit: {', '.join(kits)}.")
        return requested
    options = [(str(i + 1), kit) for i, kit in enumerate(kits)]
    key = choose(ports, "Chọn kit cần phát hành:", options, default="1")
    return dict(options)[key]


def read_pubspec_version(pubspec_path: Path) -> str:
    if not pubspec_path.is_file():
        raise ReleaseError(f"Không tìm thấy {pubspec_path}.")
    match = VERSION_LINE.search(pubspec_path.read_text(encoding="utf-8"))
    if match is None:
        raise ReleaseError(f"{pubspec_path} không có dòng 'version:'.")
    return match.group(1)


def check_pubspec_ascii(pubspec_path: Path) -> None:
    """pubspec.yaml phải thuần ASCII: pub trên Windows giải mã `git show` của git dependency theo
    code page hệ thống, ký tự tiếng Việt làm `flutter pub get` ở app lỗi 'Unexpected character'."""
    text = pubspec_path.read_text(encoding="utf-8")
    bad = [(i + 1, line) for i, line in enumerate(text.splitlines()) if not line.isascii()]
    if bad:
        where = "; ".join(f"dòng {n}: {line.strip()[:60]}" for n, line in bad[:3])
        raise ReleaseError(
            f"{pubspec_path} chứa ký tự ngoài ASCII ({where}). App ghim git dependency trên Windows sẽ không "
            "pub get được. Viết description bằng tiếng Anh / không dấu."
        )


def write_pubspec_version(pubspec_path: Path, version: str) -> None:
    text = pubspec_path.read_text(encoding="utf-8")
    new_text, count = VERSION_LINE.subn(f"version: {version}", text, count=1)
    if count != 1:
        raise ReleaseError(f"{pubspec_path} không có dòng 'version:'.")
    pubspec_path.write_text(new_text, encoding="utf-8")


def calculate_next_version(current: str, bump: str) -> str:
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)$", current)
    if match is None:
        raise ReleaseError(f"Version hiện tại '{current}' không đúng dạng X.Y.Z.")
    major, minor, patch = (int(g) for g in match.groups())
    if bump == "patch":
        return f"{major}.{minor}.{patch + 1}"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    if bump == "major":
        return f"{major + 1}.0.0"
    raise ReleaseError(f"Loại nâng '{bump}' không hợp lệ (patch / minor / major).")


def tag_name(kit: str, version: str) -> str:
    return f"{kit}-v{version}"


# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------
def _detail(result: ProcessResult) -> str:
    return (result.stderr or result.stdout).strip()


class Git:
    def __init__(self, root: Path, ports: Ports) -> None:
        self.root = root
        self.ports = ports

    def __call__(self, *args: str) -> ProcessResult:
        return self.ports.run(["git", *args], self.root, capture=True)

    def must(self, *args: str) -> ProcessResult:
        result = self(*args)
        if result.returncode != 0:
            raise ReleaseError(f"git {' '.join(args)} lỗi (mã {result.returncode}): {_detail(result)}")
        return result


def check_worktree_clean(git: Git) -> None:
    status = git("status", "--porcelain")
    if status.returncode != 0:
        raise ReleaseError(f"Không đọc được trạng thái git: {_detail(status)}")
    if status.stdout.strip():
        raise ReleaseError("Working tree chưa sạch. Commit hoặc stash các thay đổi trước khi phát hành.")


def check_branch(git: Git, ports: Ports) -> None:
    branch = git.must("rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch == "main":
        return
    ports.echo(f"Cảnh báo: đang ở nhánh '{branch}', không phải 'main'.")
    if not confirm(ports, "Vẫn phát hành từ nhánh này?", default=False):
        raise ReleaseError("Đã dừng. Chuyển sang nhánh main rồi chạy lại.")


def check_tag_free(tag: str, git: Git, ports: Ports) -> None:
    """Từ chối nếu tag đã có ở local hoặc remote; không kết nối được remote thì chỉ cảnh báo."""
    if git.must("tag", "-l", tag).stdout.strip():
        raise ReleaseError(f"Tag {tag} đã tồn tại ở local. Chọn version khác.")
    remotes = git("remote").stdout.split()
    if "origin" not in remotes:
        return
    result = git("ls-remote", "--tags", "origin", f"refs/tags/{tag}")
    if result.returncode != 0:
        ports.echo(f"Cảnh báo: không kiểm được tag trên remote origin ({_detail(result)}). Tiếp tục với tag local.")
    elif result.stdout.strip():
        raise ReleaseError(f"Tag {tag} đã có trên remote origin. Chọn version khác.")


# ---------------------------------------------------------------------------
# CHANGELOG
# ---------------------------------------------------------------------------
def _section_body(text: str, heading_start: int) -> str:
    body_start = text.find("\n", heading_start)
    body_start = len(text) if body_start == -1 else body_start + 1
    nxt = re.compile(r"^##\s", re.MULTILINE).search(text, body_start)
    return text[body_start: nxt.start() if nxt else len(text)]


def _strip_rules(body: str) -> str:
    """Bỏ các dòng `---` ngăn cách mục và khoảng trắng thừa."""
    lines = [line for line in body.splitlines() if line.strip() != "---"]
    return "\n".join(lines).strip()


def release_changelog(text: str, version: str, today: date) -> Tuple[str, bool]:
    """Đổi `## [Unreleased]` thành `## [version] - today`, chèn lại mục Unreleased trống phía trên.

    Trả về (nội dung mới, mục Unreleased có nội dung hay không).
    """
    match = re.compile(rf"^{re.escape(UNRELEASED_HEADING)}[ \t]*$", re.MULTILINE).search(text)
    if match is None:
        raise ReleaseError(f"CHANGELOG.md không có mục '{UNRELEASED_HEADING}'.")
    has_content = bool(_strip_rules(_section_body(text, match.start())))
    new_heading = f"{UNRELEASED_HEADING}\n\n---\n\n## [{version}] - {today.isoformat()}"
    return text[: match.start()] + new_heading + text[match.end():], has_content


def changelog_notes(text: str, version: str) -> Optional[str]:
    """Nội dung mục `## [version]` để làm ghi chú GitHub Release, None nếu trống."""
    match = re.compile(rf"^##\s*\[{re.escape(version)}\](\s|$)", re.MULTILINE).search(text)
    if match is None:
        return None
    return _strip_rules(_section_body(text, match.start())) or None


# ---------------------------------------------------------------------------
# Các bước ghi
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class Kit:
    name: str
    root: Path  # thư mục repo

    @property
    def dir(self) -> Path:
        return self.root / self.name

    @property
    def pubspec(self) -> Path:
        return self.dir / "pubspec.yaml"

    @property
    def changelog(self) -> Path:
        return self.dir / "CHANGELOG.md"

    @property
    def release_files(self) -> Tuple[str, str]:
        """Đường dẫn tương đối repo, dùng cho git add / git checkout."""
        return (f"{self.name}/pubspec.yaml", f"{self.name}/CHANGELOG.md")


def choose_version(current: str, ports: Ports) -> str:
    options = [(key, f"{kind:<5} -> {calculate_next_version(current, kind)}") for key, kind in BUMPS]
    key = choose(ports, f"Version hiện tại: {current}. Nâng lên:", options, default="1")
    return calculate_next_version(current, dict(BUMPS)[key])


def write_release_files(kit: Kit, version: str, today: date, ports: Ports) -> None:
    if not kit.changelog.is_file():
        raise ReleaseError(f"Không tìm thấy {kit.changelog}. Mỗi kit phải có CHANGELOG.md riêng.")
    write_pubspec_version(kit.pubspec, version)
    new_text, has_content = release_changelog(kit.changelog.read_text(encoding="utf-8"), version, today)
    kit.changelog.write_text(new_text, encoding="utf-8")
    if not has_content:
        ports.echo(f"Cảnh báo: mục [Unreleased] trong {kit.name}/CHANGELOG.md trống, mục mới sẽ không có nội dung.")
    ports.echo(f"Đã ghi version {version} vào: {', '.join(kit.release_files)}")


def run_tests(kit: Kit, ports: Ports) -> None:
    flutter = ports.which("flutter")
    if flutter is None:
        raise ReleaseError("Không tìm thấy flutter trong PATH. Cài Flutter hoặc chọn không chạy test.")
    ports.echo(f"Đang chạy flutter test trong {kit.name}/ ...")
    result = ports.run([flutter, "test"], kit.dir, capture=False)
    if result.returncode != 0:
        raise ReleaseError(f"flutter test thất bại (mã {result.returncode}). Sửa test rồi chạy lại.")


def restore_release_files(kit: Kit, git: Git, ports: Ports) -> None:
    result = git("checkout", "--", *kit.release_files)
    if result.returncode != 0:
        ports.echo(f"Cảnh báo: không hoàn tác được file ({_detail(result)}). Kiểm tra bằng `git status`.")
    else:
        ports.echo(f"Đã trả {', '.join(kit.release_files)} về nguyên trạng.")


def commit_and_tag(kit: Kit, git: Git, version: str, ports: Ports) -> str:
    tag = tag_name(kit.name, version)
    git.must("add", "--", *kit.release_files)
    git.must("commit", "-m", f"chore(release): bump {kit.name} to {version}")
    git.must("tag", "-a", tag, "-m", f"Release {kit.name} v{version}")
    ports.echo(f"Đã commit và tạo tag {tag}.")
    return tag


def _manual_push_hint(tag: str) -> str:
    return f"Push tay: git push origin HEAD && git push origin {tag}"


def publish(kit: Kit, version: str, tag: str, git: Git, ports: Ports) -> None:
    git.must("push", "origin", "HEAD")
    git.must("push", "origin", tag)
    ports.echo(f"Đã push nhánh hiện tại và tag {tag} lên origin.")
    if ports.which("gh") is None:
        ports.echo(
            "Chưa cài GitHub CLI (gh) nên không tạo GitHub Release tự động.\n"
            f"Tạo tay trên GitHub: Releases -> Draft a new release -> chọn tag {tag}, "
            f"dán nội dung mục [{version}] trong {kit.name}/CHANGELOG.md vào ghi chú."
        )
        return
    cmd = ["gh", "release", "create", tag, "--title", f"{kit.name} v{version}"]
    notes = changelog_notes(kit.changelog.read_text(encoding="utf-8"), version)
    with tempfile.TemporaryDirectory(prefix=f"{kit.name}-notes-") as tmp:
        if notes:
            notes_file = Path(tmp) / "notes.md"
            notes_file.write_text(notes + "\n", encoding="utf-8")
            cmd += ["--notes-file", str(notes_file)]
        else:
            cmd.append("--generate-notes")
        result = ports.run(cmd, kit.root, capture=True)
    if result.returncode != 0:
        raise ReleaseError(f"gh release create lỗi (mã {result.returncode}): {_detail(result)}")
    ports.echo(f"Đã tạo GitHub Release {tag}. {result.stdout.strip()}".rstrip())


def _print_plan(kit: Kit, current: str, version: str, tag: str, with_tests: bool, today: date, ports: Ports) -> None:
    ports.echo("")
    ports.echo("=" * 60)
    ports.echo(f"  PHÁT HÀNH {kit.name}: {current} -> {version}")
    ports.echo("=" * 60)
    ports.echo(f"  File sẽ sửa : {', '.join(kit.release_files)}")
    ports.echo(f"  CHANGELOG   : [Unreleased] -> [{version}] - {today.isoformat()}")
    ports.echo(f"  Chạy test   : {'có (flutter test trong ' + kit.name + '/)' if with_tests else 'không'}")
    ports.echo(f"  Commit      : chore(release): bump {kit.name} to {version}")
    ports.echo(f"  Tag         : {tag}")
    ports.echo("  Push        : hỏi sau khi tag xong")
    ports.echo("=" * 60)


def run_release(root: Path, ports: Ports, requested_kit: Optional[str] = None, today: Optional[date] = None) -> int:
    today = today or date.today()
    if ports.which("git") is None:
        raise ReleaseError("Không tìm thấy git.")
    git = Git(root, ports)

    check_worktree_clean(git)
    check_branch(git, ports)

    kit = Kit(resolve_kit(root, requested_kit, ports), root)
    check_pubspec_ascii(kit.pubspec)
    current = read_pubspec_version(kit.pubspec)
    version = choose_version(current, ports)
    tag = tag_name(kit.name, version)
    check_tag_free(tag, git, ports)
    with_tests = confirm(ports, f"Chạy flutter test trong {kit.name}/ trước khi commit?", default=True)

    _print_plan(kit, current, version, tag, with_tests, today, ports)
    if not confirm(ports, "Thực hiện?", default=True):
        raise ReleaseError("Đã hủy, chưa sửa gì.")

    try:
        write_release_files(kit, version, today, ports)
        if with_tests:
            run_tests(kit, ports)
    except ReleaseError:
        restore_release_files(kit, git, ports)
        raise

    commit_and_tag(kit, git, version, ports)

    if not confirm(ports, "Push lên origin (và tạo GitHub Release nếu có gh)?", default=False):
        ports.echo(f"Chưa push. {_manual_push_hint(tag)}")
        return 0
    try:
        publish(kit, version, tag, git, ports)
    except ReleaseError as exc:
        raise ReleaseError(f"{exc}\nCommit và tag {tag} vẫn ở local. {_manual_push_hint(tag)}") from None
    return 0


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    ports = real_ports()
    if any(a in ("-h", "--help") for a in args):
        ports.echo((__doc__ or "").strip())
        return 0
    if len(args) > 1:
        ports.echo("[LỖI] Chỉ nhận tối đa một tham số: tên kit. Ví dụ: python tools/release.py pda_broadcast_kit")
        return 1
    try:
        return run_release(ROOT_DIR, ports, requested_kit=args[0] if args else None)
    except ReleaseError as exc:
        ports.echo(f"[LỖI] {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
