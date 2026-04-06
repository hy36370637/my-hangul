;; -*- lexical-binding: t -*-
;;  my-hangul.el
;;  두벌식 한글 입력기
;;  - NavilIME 구조 포팅 (preedit/commit 분리)
;;  - ㅐ+ㅐ→ㅒ, ㅔ+ㅔ→ㅖ 지원
;;  - C-/M-/s- 조합키는 Emacs에 그대로 전달

(require 'quail)

;;
;; ============================================================
;; 자판 테이블 (표준 두벌식)
;;
;; q=ㅂ  w=ㅈ  e=ㄷ  r=ㄱ  t=ㅅ  y=ㅛ  u=ㅕ  i=ㅑ  o=ㅐ  p=ㅔ
;; a=ㅁ  s=ㄴ  d=ㅇ  f=ㄹ  g=ㅎ  h=ㅗ  j=ㅓ  k=ㅏ  l=ㅣ
;; z=ㅋ  x=ㅌ  c=ㅊ  v=ㅍ  b=ㅠ  n=ㅜ  m=ㅡ
;; Q=ㅃ  W=ㅉ  E=ㄸ  R=ㄲ  T=ㅆ  O=ㅒ  P=ㅖ
;; ============================================================

;; 초성: Keyboard002.swift no_shift_cho + shift_cho 기준
(defconst my-hangul-chosung-table
  '(;; 쌍자음 — 연속입력 및 Shift 모두 지원
    ("Q"  . #x1108)  ; ㅃ  Shift+q
    ("qq" . #x1108)  ; ㅃ  연속
    ("W"  . #x110D)  ; ㅉ  Shift+w
    ("ww" . #x110D)  ; ㅉ  연속
    ("E"  . #x1104)  ; ㄸ  Shift+e
    ("ee" . #x1104)  ; ㄸ  연속
    ("R"  . #x1101)  ; ㄲ  Shift+r
    ("rr" . #x1101)  ; ㄲ  연속
    ("T"  . #x110A)  ; ㅆ  Shift+t
    ("tt" . #x110A)  ; ㅆ  연속
    ;; 단일 자음
    ("q"  . #x1107)  ; ㅂ
    ("w"  . #x110C)  ; ㅈ
    ("e"  . #x1103)  ; ㄷ
    ("r"  . #x1100)  ; ㄱ
    ("t"  . #x1109)  ; ㅅ
    ("a"  . #x1106)  ; ㅁ
    ("A"  . #x1106)  ; ㅁ  (Shift 늦게 뗄 때 대비)
    ("s"  . #x1102)  ; ㄴ
    ("S"  . #x1102)  ; ㄴ
    ("d"  . #x110B)  ; ㅇ
    ("D"  . #x110B)  ; ㅇ
    ("f"  . #x1105)  ; ㄹ
    ("F"  . #x1105)  ; ㄹ
    ("g"  . #x1112)  ; ㅎ
    ("G"  . #x1112)  ; ㅎ
    ("z"  . #x110F)  ; ㅋ
    ("Z"  . #x110F)  ; ㅋ
    ("x"  . #x1110)  ; ㅌ
    ("X"  . #x1110)  ; ㅌ
    ("c"  . #x110E)  ; ㅊ
    ("C"  . #x110E)  ; ㅊ
    ("v"  . #x1111)  ; ㅍ
    ("V"  . #x1111)) ; ㅍ
  "두벌식 초성 테이블 (Keyboard002 기준).")

;; 중성: Keyboard002.swift jungsung_layout 기준
(defconst my-hangul-jungsung-table
  '(;; 이중모음 연속입력 ★
    ("oo" . #x1164)  ; ㅒ  o+o
    ("pp" . #x1168)  ; ㅖ  p+p
    ;; 이중모음 (복합)
    ("hk" . #x116A)  ; ㅘ  h+k
    ("ho" . #x116B)  ; ㅙ  h+o
    ("hl" . #x116C)  ; ㅚ  h+l
    ("nj" . #x116F)  ; ㅝ  n+j
    ("np" . #x1170)  ; ㅞ  n+p
    ("nl" . #x1171)  ; ㅟ  n+l
    ("ml" . #x1174)  ; ㅢ  m+l
    ;; Shift 모음
    ("O"  . #x1164)  ; ㅒ  Shift+o
    ("P"  . #x1168)  ; ㅖ  Shift+p
    ;; 단일 모음 — 대문자도 매핑 (Keyboard002 주석 참고)
    ("y"  . #x116D)  ; ㅛ
    ("Y"  . #x116D)  ; ㅛ
    ("u"  . #x1167)  ; ㅕ
    ("U"  . #x1167)  ; ㅕ
    ("i"  . #x1163)  ; ㅑ
    ("I"  . #x1163)  ; ㅑ
    ("o"  . #x1162)  ; ㅐ  (이중모음 있으므로 대문자 맵핑 안함)
    ("p"  . #x1166)  ; ㅔ  (이중모음 있으므로 대문자 맵핑 안함)
    ("h"  . #x1169)  ; ㅗ
    ("H"  . #x1169)  ; ㅗ
    ("j"  . #x1165)  ; ㅓ
    ("J"  . #x1165)  ; ㅓ
    ("k"  . #x1161)  ; ㅏ
    ("K"  . #x1161)  ; ㅏ
    ("l"  . #x1175)  ; ㅣ
    ("L"  . #x1175)  ; ㅣ
    ("b"  . #x1172)  ; ㅠ
    ("B"  . #x1172)  ; ㅠ
    ("n"  . #x116E)  ; ㅜ
    ("N"  . #x116E)  ; ㅜ
    ("m"  . #x1173)  ; ㅡ
    ("M"  . #x1173)) ; ㅡ
  "두벌식 중성 테이블 (Keyboard002 기준).")

;; 종성: Keyboard002.swift jongsung_layout 기준
;; 주의: tt→ㅆ 없음. 종성 ㅆ은 T(Shift+t)로만.
(defconst my-hangul-jongsung-table
  '(;; 겹받침
    ("rt" . #x11AA)  ; ㄳ
    ("sw" . #x11AC)  ; ㄵ
    ("sg" . #x11AD)  ; ㄶ
    ("fr" . #x11B0)  ; ㄺ
    ("fa" . #x11B1)  ; ㄻ
    ("fq" . #x11B2)  ; ㄼ
    ("ft" . #x11B3)  ; ㄽ
    ("fx" . #x11B4)  ; ㄾ
    ("fv" . #x11B5)  ; ㄿ
    ("fg" . #x11B6)  ; ㅀ
    ("qt" . #x11B9)  ; ㅄ
    ;; 단일 종성
    ("r"  . #x11A8)  ; ㄱ
    ("R"  . #x11A9)  ; ㄲ  Shift+r
    ("s"  . #x11AB)  ; ㄴ
    ("S"  . #x11AB)  ; ㄴ
    ("e"  . #x11AE)  ; ㄷ
    ("E"  . #x11AE)  ; ㄷ
    ("f"  . #x11AF)  ; ㄹ
    ("F"  . #x11AF)  ; ㄹ
    ("a"  . #x11B7)  ; ㅁ
    ("A"  . #x11B7)  ; ㅁ
    ("q"  . #x11B8)  ; ㅂ
    ("Q"  . #x11B8)  ; ㅂ
    ("t"  . #x11BA)  ; ㅅ
    ("T"  . #x11BB)  ; ㅆ  Shift+t 로만 (tt 연속입력 불가 — 햇사과 문제)
    ("d"  . #x11BC)  ; ㅇ
    ("D"  . #x11BC)  ; ㅇ
    ("w"  . #x11BD)  ; ㅈ
    ("W"  . #x11BD)  ; ㅈ
    ("c"  . #x11BE)  ; ㅊ
    ("C"  . #x11BE)  ; ㅊ
    ("z"  . #x11BF)  ; ㅋ
    ("Z"  . #x11BF)  ; ㅋ
    ("x"  . #x11C0)  ; ㅌ
    ("X"  . #x11C0)  ; ㅌ
    ("v"  . #x11C1)  ; ㅍ
    ("V"  . #x11C1)  ; ㅍ
    ("g"  . #x11C2)  ; ㅎ
    ("G"  . #x11C2)) ; ㅎ
  "두벌식 종성 테이블 (Keyboard002 기준).")

;; 종성 → (앞글자에 남는 종성 . 다음글자 초성) 변환
;; 겹받침: 앞 자음은 현 글자 종성으로 남고, 뒤 자음은 다음 글자 초성으로
(defconst my-hangul-jong-to-cho
  '((#x11A8 . (nil    . #x1100))  ; ㄱ       -> X  + ㄱ
    (#x11A9 . (nil    . #x1101))  ; ㄲ       -> X  + ㄲ
    (#x11AA . (#x11A8 . #x1109))  ; ㄳ(ㄱㅅ) -> ㄱ + ㅅ
    (#x11AB . (nil    . #x1102))  ; ㄴ       -> X  + ㄴ
    (#x11AC . (#x11AB . #x110C))  ; ㄵ(ㄴㅈ) -> ㄴ + ㅈ
    (#x11AD . (#x11AB . #x1112))  ; ㄶ(ㄴㅎ) -> ㄴ + ㅎ
    (#x11AE . (nil    . #x1103))  ; ㄷ       -> X  + ㄷ
    (#x11AF . (nil    . #x1105))  ; ㄹ       -> X  + ㄹ
    (#x11B0 . (#x11AF . #x1100))  ; ㄺ(ㄹㄱ) -> ㄹ + ㄱ
    (#x11B1 . (#x11AF . #x1106))  ; ㄻ(ㄹㅁ) -> ㄹ + ㅁ
    (#x11B2 . (#x11AF . #x1107))  ; ㄼ(ㄹㅂ) -> ㄹ + ㅂ
    (#x11B3 . (#x11AF . #x1109))  ; ㄽ(ㄹㅅ) -> ㄹ + ㅅ
    (#x11B4 . (#x11AF . #x1110))  ; ㄾ(ㄹㅌ) -> ㄹ + ㅌ
    (#x11B5 . (#x11AF . #x1111))  ; ㄿ(ㄹㅍ) -> ㄹ + ㅍ
    (#x11B6 . (#x11AF . #x1112))  ; ㅀ(ㄹㅎ) -> ㄹ + ㅎ
    (#x11B7 . (nil    . #x1106))  ; ㅁ       -> X  + ㅁ
    (#x11B8 . (nil    . #x1107))  ; ㅂ       -> X  + ㅂ
    (#x11B9 . (#x11B8 . #x1109))  ; ㅄ(ㅂㅅ) -> ㅂ + ㅅ
    (#x11BA . (nil    . #x1109))  ; ㅅ       -> X  + ㅅ
    (#x11BB . (nil    . #x110A))  ; ㅆ       -> X  + ㅆ
    (#x11BC . (nil    . #x110B))  ; ㅇ       -> X  + ㅇ
    (#x11BD . (nil    . #x110C))  ; ㅈ       -> X  + ㅈ
    (#x11BE . (nil    . #x110E))  ; ㅊ       -> X  + ㅊ
    (#x11BF . (nil    . #x110F))  ; ㅋ       -> X  + ㅋ
    (#x11C0 . (nil    . #x1110))  ; ㅌ       -> X  + ㅌ
    (#x11C1 . (nil    . #x1111))  ; ㅍ       -> X  + ㅍ
    (#x11C2 . (nil    . #x1112))) ; ㅎ       -> X  + ㅎ
  "종성 -> (남는종성 . 다음초성) 변환 테이블.")

;;
;; ============================================================
;; 조합 상태 변수
;; cho-key, jung-key, jong-key 를 각각 별도 추적 (핵심)
;; ============================================================

(defvar-local my-hangul--cho      nil  "현재 초성 유니코드.")
(defvar-local my-hangul--jung     nil  "현재 중성 유니코드.")
(defvar-local my-hangul--jong     nil  "현재 종성 유니코드.")
(defvar-local my-hangul--cho-key  ""   "초성 키 시퀀스 (쌍자음 판별용).")
(defvar-local my-hangul--jung-key ""   "중성 키 시퀀스 (복합모음 판별용).")
(defvar-local my-hangul--jong-key ""   "종성 키 시퀀스 (겹받침 판별용).")
(defvar-local my-hangul--overlay  nil  "Preedit overlay.")

;;
;; ============================================================
;; 유니코드 조합
;; ============================================================

(defun my-hangul--compose ()
  "현재 상태 → 유니코드 문자열."
  (let ((cho  my-hangul--cho)
        (jung my-hangul--jung)
        (jong my-hangul--jong))
    (cond
     ((and cho jung jong)
      (string (decode-char 'ucs
               (+ #xAC00
                  (* (- cho  #x1100) 21 28)
                  (* (- jung #x1161) 28)
                  (- jong #x11A7)))))
     ((and cho jung)
      (string (decode-char 'ucs
               (+ #xAC00
                  (* (- cho  #x1100) 21 28)
                  (* (- jung #x1161) 28)))))
     (jung (string (decode-char 'ucs jung)))
     ;; 초성 → 호환 자모 변환 (초성 순서 ≠ 호환 자모 순서이므로 테이블 필요)
     (cho  (let ((cho-to-hohan
                  '((#x1100 . #x3131)  ; ㄱ
                    (#x1101 . #x3132)  ; ㄲ
                    (#x1102 . #x3134)  ; ㄴ
                    (#x1103 . #x3137)  ; ㄷ
                    (#x1104 . #x3138)  ; ㄸ
                    (#x1105 . #x3139)  ; ㄹ
                    (#x1106 . #x3141)  ; ㅁ
                    (#x1107 . #x3142)  ; ㅂ
                    (#x1108 . #x3143)  ; ㅃ
                    (#x1109 . #x3145)  ; ㅅ
                    (#x110A . #x3146)  ; ㅆ
                    (#x110B . #x3147)  ; ㅇ
                    (#x110C . #x3148)  ; ㅈ
                    (#x110D . #x3149)  ; ㅉ
                    (#x110E . #x314A)  ; ㅊ
                    (#x110F . #x314B)  ; ㅋ
                    (#x1110 . #x314C)  ; ㅌ
                    (#x1111 . #x314D)  ; ㅍ
                    (#x1112 . #x314E)))) ; ㅎ
             (string (decode-char 'ucs
                      (or (cdr (assoc cho cho-to-hohan)) #x3131)))))
     (t    ""))))

;;
;; ============================================================
;; 헬퍼
;; ============================================================

(defun my-hangul--lookup (table key)
  (cdr (assoc key table)))

(defun my-hangul--reset ()
  (setq my-hangul--cho      nil
        my-hangul--jung     nil
        my-hangul--jong     nil
        my-hangul--cho-key  ""
        my-hangul--jung-key ""
        my-hangul--jong-key ""))

;;
;; ============================================================
;; Preedit overlay
;; ============================================================

(defun my-hangul--show-preedit ()
  (unless (and my-hangul--overlay
               (overlay-buffer my-hangul--overlay))
    (setq my-hangul--overlay (make-overlay (point) (point)))
    (overlay-put my-hangul--overlay 'face 'underline))
  (overlay-put my-hangul--overlay 'before-string (my-hangul--compose))
  (move-overlay my-hangul--overlay (point) (point)))

(defun my-hangul--clear-preedit ()
  (when (and my-hangul--overlay
             (overlay-buffer my-hangul--overlay))
    (delete-overlay my-hangul--overlay))
  (setq my-hangul--overlay nil))

(defun my-hangul--commit-current ()
  "현재 조합 글자 확정 후 상태 초기화."
  (let ((str (my-hangul--compose)))
    (my-hangul--clear-preedit)
    (when (> (length str) 0)
      (insert str)))
  (my-hangul--reset))

;;
;; ============================================================
;; 키 처리 오토마타
;; ============================================================

(defun my-hangul--handle (ch)
  "키 문자열 CH 하나를 처리."
  (cond

   ;; ── 1. 종성 있음 ─────────────────────────────────────────
   (my-hangul--jong
    (let* ((jong-try (concat my-hangul--jong-key ch))
           (jong2    (my-hangul--lookup my-hangul-jongsung-table jong-try))
           (is-jung  (my-hangul--lookup my-hangul-jungsung-table ch)))
      (cond
       ;; 겹받침 가능
       (jong2
        (setq my-hangul--jong     jong2
              my-hangul--jong-key jong-try)
        (my-hangul--show-preedit))

       ;; 중성 입력 → 도깨비불
       (is-jung
        (let* ((split   (cdr (assoc my-hangul--jong my-hangul-jong-to-cho)))
               (rem-jong (car split))   ; 앞글자에 남는 종성 (겹받침 앞자음)
               (new-cho  (cdr split)))  ; 다음글자 초성 (겹받침 뒷자음)
          ;; 남는 종성으로 교체 후 현재 글자 확정
          (setq my-hangul--jong     rem-jong
                my-hangul--jong-key "")
          (my-hangul--commit-current)
          ;; 새 글자 시작: 분리된 초성 + 새 중성
          (setq my-hangul--cho      new-cho
                my-hangul--cho-key  ""
                my-hangul--jung     is-jung
                my-hangul--jung-key ch)
          (my-hangul--show-preedit)))

       ;; 그 외 → 현재 확정, 새 글자
       (t
        (my-hangul--commit-current)
        (my-hangul--handle ch)))))

   ;; ── 2. 중성 있음 ─────────────────────────────────────────
   (my-hangul--jung
    (let* ((jung-try (concat my-hangul--jung-key ch))
           (jung2    (my-hangul--lookup my-hangul-jungsung-table jung-try))
           (jong1    (my-hangul--lookup my-hangul-jongsung-table ch)))
      (cond
       ;; 복합 중성 (oo→ㅒ, pp→ㅖ, hk→ㅘ 등) — jung-key 기준
       (jung2
        (setq my-hangul--jung     jung2
              my-hangul--jung-key jung-try)
        (my-hangul--show-preedit))

       ;; 종성 가능
       (jong1
        (setq my-hangul--jong     jong1
              my-hangul--jong-key ch)
        (my-hangul--show-preedit))

       ;; 새 글자 시작
       (t
        (my-hangul--commit-current)
        (my-hangul--handle ch)))))

   ;; ── 3. 초성 있음 ─────────────────────────────────────────
   (my-hangul--cho
    (let* ((cho-try (concat my-hangul--cho-key ch))
           (cho2    (my-hangul--lookup my-hangul-chosung-table cho-try))
           (jung1   (my-hangul--lookup my-hangul-jungsung-table ch)))
      (cond
       ;; 쌍자음 (rr→ㄲ, tt→ㅆ 등) — 초성 단계에서만!
       (cho2
        (setq my-hangul--cho     cho2
              my-hangul--cho-key cho-try)
        (my-hangul--show-preedit))

       ;; 중성 입력
       (jung1
        (setq my-hangul--jung     jung1
              my-hangul--jung-key ch)
        (my-hangul--show-preedit))

       ;; 새 글자 시작
       (t
        (my-hangul--commit-current)
        (my-hangul--handle ch)))))

   ;; ── 4. 빈 상태 ───────────────────────────────────────────
   (t
    (let ((cho1  (my-hangul--lookup my-hangul-chosung-table ch))
          (jung1 (my-hangul--lookup my-hangul-jungsung-table ch)))
      (cond
       (cho1
        (setq my-hangul--cho     cho1
              my-hangul--cho-key ch)
        (my-hangul--show-preedit))
       (jung1
        (setq my-hangul--jung     jung1
              my-hangul--jung-key ch)
        (my-hangul--show-preedit))
       (t
        ;; 한글 아님 (숫자, 기호 등) → 확정 후 직접 삽입
        (my-hangul--commit-current)
        (insert ch)))))))

;;
;; ============================================================
;; 백스페이스
;; ============================================================

(defun my-hangul--backspace ()
  "자모 단위 백스페이스."
  (cond
   ;; 종성 있음 → 종성 제거
   (my-hangul--jong
    (setq my-hangul--jong     nil
          my-hangul--jong-key "")
    (my-hangul--show-preedit))
   ;; 중성 복합 → 첫 글자로 복구
   ((and my-hangul--jung (> (length my-hangul--jung-key) 1))
    (let* ((fk   (substring my-hangul--jung-key 0 1))
           (fval (my-hangul--lookup my-hangul-jungsung-table fk)))
      (setq my-hangul--jung     fval
            my-hangul--jung-key fk))
    (my-hangul--show-preedit))
   ;; 중성 단일 → 중성 제거
   (my-hangul--jung
    (setq my-hangul--jung     nil
          my-hangul--jung-key "")
    (if my-hangul--cho
        (my-hangul--show-preedit)
      (my-hangul--clear-preedit)))
   ;; 초성 쌍자음 → 첫 글자로 복구
   ((and my-hangul--cho (> (length my-hangul--cho-key) 1))
    (let* ((fk   (substring my-hangul--cho-key 0 1))
           (fval (my-hangul--lookup my-hangul-chosung-table fk)))
      (setq my-hangul--cho     fval
            my-hangul--cho-key fk))
    (my-hangul--show-preedit))
   ;; 초성 단일 → 초성 제거
   (my-hangul--cho
    (setq my-hangul--cho     nil
          my-hangul--cho-key "")
    (my-hangul--clear-preedit))
   ;; 조합 없음 → 앞 글자 삭제
   (t
    (delete-char -1))))

;;
;; ============================================================
;; 입력 메서드 메인 루프
;; ============================================================

(defun my-hangul--alpha-p (key)
  "KEY 가 알파벳(A-Z, a-z)이면 t."
  (and (>= key ?A)
       (<= key ?z)
       (not (and (> key ?Z) (< key ?a)))))

(defun my-hangul-input-method (key)
  "my-hangul 입력 메서드 진입점."
  (if (or buffer-read-only
          (not (my-hangul--alpha-p key)))
      (list key)
    (let ((input-method-function nil)
          (echo-keystrokes 0)
          (help-char nil))
      (my-hangul--handle (string key))
      (unwind-protect
          (catch 'my-hangul-exit
            (while t
              (let* ((seq      (read-key-sequence nil))
                     (next-key (and (stringp seq)
                                    (= 1 (length seq))
                                    (aref seq 0))))
                (cond
                 ;; 백스페이스
                 ((eq next-key ?\d)
                  (my-hangul--backspace))
                 ;; 알파벳 → 계속 조합
                 ((and next-key (my-hangul--alpha-p next-key))
                  (my-hangul--handle (string next-key)))
                 ;; 그 외 (보조키, 숫자, Space, Enter 등)
                 ;; → 현재 글자 확정 후 Emacs에 그대로 전달
                 (t
                  (my-hangul--commit-current)
                  (setq unread-command-events
                        (nconc (listify-key-sequence seq)
                               unread-command-events))
                  (throw 'my-hangul-exit nil))))))
        (my-hangul--commit-current)
        (my-hangul--clear-preedit)))))

;;
;; ============================================================
;; 입력기 등록
;; ============================================================

(defun my-hangul-activate (&rest _)
  "my-hangul 입력기 활성화."
  (setq deactivate-current-input-method-function #'my-hangul-deactivate)
  (setq-local input-method-function #'my-hangul-input-method))

(defun my-hangul-deactivate ()
  "my-hangul 입력기 비활성화."
  (my-hangul--commit-current)
  (my-hangul--clear-preedit)
  (kill-local-variable 'input-method-function))

(register-input-method
 "korean-my-hangul"
 "Korean"
 #'my-hangul-activate
 "한2"
 "두벌식 한글 입력기 (my-hangul)
ㅐ+ㅐ→ㅒ, ㅔ+ㅔ→ㅖ 지원
C-/M-/s- 조합키는 Emacs에 그대로 전달")

(provide 'my-hangul)
;;; my-hangul.el ends here
