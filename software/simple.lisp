;;; simple.lisp --- simple software rep. to manipulate lines of code

;; Copyright (C) 2013  Eric Schulte

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:
(in-package :software-evolution)


;;; simple software objects
(defclass simple (software)
  ((genome   :initarg :genome   :accessor genome   :initform nil)))

(defmethod lines ((simple simple))
  (mapcar {aget :line} (genome simple)))

(defmethod genome-string ((simple simple))
  (mapconcat {format nil "~a~%"} (lines simple) ""))

(defmethod from-file ((simple simple) path)
  (with-open-file (in path)
    (setf (genome simple)
          (loop :for line = (read-line in nil)
             :while line :collect (list (cons :line line))))
    simple))

(defmethod to-file ((simple simple) file)
  (string-to-file (genome-string simple) file))

(defmethod mutate ((simple simple))
  "Randomly mutate SIMPLE."
  (unless (> (size simple) 0) (error 'mutate :text "No valid IDs" :obj simple))
  (setf (fitness simple) nil)
  (let ((mut (case (random-elt '(cut insert swap))
               (cut    `(:cut    ,(pick-bad simple)))
               (insert `(:insert ,(pick-bad simple) ,(pick-good simple)))
               (swap   `(:swap   ,(pick-bad simple) ,(pick-good simple))))))
    (push mut (edits simple))
    (apply-mutation simple mut))
  simple)

(defmethod apply-mutation ((simple simple) mutation)
  (let ((op (first mutation))
        (s1 (second mutation))
        (s2 (third mutation)))
    (with-slots (genome) simple
      (setf genome (case op
                     (:cut (append (subseq genome 0 s1)
                                   (subseq genome (1+ s1))))
                     (:insert (append (subseq genome 0 s1)
                                      (list (nth s2 genome))
                                      (subseq genome s1)))
                     (:swap (let ((tmp (nth s1 genome)))
                              (setf (nth s1 genome) (nth s2 genome))
                              (setf (nth s2 genome) tmp))
                            genome))))))


;;; Crossover
(defmethod crossover ((a simple) (b simple)) (two-point-crossover a b))

#|
(defun align-for-crossover (a b &key (test equal) key)
  "Return two offsets which align genomes A and B for maximum similarity.
TEST may be used to test for similarity and should return a boolean (number?)."
  (values 0 0))
|#

(defmethod two-point-crossover ((a simple) (b simple))
  ;; Two point crossover
  (let* ((range (min (size a) (size b)))
         (points (sort (loop :for i :below 2 :collect (random range)) #'<))
         (new (copy a)))
    (setf (genome new)
          (copy-tree (append (subseq (genome b) 0 (first points))
                             (subseq (genome a) (first points) (second points))
                             (subseq (genome b) (second points)))))
    (values new points)))

(defmethod one-point-crossover ((a simple) (b simple))
  (let* ((range (min (size a) (size b)))
         (point (random range))
         (new (copy a)))
    (setf (genome new)
          (copy-tree (append (subseq (genome b) 0 point)
                             (subseq (genome a) point))))
    (values new point)))