package main

import (
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestDesktopOpenerReusesEditor(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("desktop integration is Linux-only")
	}
	if _, err := exec.LookPath("gio"); err != nil {
		t.Skip("desktop integration test requires gio")
	}
	fixture := newTmuxFixture(t, false)
	_, server := fixture.editor(t, "editor")
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	desktop := "[Desktop Entry]\nType=Application\nName=Neovim (tmux test)\nTerminal=false\nNoDisplay=true\nMimeType=text/plain;\nExec=" + binary + " -test.run=^TestCLIProcess$ -- --local %u\n"
	files := map[string]string{
		filepath.Join(os.Getenv("XDG_DATA_HOME"), "applications", "tmux-nvim-test.desktop"): desktop,
		filepath.Join(os.Getenv("XDG_DATA_HOME"), "applications", "mimeinfo.cache"):         "[MIME Cache]\ntext/plain=tmux-nvim-test.desktop;\n",
		filepath.Join(os.Getenv("XDG_CONFIG_HOME"), "mimeapps.list"):                        "[Default Applications]\ntext/plain=tmux-nvim-test.desktop;\n",
	}
	for path, content := range files {
		if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0600); err != nil {
			t.Fatal(err)
		}
	}
	t.Setenv("TMUX_OPENER_TEST_PROCESS", "1")
	uri := (&url.URL{Scheme: "file", Path: fixture.file, Fragment: "L49C2"}).String()
	output, err := exec.Command("gio", "open", uri).CombinedOutput()
	if err != nil {
		t.Fatalf("system opener: %v: %s", err, output)
	}
	waitFor(t, func() bool {
		output, err := exec.Command("nvim", "--server", server, "--remote-expr", "expand('%:p')").Output()
		return err == nil && strings.TrimSpace(string(output)) == fixture.file
	})
	assertEditorTarget(t, server, fixture.file, 49, 2)
}
