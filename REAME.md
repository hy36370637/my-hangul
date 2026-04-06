# my-hangul.el

**A Lightweight, Native Dubeolsik (2-Bureol) Hangul Input Method for Emacs**

`my-hangul.el` is a streamlined Korean input method for Emacs, inspired by the architecture of **NavilIME**. It provides a smooth "Dokkaebibul" (ghost-fire) composition experience while maintaining full compatibility with Emacs' native keybinding system.

## Key Features

* **NavilIME Architecture**: Ported logic that strictly separates *preedit* (composing) and *commit* (finalized) states for a reliable and modern input feel.
* **Vowel Expansion**: Supports intuitive double-tap sequences for complex vowels (e.g., `o`+`o` → `ㅒ`, `p`+`p` → `ㅖ`) in addition to standard `Shift` keys.
* **Emacs Friendly**: Designed to pass through `Control`, `Meta`, and `Super` combinations seamlessly. Your custom Emacs shortcuts will work without interference even while the input method is active.
* **Zero Dependencies**: Written in pure Elisp using built-in `quail` and `overlay` libraries. No external processes or specialized OS-level configuration required.

## Installation

1.  Clone this repository to your local machine:
    ```bash
    git clone [https://github.com/hy36370637/my-hangul.git](https://github.com/hy36370637/my-hangul.git)
    ```

2.  Add the following to your `init.el` or `.emacs`:
    ```elisp
    (add-to-list 'load-path "/path/to/my-hangul")
    (require 'my-hangul)

    ;; Optional: Set as the default Korean input method
    (setq default-input-method "korean-my-hangul")
    ```

## Usage

* **Toggle Input Method**: Press `C-\` (default Emacs toggle).
* **Select Method**: If not set as default, run `M-x set-input-method` and select `korean-my-hangul`.
* **Input Logic**:
    * Standard Dubeolsik layout.
    * `o` + `o` → `ㅒ`
    * `p` + `p` → `ㅖ`
    * Standard `Shift` keys (Q, W, E, R, T, O, P) are fully supported.

## Technical Details

The input method utilizes a specialized state-machine automaton to handle the transitions between Chosung (Initial), Jungsung (Vowel), and Jongsung (Final) characters. It includes a `jong-to-cho` transition table to facilitate the "Dokkaebibul" effect, ensuring that the final consonant of a previous syllable correctly moves to the initial position of the next syllable when a vowel is followed.

## License

[MIT License](LICENSE)
