package whitespaze

import "core:strings"
import "core:strconv"
import "core:bufio"
import "core:fmt"
import "core:os"

main :: proc() {
	Whitespace_Mode :: enum { Help, Run, Build }
	
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
			if len(file) > 0 {
				program, read_success := os.read_entire_file(file);
				if read_success {
					run_program(program);
				} else {
					fmt.eprintf("The file '%s' could not be opened or read.\n", file);
				}
			} else {
				fmt.eprintf("No input file.\n");
			}
		}
		
		case .Build: {
			if len(dest) == 0 do dest = "a"; // make this better, using the filename (without the extension if it has one, make sure it won't overwrite the source file)
		}
		
		case: panic("Invalid switch case");
	}
	
	return;
}

////////////////////////////////////////////////////////////////
// Parser

Instr_Kind :: enum { None = 0, Stack, Arithmetic, Heap, Flow_Control, IO }

Instr_Operator :: enum {
	Stack_Push, Stack_Duplicate, Stack_Copy, Stack_Swap, Stack_Discard, Stack_Slide,
	Arithmetic_Addition, Arithmetic_Subtraction, Arithmetic_Multiplication, Arithmetic_Division, Arithmetic_Modulo,
	Heap_Store, Heap_Retrieve,
	IO_Out_Char, IO_Out_Number, IO_In_Char, IO_In_Number,
}

Instr :: struct {
	kind: Instr_Kind,
	operator: Instr_Operator,
	
	number: int,
}

Instr_Format :: struct {
	kind: Instr_Kind,
	kind_string: string,
	
	operator: Instr_Operator,
	operator_string:  string,
}

@(rodata)
instr_formats := [?]Instr_Format {
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Push,      operator_string = " "},
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Duplicate, operator_string = "\n "},
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Copy,      operator_string = "\t "},
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Swap,      operator_string = "\n\t"},
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Discard,   operator_string = "\n\n"},
	Instr_Format{kind = .Stack, kind_string = " ",    operator = .Stack_Slide,     operator_string = "\t\n"},
	
	Instr_Format{kind = .Arithmetic, kind_string = "\t ", operator = .Arithmetic_Addition,       operator_string = "  "},
	Instr_Format{kind = .Arithmetic, kind_string = "\t ", operator = .Arithmetic_Subtraction,    operator_string = " \t"},
	Instr_Format{kind = .Arithmetic, kind_string = "\t ", operator = .Arithmetic_Multiplication, operator_string = " \n"},
	Instr_Format{kind = .Arithmetic, kind_string = "\t ", operator = .Arithmetic_Division,       operator_string = "\t "},
	Instr_Format{kind = .Arithmetic, kind_string = "\t ", operator = .Arithmetic_Modulo,         operator_string = "\t\t"},
	
	Instr_Format{kind = .Heap,  kind_string = "\t\t", operator = .Heap_Store,      operator_string = " "},
	Instr_Format{kind = .Heap,  kind_string = "\t\t", operator = .Heap_Retrieve,   operator_string = "\t"},
	
	Instr_Format{kind = .IO,    kind_string = "\t\n", operator = .IO_Out_Char,     operator_string = "  "},
	Instr_Format{kind = .IO,    kind_string = "\t\n", operator = .IO_Out_Number,   operator_string = " \t"},
	Instr_Format{kind = .IO,    kind_string = "\t\n", operator = .IO_In_Char,      operator_string = "\t "},
	Instr_Format{kind = .IO,    kind_string = "\t\n", operator = .IO_In_Number,    operator_string = "\t\t"},
}

is_whitespace :: proc(c: u8) -> bool {
	return c == ' ' || c == '\t' || c == '\n';
}

skip_non_whitespace :: proc(program: []u8, start: int) -> int {
	index := start;
	for index < len(program) && !is_whitespace(program[index]) {
		index += 1;
	}
	return index;
}

compare_ignoring_whitespace :: proc(program: []u8, start: int, other: string) -> (bool, int) {
	match := true;
	index := start;
	other_bytes := transmute([]u8)other;
	for b in other_bytes {
		index = skip_non_whitespace(program, index);
		if index >= len(program) || program[index] != b {
			match = false;
			break;
		}
		index += 1;
	}
	return match, index;
}

parse_number :: proc(program: []u8, start: int) -> (n: int, new_index: int) {
	number := 0;
	index := skip_non_whitespace(program, start);
	if index < len(program) && program[index] != '\n' {
		sign := program[index] == ' ' ? +1 : -1;
		index += 1;
		
		for index < len(program) {
			index = skip_non_whitespace(program, index);
			if index >= len(program) || program[index] == '\n' {
				if program[index] == '\n' do index += 1;
				break;
			}
			digit := program[index] == '\t' ? 1 : 0;
			index += 1;
			
			number = (number << 1) | digit;
		}
		
		number *= sign;
	}
	return number, index;
}

parse_instruction :: proc(program: []u8, start: int) -> (Instr, int) {
	instr: Instr;
	
	index := skip_non_whitespace(program, start);
	for format in instr_formats {
		match, new_index := compare_ignoring_whitespace(program, index, format.kind_string);
		if match {
			index = new_index;
			instr.kind = format.kind;
			
			match, new_index = compare_ignoring_whitespace(program, index, format.operator_string);
			if match {
				index = new_index;
				instr.operator = format.operator;
				
				if instr.operator == .Stack_Push || instr.operator == .Stack_Copy || instr.operator == .Stack_Slide {
					instr.number, new_index = parse_number(program, index);
					index = new_index;
				} else if false {
				}
				
				break;
			}
		}
	}
	
	if instr.kind == .None do index += 1;
	
	return instr, index;
}

////////////////////////////////////////////////////////////////
// Interpreter

run_program :: proc(program: []u8) {
	stack_top = 0;
	
	index := 0;
	for index < len(program) {
		instr, new_index := parse_instruction(program, index);
		
		#partial switch instr.operator {
			case .Stack_Push: stack_push(stack[:], &stack_top, instr.number);
			case .Stack_Duplicate: stack_duplicate(stack[:], &stack_top);
			case .Stack_Copy: stack_copy(stack[:], &stack_top, instr.number);
			case .Stack_Swap: stack_swap(stack[:], &stack_top);
			case .Stack_Discard: stack_discard(stack[:], &stack_top);
			case .Stack_Slide: /* stack_slide(stack[:], &stack_top, instr.number); */;
			
			case .Arithmetic_Addition:       arithmetic_add(stack[:], &stack_top);
			case .Arithmetic_Subtraction:    arithmetic_sub(stack[:], &stack_top);
			case .Arithmetic_Multiplication: arithmetic_mul(stack[:], &stack_top);
			case .Arithmetic_Division:       arithmetic_div(stack[:], &stack_top);
			case .Arithmetic_Modulo:         arithmetic_mod(stack[:], &stack_top);
			
			case .Heap_Store: heap_store(stack[:], &stack_top, heap[:]);
			case .Heap_Retrieve: heap_retrieve(stack[:], &stack_top, heap[:]);
			case .IO_Out_Char:   io_out_char(stack[:], &stack_top);
			case .IO_Out_Number: io_out_number(stack[:], &stack_top);
			case .IO_In_Char:    io_in_char(stack[:], &stack_top);
			case .IO_In_Number:  io_in_number(stack[:], &stack_top);
			
			case: {
				fmt.print("Unimplemented\n");
			}
		}
		
		index = new_index;
	}
}

////////////////////////////////////////////////////////////////
// Runtime helpers

stack: [1024]int;
stack_top := 0;

stack_push :: proc(stack: []int, stack_top: ^int, number: int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ < len(stack) {
		stack[stack_top^] = number;
		stack_top^ += 1;
	}
}

stack_duplicate :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 0 && stack_top^ < len(stack) {
		stack[stack_top^] = stack[stack_top^ - 1];
		stack_top^ += 1;
	}
}

stack_copy :: proc(stack: []int, stack_top: ^int, number: int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ < len(stack) && number >= 0 && number < stack_top^ {
		stack[stack_top^] = stack[number];
		stack_top^ += 1;
	}
}

stack_swap :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 && stack_top^ < len(stack) {
		stack[stack_top^], stack[stack_top^ - 1] = stack[stack_top^ - 1], stack[stack_top^];
	}
}

stack_discard :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 0 {
		stack_top^ -= 1;
	}
}

arithmetic_add :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		stack[stack_top^ - 1] += stack[stack_top^];
		stack_top^ -= 1;
	}
}

arithmetic_sub :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		stack[stack_top^ - 1] -= stack[stack_top^];
		stack_top^ -= 1;
	}
}

arithmetic_mul :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		stack[stack_top^ - 1] *= stack[stack_top^];
		stack_top^ -= 1;
	}
}

arithmetic_div :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		stack[stack_top^ - 1] /= stack[stack_top^] if stack[stack_top^] != 0 else 1;
		stack_top^ -= 1;
	}
}

arithmetic_mod :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		stack[stack_top^ - 1] %= stack[stack_top^] if stack[stack_top^] != 0 else 1;
		stack_top^ -= 1;
	}
}

heap: [1024]int;

heap_store :: proc(stack: []int, stack_top: ^int, heap: []int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 1 {
		number := stack[stack_top^];
		address := stack[stack_top^ - 1];
		
		if address >= 0 && address < len(heap) {
			heap[address] = number;
		}
	}
}

heap_retrieve :: proc(stack: []int, stack_top: ^int, heap: []int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 0 && stack_top^ < len(stack){
		address := stack[stack_top^];
		
		if address >= 0 && address < len(heap) {
			number := heap[address];
			
			stack[stack_top^] = number;
			stack_top^ += 1;
		}
	}
}

io_out_char :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 0 {
		char := stack[stack_top^ - 1];
		fmt.printf("%c", cast(i8)char);
	}
}

io_out_number :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ > 0 {
		number := stack[stack_top^ - 1];
		fmt.printf("%i", number);
	}
}

io_in_char :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ < len(stack) {
		data: [1]u8;
		total_read, err := os.read_at_least(os.stdin, data[:], 1);
		
		if err == nil {
			char := cast(i8)data[0];
			
			stack[stack_top^] = cast(int)char;
			stack_top^ += 1;
		}
	}
}

io_in_number :: proc(stack: []int, stack_top: ^int) {
	assert(stack_top != nil &&
		   stack_top^ >= 0  &&
		   stack_top^ <= len(stack));
	
	if stack_top^ < len(stack) {
		data: [1]u8;
		total_read, err := os.read_at_least(os.stdin, data[:], 1);
		
		if err == nil {
			number, ok := strconv.digit_to_int(cast(rune)data[0]);
			if !ok do number = 0;
			
			stack[stack_top^] = number;
			stack_top^ += 1;
		}
	}
}

when false {
	skip_non_whitespace :: proc(program: []u8, start: int) -> int {
		index := start;
		for done := false; index < len(program) && !done; {
			done = true;
			if !is_whitespace(program[index]) {
				done = false;
				for index < len(program) && !is_whitespace(program[index]) do index += 1;
			}
		}
		return index;
	}
}
