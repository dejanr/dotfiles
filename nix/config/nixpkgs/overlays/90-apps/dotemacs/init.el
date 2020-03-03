(require 'package)

;; optional. makes unpure packages archives unavailable
(setq package-archives nil)

(setq package-enable-at-startup nil)
(package-initialize)

;; don't show menu bar in terminal mode
;; https://emacs.stackexchange.com/questions/29441/how-do-i-disable-menu-bar-mode-only-for-tty-frames
(unless (display-graphic-p)
   (menu-bar-mode -1))

(require 'color-theme-sanityinc-tomorrow)
  (load-theme 'sanityinc-tomorrow-eighties t)

;; show available commands after a delay
(require 'which-key)
  (which-key-mode)

(setq ensime-startup-notification nil)
(setq org-pomodoro-finished-sound-p nil)

;; line numbers
(setq-default display-line-numbers 'visual)
(setq-default linum-relative-current-symbol "")

(require 'evil)
  (evil-mode 1)

(require 'key-chord)
  (key-chord-define evil-insert-state-map "kj" 'evil-normal-state)
  (key-chord-mode 1)

(require 'evil-org)
  (add-hook 'org-mode-hook 'evil-org-mode)
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar))

;; Everything below here is an intricate tower of org-mode config.  Most of this was taken and
;; slightly modified from Bernt Hansen's "Org Mode - Organize Your Life In Plain Text!" document.
;; http://doc.norang.ca/org-mode.html
(require 'evil-org-agenda)
  (evil-org-agenda-set-keys)
  (evil-define-key 'motion org-agenda-mode-map
    (kbd "RET") 'org-agenda-switch-to
  )

(setq org-agenda-files
      (list "~/todo/next-actions.org" "~/todo/schedule.org" "~/todo/refile.org"))

(setq org-agenda-start-day "-3d")
(setq org-agenda-span 8)
(setq org-agenda-start-on-weekday nil)

(setq org-log-done 'time)
(setq org-agenda-start-with-log-mode t)

(define-key global-map "\C-cc" 'org-capture)

(setq initial-major-mode 'org-mode)

(setq org-capture-templates
  '(("t" "todo" entry (file "~/todo/refile.org")
     "* TODO %?\n  %U\n")
    ("c" "todo (with capture)" entry (file "~/todo/refile.org")
     "* TODO %?\n%U\n%(shell-command-to-string \"pbpaste\")\n")
    ("n" "note" entry (file "~/todo/refile.org")
     "* %? :NOTE:\n%U\n")
    )
)
; Targets include this file and any file contributing to the agenda - up to N levels deep
(setq org-refile-use-outline-path 'file)
(setq org-refile-targets (quote ((nil :maxlevel . 1)
                                 (org-agenda-files :maxlevel . 1)
                                 ("~/todo/maybe-someday.org" :maxlevel . 1)
                                 ("~/todo/junk-drawer.org" :maxlevel . 1)
                                 ("~/todo/ideas.org" :maxlevel . 1))))
(setq org-todo-keywords
      (quote ((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
              (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "MEETING"))))

(setq org-todo-state-tags-triggers
      (quote (("CANCELLED" ("CANCELLED" . t))
              ("WAITING" ("WAITING" . t))
              ("HOLD" ("WAITING") ("HOLD" . t))
              (done ("WAITING") ("HOLD"))
              ("TODO" ("WAITING") ("CANCELLED") ("HOLD"))
              ("NEXT" ("WAITING") ("CANCELLED") ("HOLD"))
              ("DONE" ("WAITING") ("CANCELLED") ("HOLD")))))

;; Do not dim blocked tasks
(setq org-agenda-dim-blocked-tasks nil)

;; Compact the block agenda view
(setq org-agenda-compact-blocks t)

;; Custom agenda command definitions
(setq org-agenda-custom-commands
      (quote (("N" "Notes" tags "NOTE"
              ((org-agenda-overriding-header "Notes")
                (org-tags-match-list-sublevels t)))
              (" " "Agenda"
              ((agenda "" nil)
                (tags "REFILE"
                      ((org-agenda-overriding-header "Tasks to Refile")
                      (org-tags-match-list-sublevels nil)))
                (tags-todo "-CANCELLED/!"
                          ((org-agenda-overriding-header "Stuck Projects")
                            (org-agenda-skip-function 'bh/skip-non-stuck-projects)
                            (org-agenda-sorting-strategy
                            '(category-keep))))
                (tags-todo "-CANCELLED/!NEXT"
                          ((org-agenda-overriding-header (concat "Project Next Tasks"
                                                                  (if bh/hide-scheduled-and-waiting-next-tasks
                                                                      ""
                                                                    " (including WAITING and SCHEDULED tasks)")))
                            (org-tags-match-list-sublevels t)
                            (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-sorting-strategy
                            '(todo-state-down effort-up category-keep))))
                (tags-todo "-HOLD-CANCELLED/!"
                           ((org-agenda-overriding-header "Projects")
                            (org-agenda-skip-function 'bh/skip-non-projects)
                            (org-tags-match-list-sublevels 'indented)
                            (org-agenda-sorting-strategy
                             '(category-keep))))
                (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                          ((org-agenda-overriding-header (concat "Project Subtasks"
                                                                  (if bh/hide-scheduled-and-waiting-next-tasks
                                                                      ""
                                                                    " (including WAITING and SCHEDULED tasks)")))
                            (org-agenda-skip-function 'bh/skip-non-project-tasks)
                            (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-sorting-strategy
                            '(category-keep))))
                (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                          ((org-agenda-overriding-header (concat "Standalone Tasks"
                                                                  (if bh/hide-scheduled-and-waiting-next-tasks
                                                                      ""
                                                                    " (including WAITING and SCHEDULED tasks)")))
                            (org-agenda-skip-function 'bh/skip-project-tasks)
                            (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-sorting-strategy
                            '(category-keep))))
                (tags-todo "-CANCELLED+WAITING|HOLD/!"
                          ((org-agenda-overriding-header (concat "Waiting and Postponed Tasks"
                                                                  (if bh/hide-scheduled-and-waiting-next-tasks
                                                                      ""
                                                                    " (including WAITING and SCHEDULED tasks)")))
                            (org-agenda-skip-function 'bh/skip-non-tasks)
                            (org-tags-match-list-sublevels nil)
                            (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                            (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)))
                (tags "-REFILE/"
                      ((org-agenda-overriding-header "Tasks to Archive")
                      (org-agenda-skip-function 'bh/skip-non-archivable-tasks)
                      (org-tags-match-list-sublevels nil))))
              nil)
              ("y" "Yesterday" tags (concat "+TODO=\"DONE\"" "+CLOSED>=\"" (format-time-string "[%Y-%m-%d]" (time-subtract (current-time) (days-to-time 1))) "\"")
               ((org-agenda-overriding-header "Yesterday")
                (org-tags-match-list-sublevels t))))))

(defun bh/find-project-task ()
  "Move point to the parent (project) task if any"
  (save-restriction
    (widen)
    (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
      (while (org-up-heading-safe)
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq parent-task (point))))
      (goto-char parent-task)
      parent-task)))

(defun bh/is-project-p ()
  "Any task with a todo keyword subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task has-subtask))))

(defun bh/is-project-subtree-p ()
  "Any task with a todo keyword that is in a project subtree.
Callers of this function already widen the buffer view."
  (let ((task (save-excursion (org-back-to-heading 'invisible-ok)
                              (point))))
    (save-excursion
      (bh/find-project-task)
      (if (equal (point) task)
          nil
        t))))

(defun bh/is-task-p ()
  "Any task with a todo keyword and no subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task (not has-subtask)))))

(defun bh/is-subproject-p ()
  "Any task which is a subtask of another project"
  (let ((is-subproject)
        (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
    (save-excursion
      (while (and (not is-subproject) (org-up-heading-safe))
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq is-subproject t))))
    (and is-a-task is-subproject)))

(defun bh/list-sublevels-for-projects-indented ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels 'indented)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defun bh/list-sublevels-for-projects ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels t)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defvar bh/hide-scheduled-and-waiting-next-tasks t)

(defun bh/toggle-next-task-display ()
  (interactive)
  (setq bh/hide-scheduled-and-waiting-next-tasks (not bh/hide-scheduled-and-waiting-next-tasks))
  (when  (equal major-mode 'org-agenda-mode)
    (org-agenda-redo))
  (message "%s WAITING and SCHEDULED NEXT Tasks" (if bh/hide-scheduled-and-waiting-next-tasks "Hide" "Show")))

(defun bh/skip-stuck-projects ()
  "Skip trees that are not stuck projects"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                (has-next ))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (unless (member "WAITING" (org-get-tags-at))
                  (setq has-next t))))
            (if has-next
                nil
              next-headline)) ; a stuck project, has subtasks but no next task
        nil))))

(defun bh/skip-non-stuck-projects ()
  "Skip trees that are not stuck projects"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (bh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                (has-next ))
            (save-excursion
              (forward-line 1)
              (while (and (not has-next) (< (point) subtree-end) (re-search-forward "^\\*+ NEXT " subtree-end t))
                (unless (member "WAITING" (org-get-tags-at))
                  (setq has-next t))))
            (if has-next
                next-headline
              nil)) ; a stuck project, has subtasks but no next task
        next-headline))))

(defun bh/skip-non-projects ()
  "Skip trees that are not projects"
  (if (save-excursion (bh/skip-non-stuck-projects))
      (save-restriction
        (widen)
        (let ((subtree-end (save-excursion (org-end-of-subtree t))))
          (cond
          ((bh/is-project-p)
            nil)
          ((and (bh/is-project-subtree-p) (not (bh/is-task-p)))
            nil)
          (t
            subtree-end))))
    (save-excursion (org-end-of-subtree t))))

(defun bh/skip-non-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
      ((bh/is-task-p)
        nil)
      (t
        next-headline)))))

(defun bh/skip-project-tasks-maybe ()
  "Show tasks related to the current restriction.
When restricted to a project, skip project and sub project tasks, habits, NEXT tasks, and loose tasks.
When not restricted, skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
          (next-headline (save-excursion (or (outline-next-heading) (point-max))))
          (limit-to-project (marker-buffer org-agenda-restrict-begin)))
      (cond
      ((bh/is-project-p)
        next-headline)
      ((and (not limit-to-project)
            (bh/is-project-subtree-p))
        subtree-end)
      ((and limit-to-project
            (bh/is-project-subtree-p)
            (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
      (t
        nil)))))

(defun bh/skip-project-tasks ()
  "Show non-project tasks.
Skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
      ((bh/is-project-p)
        subtree-end)
      ((bh/is-project-subtree-p)
        subtree-end)
      (t
        nil)))))

(defun bh/skip-non-project-tasks ()
  "Show project tasks.
Skip project and sub-project tasks, habits, and loose non-project tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
          (next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
      ((bh/is-project-p)
        next-headline)
      ((and (bh/is-project-subtree-p)
            (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
      ((not (bh/is-project-subtree-p))
        subtree-end)
      (t
        nil)))))

(defun bh/skip-non-subprojects ()
  "Skip trees that are not projects"
  (let ((next-headline (save-excursion (outline-next-heading))))
    (if (bh/is-subproject-p)
        nil
      next-headline)))


;; Keep tasks with dates on the global todo lists
(setq org-agenda-todo-ignore-with-date nil)

;; Keep tasks with deadlines on the global todo lists
(setq org-agenda-todo-ignore-deadlines nil)

;; Keep tasks with scheduled dates on the global todo lists
(setq org-agenda-todo-ignore-scheduled nil)

;; Keep tasks with timestamps on the global todo lists
(setq org-agenda-todo-ignore-timestamp nil)

;; Remove completed deadline tasks from the agenda view
(setq org-agenda-skip-deadline-if-done t)

;; Remove completed scheduled tasks from the agenda view
(setq org-agenda-skip-scheduled-if-done t)

;; Remove completed items from search results
(setq org-agenda-skip-timestamp-if-done t)


;; Show all future entries for repeating tasks
(setq org-agenda-repeating-timestamp-show-all t)

;; Show all agenda dates - even if they are empty
(setq org-agenda-show-all-dates t)

;; Sorting order for tasks on the agenda
(setq org-agenda-sorting-strategy
      (quote ((agenda habit-down time-up user-defined-up effort-up category-keep)
              (todo category-up effort-up)
              (tags category-up effort-up)
              (search category-up))))


(setq org-agenda-time-grid
      (quote
      ((daily today remove-match)
        (900 1100 1300 1500 1700)
        "......" "----------------")))

;; Display tags farther right
(setq org-agenda-tags-column -102)

;;
;; Agenda sorting functions
;;
(setq org-agenda-cmp-user-defined 'bh/agenda-sort)

(defun bh/agenda-sort (a b)
  "Sorting strategy for agenda items.
Late deadlines first, then scheduled, then non-late deadlines"
  (let (result num-a num-b)
    (cond
    ; time specific items are already sorted first by org-agenda-sorting-strategy

    ; non-deadline and non-scheduled items next
    ((bh/agenda-sort-test 'bh/is-not-scheduled-or-deadline a b))

    ; deadlines for today next
    ((bh/agenda-sort-test 'bh/is-due-deadline a b))

    ; late deadlines next
    ((bh/agenda-sort-test-num 'bh/is-late-deadline '> a b))

    ; scheduled items for today next
    ((bh/agenda-sort-test 'bh/is-scheduled-today a b))

    ; late scheduled items next
    ((bh/agenda-sort-test-num 'bh/is-scheduled-late '> a b))

    ; pending deadlines last
    ((bh/agenda-sort-test-num 'bh/is-pending-deadline '< a b))

    ; finally default to unsorted
    (t (setq result nil)))
    result))

(defmacro bh/agenda-sort-test (fn a b)
  "Test for agenda sort"
  `(cond
    ; if both match leave them unsorted
    ((and (apply ,fn (list ,a))
          (apply ,fn (list ,b)))
    (setq result nil))
    ; if a matches put a first
    ((apply ,fn (list ,a))
    (setq result -1))
    ; otherwise if b matches put b first
    ((apply ,fn (list ,b))
    (setq result 1))
    ; if none match leave them unsorted
    (t nil)))

(defmacro bh/agenda-sort-test-num (fn compfn a b)
  `(cond
    ((apply ,fn (list ,a))
    (setq num-a (string-to-number (match-string 1 ,a)))
    (if (apply ,fn (list ,b))
        (progn
          (setq num-b (string-to-number (match-string 1 ,b)))
          (setq result (if (apply ,compfn (list num-a num-b))
                            -1
                          1)))
      (setq result -1)))
    ((apply ,fn (list ,b))
    (setq result 1))
    (t nil)))

(defun bh/is-not-scheduled-or-deadline (date-str)
  (and (not (bh/is-deadline date-str))
      (not (bh/is-scheduled date-str))))

(defun bh/is-due-deadline (date-str)
  (string-match "Deadline:" date-str))

(defun bh/is-late-deadline (date-str)
  (string-match "\\([0-9]*\\) d\. ago:" date-str))

(defun bh/is-pending-deadline (date-str)
  (string-match "In \\([^-]*\\)d\.:" date-str))

(defun bh/is-deadline (date-str)
  (or (bh/is-due-deadline date-str)
      (bh/is-late-deadline date-str)
      (bh/is-pending-deadline date-str)))

(defun bh/is-scheduled (date-str)
  (or (bh/is-scheduled-today date-str)
      (bh/is-scheduled-late date-str)))

(defun bh/is-scheduled-today (date-str)
  (string-match "Scheduled:" date-str))

(defun bh/is-scheduled-late (date-str)
  (string-match "Sched\.\\(.*\\)x:" date-str))
