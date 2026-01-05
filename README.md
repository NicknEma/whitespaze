<p align="center">
    <img src="assets/icon.png" alt="Whitespaze logo." style="width:25%">
</p>

# Whitespaze
A whitespace interpreter and whitespace-to-C transpiler written in Odin.

## What is whitespace?
[Whitespace](https://en.wikipedia.org/wiki/Whitespace_(programming_language)) is an esoteric programming language created in 2003 by Edwin Brady and Chris Morris. The only significant characters are the space (' ' or 32), the horizontal tabstop ('\t' or 9) and the line feed ('\n' or 10). All other characters are ignored.

More about Whitespace [on Progopedia](http://progopedia.com/language/whitespace/).

## Build
#### Windows
- Make sure you have [Visual Studio](https://learn.microsoft.com/en-us/visualstudio/install/install-visual-studio?view=vs-2022) installed on your device.
- Install the [Odin compiler](https://github.com/odin-lang/Odin) and [add its location to the `path`](https://www.computerhope.com/issues/ch000549.htm) environment variable.
- Either start a [64-bit developer command prompt](https://learn.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell?view=vs-2022) or start a regular command prompt and run `vcvars64.bat`.
- Run `build.bat`.

