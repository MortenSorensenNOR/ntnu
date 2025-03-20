#include "tree.h"
#include "vslc.h"

// This header defines a bunch of macros we can use to emit assembly to stdout
#include "emit.h"

// In the System V calling convention, the first 6 integer parameters are passed in registers
#define NUM_REGISTER_PARAMS 6
static const char* REGISTER_PARAMS[6] = {RDI, RSI, RDX, RCX, R8, R9};

// Takes in a symbol of type SYMBOL_FUNCTION, and returns how many parameters the function takes
#define FUNC_PARAM_COUNT(func) ((func)->node->children[1]->n_children)

static void generate_stringtable(void);
static void generate_global_variables(void);
static void generate_function(symbol_t* function);
static void generate_expression(node_t* expression);
static void generate_statement(node_t* node);
static void generate_main(symbol_t* first);

// Entry point for code generation
void generate_program(void) {
    generate_stringtable();
    generate_global_variables();

    // This directive announces that the following assembly belongs to the .text section,
    // which is the section where all executable assembly lives
    DIRECTIVE(".text");

    // TODO: (Part of 2.3)
    // For each function in global_symbols, generate it using generate_function ()
    for (size_t i = 0; i < global_symbols->n_symbols; ++i) {
        symbol_t* sym = global_symbols->symbols[i];
        if (sym->type == SYMBOL_FUNCTION) {
            generate_function(sym);
        }
    }

    // TODO: (Also part of 2.3)
    // In VSL, the topmost function in a program is its entry point.
    // We want to be able to take parameters from the command line,
    // and have them be sent into the entry point function.
    //
    // Due to the fact that parameters are all passed as strings,
    // and passed as the (argc, argv)-pair, we need to make a wrapper for our entry function.
    // This wrapper handles string -> int64_t conversion, and is already implemented.
    // call generate_main ( <entry point function symbol> );
    symbol_t* entry = NULL;
    for (size_t i = 0; i < global_symbols->n_symbols; ++i) {
        if (global_symbols->symbols[i]->type == SYMBOL_FUNCTION) {
            entry = global_symbols->symbols[i];
            break;
        }
    }
    if (entry == NULL) {
        fprintf(stderr, "No entry function found. Returning.\n");
        return;
    }
    generate_main(entry);
}

// Prints one .asciz entry for each string in the global string_list
static void generate_stringtable(void) {
    // This section is where read-only string data is stored
    // It is called .rodata on Linux, and "__TEXT, __cstring" on macOS
    DIRECTIVE(".section %s", ASM_STRING_SECTION);

    // These strings are used by printf
    DIRECTIVE("intout: .asciz \"%s\"", "%ld");
    DIRECTIVE("strout: .asciz \"%s\"", "%s");
    // This string is used by the entry point-wrapper
    DIRECTIVE("errout: .asciz \"%s\"", "Wrong number of arguments");

    // TODO 2.1: Print all strings in the program here, with labels you can refer to later
    // You have access to the global variables string_list and string_list_len from symbols.c
    for (size_t i = 0; i < string_list_len; i++) {
        char* str = string_list[i];
        DIRECTIVE("string%ld: .asciz %s", i, str);
    }    
}

// Prints .zero entries in the .bss section to allocate room for global variables and arrays
static void generate_global_variables(void)
{
    // This section is where zero-initialized global variables lives
    // It is called .bss on linux, and "__DATA, __bss" on macOS
    DIRECTIVE(".section %s", ASM_BSS_SECTION);
    DIRECTIVE(".align 8");

    // TODO 2.2: Fill this section with all global variables and global arrays
    // Give each a label you can find later, and the appropriate size.
    // Regular variables are 8 bytes, while arrays are 8 bytes per element.
    // Remember to mangle the name in some way, to avoid collisions with labels
    // (for example, put a '.' in front of the symbol name)

    // As an example, to set aside 16 bytes and label it .myBytes, write:
    // DIRECTIVE(".myBytes: .zero 16")
    
    for (size_t i = 0; i < global_symbols->n_symbols; ++i) {
        symbol_t* sym = global_symbols->symbols[i];
        if (sym->type == SYMBOL_GLOBAL_VAR) {
            DIRECTIVE(".%s: .zero %d", sym->name, 8);
        } else if (sym->type == SYMBOL_GLOBAL_ARRAY) {
            size_t num_elems = sym->node->children[1]->data.number_literal;
            DIRECTIVE(".%s: .zero %ld", sym->name, 8 * num_elems);
        }
    }
}

// Global variable used to make the functon currently being generated accessible from anywhere
static symbol_t* current_function;

// Prints the entry point. preamble, statements and epilouge of the given function
static void generate_function(symbol_t* function) {
    // TODO: 2.3
    DIRECTIVE(".%s:", function->name);

    // TODO: 2.3.1 Do the prologue, including call frame building and parameter pushing
    // Tip: use the definitions REGISTER_PARAMS and NUM_REGISTER_PARAMS at the top of this file
    PUSHQ("%rbp"); 
    MOVQ("%rsp", "%rbp");

    // Push parameters to stack
    for (size_t i = 0; i < function->function_symtable->n_symbols; i++) {
        symbol_t* sym = function->function_symtable->symbols[i];
        if (sym->type == SYMBOL_PARAMETER) {
            if (i > 5) 
                continue;
            PUSHQ(REGISTER_PARAMS[i]);
        } else if (sym->type == SYMBOL_LOCAL_VAR) {
            PUSHQ("$0");
        }
    } 

    // Push local variables

    // TODO: 2.4 the function body can be sent to generate_statement()
    current_function = function;
    generate_statement(function->node->children[2]);

    // TODO: 2.3.2
    // Reset stack
    DIRECTIVE(".%s.epilogue:", function->name);
    EMIT("leave");
    RET;
}

// Generates code for a function call, which can either be a statement or an expression
static void generate_function_call(node_t* call) {
    // Push function parameters onto stack
    assert(call->n_children == 2);
    node_t* param_list = call->children[1];
    size_t num_params = param_list->n_children;

    // Go from right to left, 6 will be passed in registers, rest pushed on stack
    // Start by pushing the last N - 6 onto stack

    if (num_params > 0) {
        size_t i = num_params;
        for (; i-- > 0;) {
            node_t* ident = param_list->children[i];
            generate_expression(ident);
            PUSHQ(RAX);
        }

        // Pop parameters back into registers
        size_t num_to_pop = 0;
        if (num_params > 6)
            num_to_pop = 6;
        else
            num_to_pop = num_params;
        for (size_t i = 0; i < num_to_pop; i++) {
            POPQ(REGISTER_PARAMS[i]);
        }
    }


    // Call function
    node_t* func_ident = call->children[0];
    CALL(func_ident->symbol->name);
}

// Generates code to evaluate the expression, and place the result in %rax
static void generate_expression(node_t* expression) {
    // TODO: 2.4.1 Generate code for evaluating the given expression.
    // (The candidates are NUMBER_LITERAL, IDENTIFIER, ARRAY_INDEXING, OPERATOR and FUNCTION_CALL)
    switch(expression->type) {
        case NUMBER_LITERAL: {
            NUM_LITERAL(expression->data.number_literal, RAX);
            break;
        }
        case IDENTIFIER: {
            if (expression->symbol == NULL)
                break;

            if (expression->symbol->type == SYMBOL_GLOBAL_VAR) {
                LOAD_GLOBAL_VAR(expression->symbol->name, RAX);
            } else if (expression->symbol->type == SYMBOL_PARAMETER) {
                // Get stack offset for parameter
                size_t num_params = FUNC_PARAM_COUNT(current_function);
                int sym_table_index = expression->symbol->sequence_number;
            
                int stack_offset = 0;
                if (sym_table_index < 6) {
                    stack_offset = -8 * (sym_table_index + 1);
                } else {
                    // Have to positive relative to %rbp
                    stack_offset = 8 + 8 * (sym_table_index - 6 + 1);
                }
            
                // Load parameter
                LOAD_LOCAL_VAR(stack_offset, RAX);
            
            } else if (expression->symbol->type == SYMBOL_LOCAL_VAR) {
                // Get stack offset for local var
                size_t num_params = FUNC_PARAM_COUNT(current_function);
                size_t sym_table_index = expression->symbol->sequence_number;
                int stack_offset_idx = sym_table_index;
                if (num_params > 6) {
                    stack_offset_idx -= (num_params - 6);
                }
            
                int stack_offset = -8 * (stack_offset_idx + 1);
            
                // Load var
                LOAD_LOCAL_VAR(stack_offset, RAX);
            }
            break;
        }
        case ARRAY_INDEXING:
            assert(expression->n_children == 2);
            node_t* ident  = expression->children[0];
            node_t* offset = expression->children[1];

            assert(ident->symbol->type == SYMBOL_GLOBAL_ARRAY);

            // Load value from array at index
            generate_expression(offset);
            LEAQ(ident->symbol->name, RCX);
            LEAQ_O(RCX, RAX, RCX);
            MOVQ(MEM(RCX), RAX);

            break;
        case OPERATOR:
            if (expression->n_children == 1) {
                node_t* left = expression->children[0];
                generate_expression(left);

                if (strcmp(expression->data.operator, "-") == 0) {
                    NEGQ(RAX);
                } else if (strcmp(expression->data.operator, "!") == 0) {
                    EMIT("test %s, %s", RAX, RAX);
                    SETE(AL);
                    MOVZBQ(AL, RAX);
                }

            } else {
                node_t* left = expression->children[0];
                node_t* right = expression->children[1];

                // Handle LHS
                generate_expression(right);
                PUSHQ(RAX);
                generate_expression(left);
                POPQ(RCX);

                if (strcmp(expression->data.operator, "+") == 0) {
                    ADDQ(RCX, RAX);
                } else if (strcmp(expression->data.operator, "-") == 0) {
                    SUBQ(RCX, RAX);
                } else if (strcmp(expression->data.operator, "*") == 0) {
                    IMULQ(RCX, RAX);
                } else if (strcmp(expression->data.operator, "/") == 0) {
                    CQO;
                    IDIVQ(RCX);
                } else if (strcmp(expression->data.operator, "==") == 0) {
                    CMPQ(RAX, RCX);
                    SETE(AL);
                    MOVZBQ(AL, RAX);
                } else if (strcmp(expression->data.operator, "!=") == 0) {
                    CMPQ(RCX, RAX);
                    SETNE(AL);
                    MOVZBQ(AL, RAX);
                } else if (strcmp(expression->data.operator, "<") == 0) {
                    CMPQ(RCX, RAX);
                    SETL(AL);
                    MOVZBQ(AL, RAX);
                } else if (strcmp(expression->data.operator, "<=") == 0) {
                    CMPQ(RCX, RAX);
                    SETLE(AL);
                    MOVZBQ(AL, RAX);
                } else if (strcmp(expression->data.operator, ">") == 0) {
                    CMPQ(RCX, RAX);
                    SETG(AL);
                    MOVZBQ(AL, RAX);
                } else if (strcmp(expression->data.operator, ">=") == 0) {
                    CMPQ(RCX, RAX);
                    SETGE(AL);
                    MOVZBQ(AL, RAX);
                }
            }

            break;
        case FUNCTION_CALL:
            generate_function_call(expression);
            break;
        default:
            break;
    }
}

static void generate_assignment_statement(node_t* statement) {
    // TODO: 2.4.2
    // You can assign to both local variables, global variables and function parameters.
    // Use the IDENTIFIER's symbol to find out what kind of symbol you are assigning to.
    // The left hand side of an assignment statement may also be an ARRAY_INDEXING node.
    // In that case, you must also emit code for evaluating the index being stored to

    // LHS and RHS must be expressions (i think)
    assert (statement->n_children == 2);

    node_t* left  = statement->children[0];
    node_t* right = statement->children[1];

    // Generate LHS
    generate_expression(right); // must now be a num literal right?

    if (left->type == IDENTIFIER) {
        assert(left->symbol != NULL);
        if (left->symbol->type == SYMBOL_GLOBAL_VAR) {
            STORE_GLOBAL_VAR(RAX, left->symbol->name);
        } else if (left->symbol->type == SYMBOL_PARAMETER) {
            size_t num_params = FUNC_PARAM_COUNT(current_function);
            int sym_table_index = left->symbol->sequence_number;

            int stack_offset = 0;
            if (sym_table_index < 6) {
                stack_offset = -8 * (sym_table_index + 1);
            } else {
                // Have to positive relative to %rbp
                stack_offset = 8 + 8 * (sym_table_index - 6 + 1);
            }
        
            // Load parameter
            STORE_LOCAL_VAR(RAX, stack_offset);

        } else if (left->symbol->type == SYMBOL_LOCAL_VAR) {
            size_t num_params = FUNC_PARAM_COUNT(current_function);
            int sym_table_index = left->symbol->sequence_number;

            int stack_offset_idx = sym_table_index;
            if (num_params > 6) {
                stack_offset_idx -= (num_params - 6);
            }
        
            int stack_offset = -8 * (stack_offset_idx + 1);
        
            // Load var
            STORE_LOCAL_VAR(RAX, stack_offset);
        }
    } else if (left->type == ARRAY_INDEXING) {
        assert(left->children[0]->symbol->type == SYMBOL_GLOBAL_ARRAY);
        assert(left->n_children == 2);

        node_t* ident  = left->children[0];
        node_t* offset = left->children[1];

        assert(ident->symbol->type == SYMBOL_GLOBAL_ARRAY);

        // Store value in %rax to array
        PUSHQ(RAX); // Save RHS of assignment value
        generate_expression(offset);
        LEAQ(ident->symbol->name, RCX);
        LEAQ_O(RCX, RAX, RCX);
        POPQ(RAX);
        MOVQ(RAX, MEM(RCX));
    }
}

static void generate_print_statement(node_t* statement) {
    // TODO: 2.4.4
    // Remember to call safe_printf instead of printf

    // Loop over the list of statements to be printed and call safe_print
    node_t* printables_list = statement->children[0];
    for (size_t i = 0; i < printables_list->n_children; ++i) {
        node_t* ps = printables_list->children[i];

        if (ps->type == STRING_LIST_REFERENCE) {
            size_t str_list_idx = ps->data.string_list_index;
            EMIT("leaq string%ld(%rip), %rsi", str_list_idx);
            EMIT("leaq strout(%rip), %rdi");
            EMIT("call safe_printf");
        } else {
            generate_expression(ps);
            MOVQ(RAX, RSI);
            EMIT("leaq intout(%rip), %rdi");
            EMIT("call safe_printf");
        }
    }

    NUM_LITERAL('\n', RDI);
    EMIT("call putchar");
}

static void generate_return_statement(node_t* statement) {
    // TODO: 2.4.5 Evaluate the return value, store it in %rax and jump to the function epilogue
    assert(statement->n_children == 1);
    generate_expression(statement->children[0]);
    EMIT("jmp .%s.epilogue", current_function->name);
}

// Recursively generate the given statement node, and all sub-statements.
static void generate_statement(node_t* node) {
    if (node == NULL)
        return;

    // TODO: 2.4 Generate instructions for statements.
    // The candidates are BLOCK, ASSIGNMENT_STATEMENT, PRINT_STATEMENT, RETURN_STATEMENT,
    // FUNCTION_CALL
    switch (node->type) {
        case BLOCK:
            for (size_t i = 0; i < node->n_children; ++i) {
                generate_statement(node->children[i]);
            }
            break;
        case ASSIGNMENT_STATEMENT:
            generate_assignment_statement(node);
            break;
        case PRINT_STATEMENT:
            generate_print_statement(node);
            break;
        case RETURN_STATEMENT:
            generate_return_statement(node);
            break;
        case FUNCTION_CALL:
            generate_expression(node);
            break;
        case LIST:
            for (size_t i = 0; i < node->n_children; ++i) {
                generate_statement(node->children[i]);
            }
            break;
        default:
            generate_expression(node);
            break;
    }
}

static void generate_safe_printf(void) {
    LABEL("safe_printf");

    PUSHQ(RBP);
    MOVQ(RSP, RBP);
    // This is a bitmask that abuses how negative numbers work, to clear the last 4 bits
    // A stack pointer that is not 16-byte aligned, will be moved down to a 16-byte boundary
    ANDQ("$-16", RSP);
    EMIT("call printf");
    // Cleanup the stack back to how it was
    MOVQ(RBP, RSP);
    POPQ(RBP);
    RET;
}

// Generates the scaffolding for parsing integers from the command line, and passing them to the
// entry point of the VSL program. The VSL entry function is specified using the parameter "first".
static void generate_main(symbol_t* first) {
    // Make the globally available main function
    LABEL("main");

    // Save old base pointer, and set new base pointer
    PUSHQ(RBP);
    MOVQ(RSP, RBP);

    // Which registers argc and argv are passed in
    const char* argc = RDI;
    const char* argv = RSI;

    const size_t expected_args = FUNC_PARAM_COUNT(first);

    SUBQ("$1", argc); // argc counts the name of the binary, so subtract that
    EMIT("cmpq $%ld, %s", expected_args, argc);
    JNE("ABORT"); // If the provdied number of arguments is not equal, go to the abort label

    if (expected_args == 0)
        goto skip_args; // No need to parse argv

    // Now we emit a loop to parse all parameters, and push them to the stack,
    // in right-to-left order

    // First move the argv pointer to the vert rightmost parameter
    EMIT("addq $%ld, %s", expected_args * 8, argv);

    // We use rcx as a counter, starting at the number of arguments
    MOVQ(argc, RCX);
    LABEL("PARSE_ARGV"); // A loop to parse all parameters
    PUSHQ(argv);         // push registers to caller save them
    PUSHQ(RCX);

    // Now call strtol to parse the argument
    EMIT("movq (%s), %s", argv, RDI); // 1st argument, the char *
    MOVQ("$0", RSI);                  // 2nd argument, a null pointer
    MOVQ("$10", RDX);                 // 3rd argument, we want base 10
    EMIT("call strtol");

    // Restore caller saved registers
    POPQ(RCX);
    POPQ(argv);
    PUSHQ(RAX); // Store the parsed argument on the stack

    SUBQ("$8", argv);        // Point to the previous char*
    EMIT("loop PARSE_ARGV"); // Loop uses RCX as a counter automatically

    // Now, pop up to 6 arguments into registers instead of stack
    for (size_t i = 0; i < expected_args && i < NUM_REGISTER_PARAMS; i++)
        POPQ(REGISTER_PARAMS[i]);

skip_args:

    EMIT("call .%s", first->name);
    MOVQ(RAX, RDI);    // Move the return value of the function into RDI
    EMIT("call exit"); // Exit with the return value as exit code

    LABEL("ABORT"); // In case of incorrect number of arguments
    EMIT("leaq errout(%s), %s", RIP, RDI);
    EMIT("call puts"); // print the errout string
    MOVQ("$1", RDI);
    EMIT("call exit"); // Exit with return code 1

    generate_safe_printf();

    // Declares global symbols we use or emit, such as main, printf and putchar
    DIRECTIVE("%s", ASM_DECLARE_SYMBOLS);
}
