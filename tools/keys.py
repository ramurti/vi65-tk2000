"""Harness key arguments for a string: one -k per key, a key every STEP seconds.

Usage: keys.py START "text" -> prints -k arguments for build/run (zsh: run ... $(keys.py ...))
Text: plain characters are TK2000 keys (lower case = the key alone, upper case = SHIFT + key);
- = + ^ @ are CTRL + SHIFT + I O P K L; {ret} {left} {right} {up} {down} {esc} (= CTRL-C),
{bs} (= CTRL-H) and {S-x} (SHIFT + x) are special keys.
"""
import re
import sys

STEP, HOLD = 0.15, 0.06
SHIFTED = {'!': '1', '"': '2', '#': '3', '$': '4', '%': '5', '&': '6', "'": '7', '(': '8',
           ')': '9', '*': '0', ';': ':',
           '<': ',', '>': '.', '/': '?'}
CTRLSHIFTED = {'-': 'i', '=': 'o', '+': 'p', '^': 'k', '@': 'l'}
NAMES = {' ': 'space', ',': ',', '.': '.', ':': ':', '?': '?'}


def args(start, text):
    out, t = [], start
    for tok in re.findall(r"\{[^}]+\}|.", text, re.S):
        if tok in ("{esc}", "{bs}"):
            key = "c" if tok == "{esc}" else "h"
            out += ["-k", f"{t:.2f}:{HOLD + 0.08:.2f}:ctrl", "-k", f"{t + 0.04:.2f}:{HOLD:.2f}:{key}"]
        elif tok in CTRLSHIFTED:
            out += ["-k", f"{t:.2f}:{HOLD + 0.08:.2f}:ctrl", "-k", f"{t + 0.04:.2f}:{HOLD:.2f}:S-{CTRLSHIFTED[tok]}"]
        elif tok.startswith("{"):
            out += ["-k", f"{t:.2f}:{HOLD}:{tok[1:-1].replace('ret', 'return')}"]
        elif tok in SHIFTED:
            out += ["-k", f"{t:.2f}:{HOLD}:S-{SHIFTED[tok]}"]
        elif tok.isupper():
            out += ["-k", f"{t:.2f}:{HOLD}:S-{tok.lower()}"]
        else:
            out += ["-k", f"{t:.2f}:{HOLD}:{NAMES.get(tok, tok)}"]
        t += STEP + (0.15 if tok.startswith("{") else 0)
    return out


if __name__ == "__main__":
    print(" ".join(args(float(sys.argv[1]), sys.argv[2])))
