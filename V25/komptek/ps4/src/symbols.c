#include <vslc.h>

// Declaration of global symbol table
symbol_table_t* global_symbols;

// Declarations of helper functions defined further down in this file
static void find_globals(void);
static void bind_names(symbol_table_t* local_symbols, node_t* root);
static void print_symbol_table(symbol_table_t* table, int nesting);
static void destroy_symbol_tables(void);

static size_t add_string(char* string);
static void print_string_list(void);
static void destroy_string_list(void);

/* External interface */

// Creates a global symbol table, and local symbol tables for each function.
// All usages of symbols are bound to their symbol table entries.
// All strings are entered into the string_list
void create_tables(void)
{
    find_globals();

    for (size_t i = 0; i < global_symbols->n_symbols; i++) {
        symbol_t* symbol = global_symbols->symbols[i];
        if (symbol->type == SYMBOL_FUNCTION) {
            node_t* function_body = symbol->node->children[2];
            bind_names(symbol->function_symtable, function_body);
        }
    }
}

// Prints the global symbol table, and the local symbol tables for each function.
// Also prints the global string list.
// Finally prints out the AST again, with bound symbols.
void print_tables(void)
{
    print_symbol_table(global_symbols, 0);
    printf("\n == STRING LIST == \n");
    print_string_list();
    printf("\n == BOUND SYNTAX TREE == \n");
    print_syntax_tree();
}

// Cleans up all memory owned by symbol tables and the global string list
void destroy_tables(void)
{
    destroy_symbol_tables();
    destroy_string_list();
}

/* Internal matters */

// Goes through all global declarations, adding them to the global symbol table.
// When adding functions, a local symbol table with symbols for its parameters are created.
static void find_globals(void)
{
    global_symbols = symbol_table_init();

    // Find global declarations and functions
    for (size_t i = 0; i < root->n_children; i++) {
        node_t* n = root->children[i];
        if (n->type == GLOBAL_DECLARATION) {
            for (size_t j = 0; j < n->n_children; j++) {
                node_t* var_list = n->children[j];

                for (size_t v = 0; v < var_list->n_children; v++) {
                    node_t* var = var_list->children[v];

                    symbol_t* symbol = malloc(sizeof(symbol_t));
                    if (var->type == IDENTIFIER) {
                        symbol->type = SYMBOL_GLOBAL_VAR;
                        symbol->name = var->data.identifier;
                        symbol->node = var;
                    } else if (var->type == ARRAY_INDEXING) {
                        symbol->type = SYMBOL_GLOBAL_ARRAY;
                        symbol->name = var->children[0]->data.identifier;
                        symbol->node = var;
                    }

                    if (symbol_table_insert(global_symbols, symbol) == INSERT_COLLISION) {
                        fprintf(stderr, "Symbol %s already exists in global symbol table\n", symbol->name);
                    }
                }
            }
        } else if (n->type == FUNCTION) {
            symbol_t* symbol = malloc(sizeof(symbol_t));
            symbol->type = SYMBOL_FUNCTION;
            symbol->name = n->children[0]->data.identifier;
            symbol->node = n;
            symbol->function_symtable = symbol_table_init();
            symbol->function_symtable->hashmap->backup = global_symbols->hashmap;

            if (symbol_table_insert(global_symbols, symbol) == INSERT_COLLISION) {
                fprintf(stderr, "Symbol %s already exists in global symbol table\n", symbol->name);
            }
            
            // Add parameters to the function's local symbol table
            assert (n->n_children >= 2);
            node_t* params = n->children[1];
            for (size_t p = 0; p < params->n_children; p++) {
                node_t* param = params->children[p];

                symbol_t* param_sym = (symbol_t*)malloc(sizeof(symbol_t));
                param_sym->type = SYMBOL_PARAMETER;
                if (param->type == IDENTIFIER) {
                    param_sym->name = param->data.identifier;
                } else if (param->type == ARRAY_INDEXING) {
                    param_sym->name = param->children[0]->data.identifier;
                }
                param_sym->node = param;

                if (symbol_table_insert(symbol->function_symtable, param_sym) == INSERT_COLLISION) {
                    fprintf(stderr, "Symbol %s already exists in function symbol table\n", param_sym->name);
                }
            }
        }
    }
}

// A recursive function that traverses the body of a function, and:
//  - Adds variable declarations to the function's local symbol table.
//  - Pushes and pops local variable scopes when entering and leaving blocks.
//  - Binds all IDENTIFIER nodes that are not declarations, to the symbol it references.
//  - Moves STRING_LITERAL nodes' data into the global string list,
//    and replaces the node with a STRING_LIST_REFERENCE node.
//    Overwrites the node's data.string_list_index field with with string list index
static void bind_names(symbol_table_t* local_symbols, node_t* node)
{
    if (node == NULL)
        return;

    // Perserve original hashmap
    symbol_hashmap_t* local_symbols_hashmap = local_symbols->hashmap;
    bool starts_with_variables = false;

    if (node->type == BLOCK) {
        assert(node->n_children > 0);

        // Create new hashmap for new block
        local_symbols->hashmap = symbol_hashmap_init();
        local_symbols->hashmap->backup = local_symbols_hashmap;

        // We may only have variable declarations in the beginning of a block
        if (node->children[0]->type == LIST && node->children[0]->children[0]->type == LIST && 
            node->children[0]->children[0]->children[0]->type == IDENTIFIER) {
            // We have struck variables
            starts_with_variables = true;

            node_t* list_of_var_decl = node->children[0];
            for (size_t i = 0; i < list_of_var_decl->n_children; i++) {
                node_t* var_decls = list_of_var_decl->children[i];

                // Multiple variables may declared together, i.e.: var a, b
                for (size_t v = 0; v < var_decls->n_children; v++) {
                    node_t* var = var_decls->children[v];

                    symbol_t* sym = (symbol_t*)malloc(sizeof(symbol_t));
                    sym->type = SYMBOL_LOCAL_VAR;
                    sym->name = var->data.identifier;   // Apparently, having ARRAY_INDEXING thing inside block is illegal
                    sym->node = var;

                    if (symbol_table_insert(local_symbols, sym) == INSERT_COLLISION) {
                        fprintf(stderr, "Symbol %s already exists in symbol table\n", sym->name);
                    }
                }
            }
        }

    } else if (node->type == IDENTIFIER) {
        symbol_t* sym = symbol_hashmap_lookup(local_symbols->hashmap, node->data.identifier);
        if (sym == NULL) {
            fprintf(stderr, "Unkown identifier %s used. Exiting\n", node->data.identifier);
        }

        node->symbol = sym;
    } else if (node->type == STRING_LITERAL) {
        char* string = node->data.string_literal;
        size_t string_table_idx = add_string(string);

        // Modify node 
        node->type = STRING_LIST_REFERENCE;
        node->data.string_list_index = string_table_idx;
    }

    // Loop over all other nodes
    int i = starts_with_variables ? 1 : 0;
    for (; i < node->n_children; i++) {
        node_t* child = node->children[i];
        bind_names(local_symbols, child);
    }

    // Reverse to local_symbols scope's hashmap
    if (node->type == BLOCK) {
        symbol_hashmap_destroy(local_symbols->hashmap);
        local_symbols->hashmap = local_symbols_hashmap;
    }

    // Tip: Strings can be added to the string list using add_string(). It returns its index.

    // Note: If an IDENTIFIER has a name that does not correspond to any symbol in the current scope,
    // a parent scope, or in the global symbol table, that is an error.
    // Feel free to print a nice error message and abort.
    // We will not test your compiler on incorrect VSL.
}

// Prints the given symbol table, with sequence number, symbol names and types.
// When printing function symbols, its local symbol table is recursively printed, with indentation.
static void print_symbol_table(symbol_table_t* table, int nesting)
{
    for (size_t i = 0; i < table->n_symbols; i++)
    {
        symbol_t* symbol = table->symbols[i];

        printf(
                "%*s%ld: %s(%s)\n",
                nesting * 4,
                "",
                symbol->sequence_number,
                SYMBOL_TYPE_NAMES[symbol->type],
                symbol->name);

        // If the symbol is a function, print its local symbol table as well
        if (symbol->type == SYMBOL_FUNCTION)
            print_symbol_table(symbol->function_symtable, nesting + 1);
    }
}

// Frees up the memory used by the global symbol table, all local symbol tables, and their symbols
static void destroy_symbol_tables(void)
{
    // TODO: Implement cleanup. All symbols in the program are owned by exactly one symbol table.

    // TIP: Using symbol_table_destroy() goes a long way, but it only cleans up the given table.
    // Try cleaning up all local symbol tables before cleaning up the global one.

    for (size_t i = 0; i < global_symbols->n_symbols; i++) {
        symbol_t* s = global_symbols->symbols[i];

        // Free local symbol tables
        if (s->type == SYMBOL_FUNCTION) {
            symbol_table_destroy(s->function_symtable);
        }
    }
    symbol_table_destroy(global_symbols);
}

// Declaration of global string list
char** string_list;
size_t string_list_len;
static size_t string_list_capacity;

// Adds the given string to the global string list, resizing if needed.
// Takes ownership of the string, and returns its position in the string list.
static size_t add_string(char* string)
{
    // TODO: Write a helper function you can use during bind_names(),
    // to easily add a string into the dynamically growing string_list.

    // The length of the string list should be stored in string_list_len.

    // The variable string_list_capacity should contain the maximum number of char*
    // that can fit in the current string_list before we need to allocate a larger array.
    // If length is about to surpass capacity, create a larger allocation first.
    // Tip: See the realloc function from the standard library

    // Return the position the added string gets in the list.

    if (string_list_len + 1 >= string_list_capacity) {
        string_list_capacity = string_list_capacity * 2 + 8;    // Don't know if this is quite right
        string_list = realloc(string_list, string_list_capacity * sizeof(char*));
    }

    string_list[string_list_len] = string;
    string_list_len++;

    return string_list_len - 1;
}

// Prints all strings added to the global string list
static void print_string_list(void)
{
    for (size_t i = 0; i < string_list_len; i++)
        printf("%ld: %s\n", i, string_list[i]);
}

// Frees all strings in the global string list, and the string list itself
static void destroy_string_list(void)
{
    // TODO: Called during cleanup, free strings, and the memory used by the string list itself
    for (size_t i = 0; i < string_list_len; i++) {
        free(string_list[i]);
    }
    free(string_list);
}
