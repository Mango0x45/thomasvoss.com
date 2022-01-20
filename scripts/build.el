;; This file is loosely based on Davil Wilson's publish.el which is
;; loosely based on Pierre Neidhardt's publish.el, here are there
;; authorship details:
;;
;; Author: David Wilson <david@daviwil.com>
;; Maintainer: David Wilson <david@daviwil.com>
;; URL: https://sr.ht/~systemcrafters/site
;;
;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://gitlab.com/Ambrevar/ambrevar.gitlab.io

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Docs License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Docs License for more details.
;;
;; You should have received a copy of the GNU General Docs License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Default settings related to the build process
(setq site/src-dir (expand-file-name "./site")     ; Directory where the source files live
      site/pub-dir (expand-file-name "./pub")      ; Directory where the published files will go
      site/pkg-dir (expand-file-name "./pkg")      ; Directory where installed packages live
      site/scr-dir (expand-file-name "./scripts")) ; Directory where scripts live

;; It's not the 60s anymore
(setq gc-cons-threshold (* 100 1024 1024))

;; Create a sensible heading ID from a heading, for example, create the ID "my-heading-123" from the
;; heading "My Heading 123".
(defun site/make-heading-anchor-name (headline-text)
  (thread-last headline-text
               (downcase)
               (replace-regexp-in-string " " "-")
               (replace-regexp-in-string "[^[:alnum:]_-]" "")))


;; Format a headline to have a clickable anchor to its left. If the headline is a top level heading
;; (i.e. <h1>) then the anchor is a '§', otherwise it is a '¶'.
(defun site/org-html-headline (headline contents info)
  (let* ((text (org-export-data (org-element-property :title headline) info))
         (level (org-export-get-relative-level headline info))
         (level (min 7 (when level (1+ level))))
         (anchor-name (site/make-heading-anchor-name text)))
    (format "<h%d><a id=\"%s\" class=\"anchor\" href=\"#%s\">&sect;</a>%s</h%d>%s"
            level
            anchor-name
            anchor-name
            text
            level
            (or contents ""))))

;; Output source code blocks as an anchor and a pre in a div. This let's us have the same anchors
;; here as we do for headings. We also add the source language as a class so that you can see that
;; when hovering over a source block.
(defun site/org-html-src-block (src-block contents info)
  (let ((code (org-html-format-code src-block info))
        (language (org-element-property :language src-block)))
    (when code
      (sxml-to-xml
       `(div (@ (class "src-code"))
             (a (@ (class "anchor")
                   (href "#"))
                "&lambda;")
             (pre (@ (class ,language))
                  (code ,(s-trim (format "%s" code)))))))))

;; The template HTML that gets used for every single page. The actual page content is represented by
;; the `contents' variable.
(defun site/org-html-template (contents info)
  (let ((doc-title (org-export-data (plist-get info :title) info))
        (description (org-export-data (plist-get info :description) info)))
    (concat
     "<!DOCTYPE html>"
     (sxml-to-xml
      `(html (@ (lang "en"))
             (head
              (meta (@ (http-equiv "content-type")
                       (content "text/html; charset=utf-8")))
              (meta (@ (name "author")
                       (content "Thomas Voss")))
              ,(unless (string-empty-p description)
                 `(meta (@ (name "description")
                           (content ,description))))
              (meta (@ (name "viewport")
                       (content "width=device-width, initial-scale=1, shrink-to-fit=no")))
              (link (@ (rel "icon")
                       (href "/favicon.svg")))
              (link (@ (rel "stylesheet")
                       (href "/style.css")))
              (title ,doc-title))
             (body
              (h1 ,doc-title)
              ,contents))))))

;; (defun site/org-html-format-headline (level attributes anchor-name text contents)
;; Initialize package sources
(require 'package)
(customize-set-value 'package-user-dir site/pkg-dir)
(customize-set-value 'package-archives '(("melpa" . "https://melpa.org/packages/")
                                         ("melpa-stable" . "https://stable.melpa.org/packages/")
                                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(customize-set-value 'use-package-always-ensure t)

;; We want non-bloated HTML
(load-file (expand-file-name "ox-slimhtml.el" site/scr-dir))

;; Install dependencies
(use-package s)
(use-package htmlize)
(use-package tree-sitter
  :init
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))
(use-package tree-sitter-langs)
(use-package esxml
  :pin melpa-stable)

(org-export-define-derived-backend 'site-html
                                   'slimhtml
                                   :translate-alist
                                   '((template . site/org-html-template)
                                     (headline . site/org-html-headline)
                                     (src-block . site/org-html-src-block)))

(defun org-html-publish-to-html (plist filename pub-dir)
  (org-publish-org-to 'site-html
                      filename
                      (concat "." (or (plist-get plist :html-extension) "html"))
                      plist
                      pub-dir))

(defun site/org-custom-link-dot-export (path desc format)
  (cond
   ((eq format 'html)
    (let ((svg-path (concat (file-name-sans-extension path) ".svg")))
      (sxml-to-xml
       `(center
         (a (@ (href ,path))
            ,(shell-command-to-string (concat "dot -Tsvg "
                                              (expand-file-name (concat "." path))
                                              " | sed -nf "
                                              (expand-file-name "parse-svg.sed" site/scr-dir))))))))))

(org-add-link-type "dot" :export #'site/org-custom-link-dot-export)

;; Disable the creation of backup files
(customize-set-value 'make-backup-files nil)

;; Set various org -> html export settings
(customize-set-value 'org-publish-timestamp-directory "../.org-timestamps/")
(customize-set-value 'org-html-validation-link nil)
(customize-set-value 'org-html-html5-fancy t)
(customize-set-value 'org-html-head-include-scripts nil)
(customize-set-value 'org-html-head-include-default-style nil)
(customize-set-value 'org-html-htmlize-output-type 'css)
(customize-set-value 'org-html-doctype "html5")
(customize-set-value 'org-html-head
                     (sxml-to-xml
                      '(link (@ (rel "stylesheet")
                                (type "text/css")
                                (href "/style.css")))))
(customize-set-value 'org-publish-project-alist
                     (list
                      (list "org-sources"
                            :recursive t
                            :base-extension "org"
                            :base-directory site/src-dir
                            :publishing-directory site/pub-dir
                            :publishing-function '(org-html-publish-to-html)
                            :section-numbers nil
                            :html-extension "html"
                            :with-author nil
                            :with-smart-quotes t
                            :with-toc nil)
                      (list "static-sources"
                            :recursive t
                            :base-extension "css\\|woff2\\|svg\\|dot"
                            :base-directory site/src-dir
                            :publishing-directory site/pub-dir
                            :publishing-function 'org-publish-attachment)))

;; Publish the site
(defun site/build ()
  (interactive)
  (org-publish-all t))
