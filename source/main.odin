package whitespaze

import "core:strings"
import "core:bufio"
import "core:fmt"
import "core:os"

Whitespace_Mode :: enum { Help, Run, Build }

main :: proc() {
	mode: Whitespace_Mode;
	file: string;
	dest: string;
	
	for arg, arg_index in os.args[1:] {
		if arg == "-help" {
			mode = .Help;
			break;
		}
		
		if strings.starts_with(arg, "-out") {
			mode = .Build;
			
			if strings.starts_with(arg, "-out:") {
				dest = arg[5:];
			}
		} else if strings.starts_with(arg, "-") {
			fmt.printf("Option %s not recognized\n", arg);
		} else {
			if file == "" {
				mode = .Run;
				file = arg;
			} else {
				fmt.printf("Already have a file\n");
			}
		}
	}
	
	switch mode {
		case .Help: {
			fmt.print("Help text\n");
		}
		
		case .Run: {
		}
		
		case .Build: {
			if len(dest) == 0 do dest = "a"; // make this better, using the filename (without the extension if it has one, make sure it won't overwrite the source file)
		}
		
		case: panic("Invalid switch case");
	}
}

