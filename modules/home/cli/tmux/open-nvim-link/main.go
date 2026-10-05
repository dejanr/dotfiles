package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

type fileTarget struct {
	path   string
	line   int
	column int
}

type editor struct {
	pane   string
	socket string
	server string
}

type paneContext struct {
	pane    string
	session string
	cwd     string
	socket  string
}

var (
	lineSuffix   = regexp.MustCompile(`:([0-9]+)(?::([0-9]+))?$`)
	lineFragment = regexp.MustCompile(`^L([0-9]+)(?:C([0-9]+))?$`)
)

func run(name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	output, err := exec.CommandContext(ctx, name, args...).Output()
	if err != nil {
		if ctx.Err() != nil {
			return "", fmt.Errorf("%s: %w", name, ctx.Err())
		}
		var exitError *exec.ExitError
		if errors.As(err, &exitError) && len(exitError.Stderr) > 0 {
			return "", fmt.Errorf("%s: %s", name, strings.TrimSpace(string(exitError.Stderr)))
		}
		return "", fmt.Errorf("%s: %w", name, err)
	}
	return strings.TrimSpace(string(output)), nil
}

func parseLocation(match []string) (int, int, bool) {
	line, err := strconv.Atoi(match[1])
	if err != nil || line < 1 {
		return 0, 0, false
	}
	column := 1
	if match[2] != "" {
		column, err = strconv.Atoi(match[2])
	}
	return line, column, err == nil && column > 0
}

func resolveFileLink(link, cwd string) (fileTarget, bool) {
	var target fileTarget
	if match := lineSuffix.FindStringSubmatchIndex(link); match != nil {
		var valid bool
		target.line, target.column, valid = parseLocation(lineSuffix.FindStringSubmatch(link))
		if !valid {
			return target, false
		}
		link = link[:match[0]]
	}

	parsed, err := url.Parse(link)
	if err != nil || (parsed.Scheme != "" && parsed.Scheme != "file") || parsed.RawQuery != "" {
		return target, false
	}
	hostname, _ := os.Hostname()
	if parsed.Host != "" && (parsed.Scheme != "file" ||
		(!strings.EqualFold(parsed.Host, "localhost") && !strings.EqualFold(parsed.Host, hostname))) {
		return target, false
	}
	if parsed.Fragment != "" {
		match := lineFragment.FindStringSubmatch(parsed.Fragment)
		if match == nil {
			return target, false
		}
		var valid bool
		target.line, target.column, valid = parseLocation(match)
		if !valid {
			return target, false
		}
	}

	path := parsed.Path
	if parsed.Opaque != "" {
		path, err = url.PathUnescape(parsed.Opaque)
		if err != nil {
			return target, false
		}
	}
	if path == "~" || strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return target, false
		}
		path = filepath.Join(home, strings.TrimPrefix(path, "~"))
	}
	if !filepath.IsAbs(path) {
		path = filepath.Join(cwd, path)
	}
	path, err = filepath.EvalSymlinks(path)
	if err != nil {
		return target, false
	}
	info, err := os.Stat(path)
	if err != nil || !info.Mode().IsRegular() {
		return target, false
	}
	target.path = path
	return target, true
}

func nvimServers() []string {
	servers := make(map[string]bool)
	for _, root := range []string{os.TempDir(), os.Getenv("XDG_RUNTIME_DIR")} {
		if root == "" {
			continue
		}
		entries, _ := filepath.Glob(filepath.Join(root, "nvim.*"))
		for _, entry := range entries {
			info, err := os.Stat(entry)
			if err != nil {
				continue
			}
			if info.Mode()&os.ModeSocket != 0 {
				servers[entry] = true
			} else if info.IsDir() {
				filepath.WalkDir(entry, func(path string, item os.DirEntry, err error) error {
					if err == nil && item.Type()&os.ModeSocket != 0 {
						if matches, _ := filepath.Match("nvim.*.0", item.Name()); matches {
							servers[path] = true
						}
					}
					return nil
				})
			}
		}
	}
	paths := make([]string, 0, len(servers))
	for path := range servers {
		paths = append(paths, path)
	}
	sort.Strings(paths)
	return paths
}

func runningEditors() []editor {
	var editors []editor
	for _, server := range nvimServers() {
		identity, err := run("nvim", "--server", server, "--remote-expr",
			"json_encode([getenv('TMUX_PANE'), split(getenv('TMUX'), ',')[0]])")
		if err != nil {
			continue
		}
		var fields []string
		if json.Unmarshal([]byte(identity), &fields) != nil || len(fields) != 2 ||
			fields[0] == "" || fields[1] == "" {
			continue
		}
		pane, err := runTmux(fields[1], "display-message", "-p", "-t", fields[0], "#{pane_id}")
		if err == nil && pane == fields[0] {
			editors = append(editors, editor{pane: pane, socket: fields[1], server: server})
		}
	}
	return editors
}

func runTmux(socket string, args ...string) (string, error) {
	if socket != "" {
		args = append([]string{"-S", socket}, args...)
	}
	return run("tmux", args...)
}

func readPaneContext(socket, pane string) (paneContext, error) {
	output, err := runTmux(socket, "display-message", "-p", "-t", pane,
		"#{pane_id}\t#{session_id}\t#{pane_current_path}\t#{socket_path}")
	if err != nil {
		return paneContext{}, err
	}
	fields := strings.Split(output, "\t")
	if len(fields) != 4 || fields[0] == "" || fields[1] == "" || fields[3] == "" {
		return paneContext{}, fmt.Errorf("invalid tmux pane context: %q", output)
	}
	return paneContext{pane: fields[0], session: fields[1], cwd: fields[2], socket: fields[3]}, nil
}

func editTarget(editor editor, target fileTarget) error {
	filename := strings.ReplaceAll(target.path, "'", "''")
	expression := fmt.Sprintf("execute('edit ' . fnameescape('%s'))", filename)
	if target.line > 0 {
		expression += fmt.Sprintf(" . cursor(%d, %d)", target.line, target.column)
	}
	if _, err := run("nvim", "--server", editor.server, "--remote-expr", expression); err != nil {
		return err
	}
	if _, err := runTmux(editor.socket, "select-window", "-t", editor.pane); err != nil {
		return err
	}
	_, err := runTmux(editor.socket, "select-pane", "-t", editor.pane)
	return err
}

func openTarget(pane paneContext, target fileTarget) error {
	paneList, err := runTmux(pane.socket, "list-panes", "-s", "-t", pane.pane, "-F", "#{pane_id}")
	if err != nil {
		return err
	}
	panes := make(map[string]bool)
	for _, id := range strings.Split(paneList, "\n") {
		panes[id] = true
	}
	for _, editor := range runningEditors() {
		if panes[editor.pane] && editor.socket == pane.socket {
			return editTarget(editor, target)
		}
	}

	args := []string{"new-window", "-t", pane.session + ":", "-n", "nvim", "-c", pane.cwd, "nvim"}
	if target.line > 0 {
		args = append(args, fmt.Sprintf("+call cursor(%d, %d)", target.line, target.column))
	}
	args = append(args, "--", target.path)
	_, err = runTmux(pane.socket, args...)
	return err
}

func openLink(pane, link string) error {
	context, err := readPaneContext("", pane)
	if err != nil {
		return err
	}
	target, valid := resolveFileLink(link, context.cwd)
	if !valid {
		return nil
	}
	return openTarget(context, target)
}

func openLocalLink(link string) error {
	editors := runningEditors()
	if len(editors) > 1 {
		return fmt.Errorf("multiple tmux Neovim editors are running; use the pane-aware tmux click instead")
	}
	var context paneContext
	var err error
	if len(editors) == 1 {
		context, err = readPaneContext(editors[0].socket, editors[0].pane)
	} else {
		sessions, listErr := runTmux("", "list-sessions", "-F", "#{session_id}")
		if listErr != nil {
			return fmt.Errorf("start a local tmux session first: %w", listErr)
		}
		if sessions == "" || strings.Contains(sessions, "\n") {
			return fmt.Errorf("no Neovim editor and no unique tmux session; use the pane-aware tmux click instead")
		}
		context, err = readPaneContext("", sessions+":")
	}
	if err != nil {
		return err
	}
	target, valid := resolveFileLink(link, context.cwd)
	if !valid {
		return fmt.Errorf("not an existing local file or supported file link: %q", link)
	}
	if len(editors) == 1 {
		return editTarget(editors[0], target)
	}
	return openTarget(context, target)
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: tmux-open-nvim-link PANE LINK\n       tmux-open-nvim-link --local FILE_OR_URL")
		os.Exit(1)
	}
	local := os.Args[1] == "--local"
	var err error
	if local {
		err = openLocalLink(os.Args[2])
	} else {
		err = openLink(os.Args[1], os.Args[2])
	}
	if err != nil {
		message := "Could not open Neovim link: " + err.Error()
		fmt.Fprintln(os.Stderr, message)
		if local {
			if runtime.GOOS == "linux" {
				run("notify-send", "--app-name=tmux-open-nvim-link", "--", "Could not open Neovim link", err.Error())
			}
		} else {
			runTmux("", "display-message", "-t", os.Args[1], message)
		}
		os.Exit(1)
	}
}
