
// The number of states in your table
#define NSTATES 14

// The starting state, at the beginning of each line
#define REAL_START 0
#define START 1

// The state to go to after a valid line
// All lines end with the newline character '\n'
#define ACCEPT 12

// The state to jump to as soon as a line is invalid
#define ERROR 13

int table[NSTATES][256];

void fillTable() {

    // Make all states lead to ERROR by default
    for (int i = 0; i < NSTATES; i++) {
        for (int c = 0; c < 256; c++) {
            table[i][c] = ERROR;
        }
    }

    // Skip whitespace
    table[START][' '] = START;

    // If we reach a newline, and are not in the middle of a statement, accept
    table[START]['\n'] = ACCEPT;

    // Accept the statement "go"
    table[START]['g'] = 1;
    table[1]['o'] = 2;
    table[2][' '] = START;
    table[2]['\n'] = ACCEPT;

    // Numbers and shit
    table[START]['d'] = 3; 
    table[3]['x'] = 4; 
    table[3]['y'] = 4; 
    table[4]['='] = 5;

    table[5]['-'] = 6;
    for (char x = '0'; x <= '9'; x++)
        table[5][x] = 6;

    for (char x = '0'; x <= '9'; x++)
        table[6][x] = 6;
    table[6]['\n'] = ACCEPT;
    table[6][' '] = START;


    for (char x = '0'; x <= '9'; x++)
        table[START][x] = 7;
    for (char x = '0'; x <= '9'; x++)
        table[7][x] = 7;
    table[7][':'] = 8;
    table[8]['\n'] = ACCEPT;
    table[8][' '] = START;

    table[START]['/'] = 9;
    table[9]['/'] = 10;
    for (int i = 0; i <= 255; i++)
        table[10][i] = 10;
    table[10]['\n'] = ACCEPT;
}
