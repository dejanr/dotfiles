package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestResolveFileLink(t *testing.T) {
	root, err := filepath.EvalSymlinks(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(root, "a'b test.nix")
	if err := os.WriteFile(path, []byte("test\n"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", root)
	uri := (&url.URL{Scheme: "file", Path: path}).String()
	for _, test := range []struct {
		name   string
		link   string
		line   int
		column int
		valid  bool
	}{
		{name: "relative", link: "a'b test.nix", valid: true},
		{name: "absolute", link: path, valid: true},
		{name: "home", link: "~/a'b test.nix", valid: true},
		{name: "encoded URI", link: uri, valid: true},
		{name: "line fragment", link: uri + "#L49", line: 49, column: 1, valid: true},
		{name: "column fragment", link: uri + "#L49C2", line: 49, column: 2, valid: true},
		{name: "line suffix", link: "a'b test.nix:49:2", line: 49, column: 2, valid: true},
		{name: "localhost", link: strings.Replace(uri, "file:///", "file://localhost/", 1), valid: true},
		{name: "remote host", link: strings.Replace(uri, "file:///", "file://remote.example/", 1)},
		{name: "web URL", link: "https://example.com/file.nix"},
		{name: "SSH URL", link: "ssh://example.com/file.nix"},
		{name: "query", link: uri + "?host=remote.example"},
		{name: "invalid fragment", link: uri + "#foo"},
		{name: "zero line", link: uri + "#L0"},
		{name: "zero column", link: uri + "#L1C0"},
		{name: "missing", link: "missing.nix"},
		{name: "directory", link: root},
	} {
		t.Run(test.name, func(t *testing.T) {
			target, valid := resolveFileLink(test.link, root)
			if valid != test.valid {
				t.Fatalf("valid = %v, want %v: %+v", valid, test.valid, target)
			}
			if valid && (target.path != path || target.line != test.line || target.column != test.column) {
				t.Fatalf("target = %+v, want %s:%d:%d", target, path, test.line, test.column)
			}
		})
	}
}

func TestCLIProcess(t *testing.T) {
	if os.Getenv("TMUX_OPENER_TEST_PROCESS") != "1" {
		return
	}
	for index, argument := range os.Args {
		if argument == "--" {
			os.Args = append([]string{"tmux-open-nvim-link"}, os.Args[index+1:]...)
			main()
			os.Exit(0)
		}
	}
	os.Exit(2)
}

type tmuxFixture struct {
	socket string
	root   string
	file   string
}

func newTmuxFixture(t *testing.T, defaultSocket bool) tmuxFixture {
	t.Helper()
	for _, name := range []string{"tmux", "nvim"} {
		if _, err := exec.LookPath(name); err != nil {
			t.Skipf("integration test requires %s", name)
		}
	}
	root, err := os.MkdirTemp("", "tmux-opener-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(root) })
	root, err = filepath.EvalSymlinks(root)
	if err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", root)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(root, "config"))
	t.Setenv("XDG_DATA_HOME", filepath.Join(root, "data"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(root, "state"))
	t.Setenv("XDG_CACHE_HOME", filepath.Join(root, "cache"))
	t.Setenv("TMPDIR", root)
	t.Setenv("TMUX_TMPDIR", root)
	t.Setenv("XDG_RUNTIME_DIR", root)
	t.Setenv("TMUX", "")
	t.Setenv("TMUX_PANE", "")
	t.Setenv("DBUS_SESSION_BUS_ADDRESS", "unix:path="+filepath.Join(root, "no-bus"))
	socket := filepath.Join(root, "tmux.sock")
	if defaultSocket {
		socket = filepath.Join(root, fmt.Sprintf("tmux-%d", os.Getuid()), "default")
		if err := os.MkdirAll(filepath.Dir(socket), 0700); err != nil {
			t.Fatal(err)
		}
	}
	fixture := tmuxFixture{socket: socket, root: root, file: filepath.Join(root, "a'b test.nix")}
	if err := os.WriteFile(fixture.file, []byte(strings.Repeat("example text\n", 80)), 0600); err != nil {
		t.Fatal(err)
	}
	fixture.tmux(t, "-f", "/dev/null", "new-session", "-d", "-s", "opener", "-c", root, "sleep 60")
	t.Logf("Monitor temporary session: tmux -S %s attach -t opener", socket)
	t.Cleanup(func() { exec.Command("tmux", "-S", socket, "kill-server").Run() })
	return fixture
}

func (fixture tmuxFixture) tmux(t *testing.T, args ...string) string {
	t.Helper()
	output, err := exec.Command("tmux", append([]string{"-S", fixture.socket}, args...)...).CombinedOutput()
	if err != nil {
		t.Fatalf("tmux %v: %v: %s", args, err, output)
	}
	return strings.TrimSpace(string(output))
}

func (fixture tmuxFixture) editor(t *testing.T, name string) (string, string) {
	t.Helper()
	server := filepath.Join(fixture.root, "nvim."+name+".0")
	command := "nvim --headless -u NONE --listen '" + server + "'"
	pane := fixture.tmux(t, "new-window", "-d", "-P", "-F", "#{pane_id}", "-n", name, "-c", fixture.root, command)
	waitFor(t, func() bool {
		_, err := os.Stat(server)
		return err == nil
	})
	return pane, server
}

func waitFor(t *testing.T, ready func() bool) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if ready() {
			return
		}
		time.Sleep(25 * time.Millisecond)
	}
	t.Fatal("timed out waiting for fixture")
}

func runCLI(t *testing.T, args ...string) (string, error) {
	t.Helper()
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	command := exec.Command(binary, append([]string{"-test.run=^TestCLIProcess$", "--"}, args...)...)
	command.Env = append(os.Environ(), "TMUX_OPENER_TEST_PROCESS=1")
	output, err := command.CombinedOutput()
	return string(output), err
}

func assertEditorTarget(t *testing.T, server, file string, line, column int) {
	t.Helper()
	output, err := exec.Command("nvim", "--server", server, "--remote-expr",
		"json_encode([expand('%:p'), line('.'), col('.')])").CombinedOutput()
	if err != nil {
		t.Fatalf("read Neovim target: %v: %s", err, output)
	}
	var fields []json.RawMessage
	if err := json.Unmarshal(output, &fields); err != nil || len(fields) != 3 {
		t.Fatalf("invalid editor target: %s", output)
	}
	var actualFile string
	var actualLine, actualColumn int
	json.Unmarshal(fields[0], &actualFile)
	json.Unmarshal(fields[1], &actualLine)
	json.Unmarshal(fields[2], &actualColumn)
	if actualFile != file || actualLine != line || actualColumn != column {
		t.Fatalf("editor at %s:%d:%d, want %s:%d:%d", actualFile, actualLine, actualColumn, file, line, column)
	}
}

func TestLocalOpenerReusesEditorWithoutTmuxEnvironment(t *testing.T) {
	fixture := newTmuxFixture(t, false)
	pane, server := fixture.editor(t, "editor")
	uri := (&url.URL{Scheme: "file", Path: fixture.file, Fragment: "L49C2"}).String()
	output, err := runCLI(t, "--local", uri)
	if err != nil {
		t.Fatalf("local opener: %v: %s", err, output)
	}
	assertEditorTarget(t, server, fixture.file, 49, 2)
	if active := fixture.tmux(t, "display-message", "-p", "#{pane_id}"); active != pane {
		t.Fatalf("selected %s, want %s", active, pane)
	}
	if windows := fixture.tmux(t, "list-windows", "-F", "#{window_id}"); len(strings.Split(windows, "\n")) != 2 {
		t.Fatalf("opener created another window: %s", windows)
	}
}

func TestLocalOpenerResolvesRelativePathInEditorDirectory(t *testing.T) {
	fixture := newTmuxFixture(t, false)
	_, server := fixture.editor(t, "editor")
	output, err := runCLI(t, "--local", "a'b test.nix:7:3")
	if err != nil {
		t.Fatalf("relative opener: %v: %s", err, output)
	}
	assertEditorTarget(t, server, fixture.file, 7, 3)
}

func TestPaneOpenerStillReusesSessionEditor(t *testing.T) {
	fixture := newTmuxFixture(t, false)
	_, server := fixture.editor(t, "editor")
	t.Setenv("TMUX", fixture.socket+",1,0")
	output, err := runCLI(t, "%0", "a'b test.nix#L9")
	if err != nil {
		t.Fatalf("pane opener: %v: %s", err, output)
	}
	assertEditorTarget(t, server, fixture.file, 9, 1)
}

func TestLocalOpenerRejectsAmbiguousEditors(t *testing.T) {
	fixture := newTmuxFixture(t, false)
	_, first := fixture.editor(t, "first")
	_, second := fixture.editor(t, "second")
	output, err := runCLI(t, "--local", fixture.file)
	if err == nil || !strings.Contains(output, "multiple tmux Neovim editors") {
		t.Fatalf("expected ambiguity error, got %v: %s", err, output)
	}
	assertEditorTarget(t, first, "", 1, 1)
	assertEditorTarget(t, second, "", 1, 1)
}

func TestLocalOpenerCreatesWindowInSingleSession(t *testing.T) {
	fixture := newTmuxFixture(t, true)
	output, err := runCLI(t, "--local", fixture.file)
	if err != nil {
		t.Fatalf("new editor: %v: %s", err, output)
	}
	waitFor(t, func() bool {
		return fixture.tmux(t, "display-message", "-p", "#{pane_current_command}") == "nvim"
	})
	if name := fixture.tmux(t, "display-message", "-p", "#{window_name}"); name != "nvim" {
		t.Fatalf("window name = %q", name)
	}
}

func TestLocalOpenerRejectsAmbiguousSessions(t *testing.T) {
	fixture := newTmuxFixture(t, true)
	fixture.tmux(t, "new-session", "-d", "-s", "second", "sleep 60")
	output, err := runCLI(t, "--local", fixture.file)
	if err == nil || !strings.Contains(output, "no unique tmux session") {
		t.Fatalf("expected ambiguous session error, got %v: %s", err, output)
	}
}

func TestLocalOpenerRequiresRunningTmux(t *testing.T) {
	fixture := newTmuxFixture(t, true)
	fixture.tmux(t, "kill-server")
	output, err := runCLI(t, "--local", fixture.file)
	if err == nil || !strings.Contains(output, "start a local tmux session first") {
		t.Fatalf("expected missing session error, got %v: %s", err, output)
	}
}

func TestLocalOpenerRejectsNonlocalLinks(t *testing.T) {
	fixture := newTmuxFixture(t, true)
	for _, link := range []string{"https://example.com/file", "file://remote.example/etc/hosts", fixture.root, "missing.nix"} {
		output, err := runCLI(t, "--local", link)
		if err == nil || !strings.Contains(output, "not an existing local file") {
			t.Fatalf("expected invalid local link error for %s, got %v: %s", link, err, output)
		}
	}
	if windows := fixture.tmux(t, "list-windows", "-F", "#{window_id}"); strings.Contains(windows, "\n") {
		t.Fatalf("invalid link created a window: %s", windows)
	}
}
