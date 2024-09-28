// Breakout game
#include <stdlib.h>
#include <stdio.h>

// Colors are defined in RGB565 format

/***************************************************************************************************
 * DON'T REMOVE THE VARIABLES BELOW THIS COMMENT                                                   *
 **************************************************************************************************/
unsigned long long __attribute__((used)) VGAaddress = 0xc8000000; // Memory storing pixels
unsigned int __attribute__((used)) red = 0x0000F0F0;
unsigned int __attribute__((used)) green = 0x00000F0F;
unsigned int __attribute__((used)) blue = 0x000000FF;
unsigned int __attribute__((used)) white = 0x0000FFFF;
unsigned int __attribute__((used)) black = 0x0;

const unsigned char n_cols = 16; // <- This variable might change depending on the size of the game. Supported value range: [1,18]

char *won = "You Won";       // DON'T TOUCH THIS - keep the string as is
char *lost = "You Lost";     // DON'T TOUCH THIS - keep the string as is
unsigned short height = 240; // DON'T TOUCH THIS - keep the value as is
unsigned short width = 320;  // DON'T TOUCH THIS - keep the value as is
unsigned int fb_size = 76800;
char font8x8[128][8];        // DON'T TOUCH THIS - this is a forward declaration
/**************************************************************************************************/

/***
 * TODO: Define your variables below this comment
 */

// Block colors 
unsigned int num_colors = 14;
unsigned int __attribute__((used)) colors[14] = {
    0x07FF,
    0xF81E,
    0xFBA0,
    0x07EB,
    0x005F,
    0x801F,
    0xF80B,
    0x97E0,
    0x8F99,
    0xCCFD,
    0x7EEA,
    0x543B,
    0xBB10,
    0x7772
};


unsigned int bar_x = 0;
unsigned int bar_y = 0;
unsigned int bar_width = 7;
unsigned int bar_height = 45;

// 360 degrees:
// 0/360: Up
// 45: Up-Right
// 90: Right
// 135: Down-Right
// 180: Down
// 225: Down-Left
// 270: Left
// 315: Up-Left
unsigned int ball_angle = 0;        
unsigned int ball_active = 0;
unsigned int ball_x = 0;
unsigned int ball_y = 0;
unsigned int ball_width = 7;
unsigned int ball_height = 7;

unsigned int block_spacing = 2;
unsigned int block_width = 0;
unsigned int block_height = 0;


/***
 * You might use and modify the struct/enum definitions below this comment
 */
typedef struct _block
{
    unsigned int destroyed;
    unsigned int deleted;
    unsigned int pos_x;
    unsigned int pos_y;
    unsigned int color;
} Block;

typedef enum _gameState
{
    Stopped = 0,
    Running = 1,
    Won = 2,
    Lost = 3,
    Exit = 4,
} GameState;
GameState currentState = Stopped;

Block* blocks;

/***
 * Here follow the C declarations for our assembly functions
 */

// TODO: Add a C declaration for the ClearScreen assembly procedure
void ClearScreen();
void SetPixel(unsigned int x_coord, unsigned int y_coord, unsigned int color);
void DrawBlock(unsigned int x, unsigned int y, unsigned int width, unsigned int height, unsigned int color);
void DrawBar(unsigned int y);
int ReadUart();
void WriteUart(char c);

/***
 * Now follow the assembly implementations
 */

asm("ClearScreen: \n\t"
    "    PUSH {LR} \n\t"
    "    PUSH {R4, R5} \n\t"
    "    LDR R5, =0\n\t"
    "    LDR R2, =0\n\t"
    "    _ClearScreen_loop:\n\t"
    "    LDR R4, =0\n\t"
    "    _ClearScreen_line:\n\t"
    // Fill screen with white
    "    MOV R0, R4\n\t"
    "    MOV R1, R5\n\t"
    "    LDR R2, =65535\n\t"
    "    BL SetPixel\n\t"
    "    ADD R4, R4, #1\n\t"
    "    CMP R4, #320\n\t"
    "    BLT _ClearScreen_line\n\t"
    "    ADD R5, R5, #1\n\t"
    "    CMP R5, #240\n\t"
    "    BLT _ClearScreen_loop\n\t"
    "    POP {R4,R5}\n\t"
    "    POP {LR} \n\t"
    "    BX LR");

// assumes R0 = x-coord, R1 = y-coord, R2 = colorvalue
asm("SetPixel: \n\t"
    "LDR R3, =VGAaddress \n\t"
    "LDR R3, [R3] \n\t"
    "LSL R1, R1, #10 \n\t"
    "LSL R0, R0, #1 \n\t"
    "ADD R1, R0 \n\t"
    "STRH R2, [R3,R1] \n\t"
    "BX LR");

// TODO: Implement the DrawBlock function in assembly. You need to accept 5 parameters, as outlined in the c declaration above (unsigned int x, unsigned int y, unsigned int width, unsigned int height, unsigned int color)
asm("DrawBlock: \n\t"
    "PUSH {R4, R5, R6, LR} \n\t"
    "ldr R4, [sp, #16] \n\t" // color

    // Loop over all pixels and draw the block
    "MOV R5, #0 \n\t"   // y

    "_DrawBlock_loop: \n\t"
    "MOV R6, #0 \n\t"   // x

    "_DrawBlock_line: \n\t"
    "PUSH {R0, R1, R2, R3} \n\t"
    "ADD R0, R6, R0 \n\t"
    "ADD R1, R5, R1 \n\t"
    "MOV R2, R4 \n\t"
    "BL SetPixel \n\t"
    "POP {R0, R1, R2, R3} \n\t"

    "ADD R6, R6, #1 \n\t"
    "CMP R6, R2 \n\t"
    "BLT _DrawBlock_line \n\t"

    "ADD R5, R5, #1 \n\t"
    "CMP R5, R3 \n\t"
    "BLT _DrawBlock_loop \n\t"

    "POP {R4, R5, R6, LR} \n\t"
    "BX LR");

// TODO: Impelement the DrawBar function in assembly. You need to accept the parameter as outlined in the c declaration above (unsigned int y)
asm("DrawBar: \n\t"
    "BX LR");

asm("ReadUart:\n\t"
    "LDR R1, =0xFF201000 \n\t"
    "LDR R0, [R1]\n\t"
    "BX LR");

// TODO: Add the WriteUart assembly procedure here that respects the WriteUart C declaration on line 46
asm("WriteUart: \n\t"
    "LDR R1, =0xFF201000 \n\t"
    "STR R0, [R1]\n\t"
    "BX LR");

// TODO: Implement the C functions below
void draw_ball() {
    DrawBlock(ball_x, ball_y, ball_width, ball_height, black);
}

void draw_playing_field()
{
    // Draw the blocks
    for (int i = 0; i < n_cols; i++)
    {
        for (int j = 0; j < n_cols; j++)
        {
            int index = i + j * n_cols;
            if (blocks[index].destroyed == 0)
            {
                DrawBlock(blocks[index].pos_x, blocks[index].pos_y, block_width, block_height, blocks[index].color);
            }
        }
    }
}

void update_game_state()
{
    if (currentState != Running)
    {
        return;
    }

    // TODO: Check: game won? game lost?
    if (ball_active == 1) {
        if (ball_x < 0) {
            currentState = Lost;
            return;
        } else if (ball_x > width) {
            currentState = Won;
            return;
        }
    }

    // TODO: Update balls position and direction
    if (ball_active) {
        switch (ball_angle) {
            case 0:
                ball_y -= 1;
                break;
            case 45:
                ball_x += 1;
                ball_y -= 1;
                break;
            case 90:
                ball_x += 1;
                break;
            case 135:
                ball_x += 1;
                ball_y += 1;
                break;
            case 180:
                ball_y += 1;
                break;
            case 225:
                ball_x -= 1;
                ball_y += 1;
                break;
            case 270:
                ball_x -= 1;
                break;
            case 315:
                ball_x -= 1;
                ball_y -= 1;
                break;
            case 360:
                ball_y -= 1;
                break;
        }
    }

    // Check hit with walls
    if (ball_active) {
        if (ball_y <= 0 || ball_y >= height - ball_height) {
            if (ball_angle == 0) {
                ball_angle = 180;
            } else if (ball_angle == 45) {
                ball_angle = 135;
            } else if (ball_angle == 135) {
                ball_angle = 45;
            } else if (ball_angle == 180) {
                ball_angle = 0;
            } else if (ball_angle == 225) {
                ball_angle = 315;
            } else if (ball_angle == 315) {
                ball_angle = 225;
            }
        }
    }

    // Check hit with bar
    if (ball_active) {
        // Check if ball hits the bar in x direction
        if (ball_x >= bar_x && ball_x <= bar_x + bar_width) {
            // Check hit with centermost 15 pixels
            if (ball_y >= bar_y + 15 && ball_y <= bar_y + bar_height - 15) {
                ball_angle = 90;
            }

            // Check hit with uppermost 15 pixels
            if (ball_y >= bar_y && ball_y <= bar_y + 15) {
                ball_angle = 45;
            }

            // Check hit with lowermost 15 pixels
            if (ball_y >= bar_y + bar_height - 15 && ball_y <= bar_y + bar_height) {
                ball_angle = 135;
            }
        }
    }

    // TODO: Hit Check with Blocks
    // HINT: try to only do this check when we potentially have a hit, as it is relatively expensive and can slow down game play a lot
    if (ball_active) {
        for (int i = 0; i < n_cols; i++)
        {
            for (int j = 0; j < n_cols; j++)
            {
                int index = i + j * n_cols;
                if (blocks[index].destroyed == 0)
                {
                    // Check if the ball hitting the block
                    // and from which direction it hits

                    // 1. Top center pixel hits a block, hit from below
                    if (ball_x >= blocks[index].pos_x && ball_x <= blocks[index].pos_x + block_width && ball_y == blocks[index].pos_y + block_height)
                    {
                        blocks[index].destroyed = 1;
                        if (ball_angle == 45)
                        {
                            ball_angle = 135;
                        } else if (ball_angle == 315)
                        {
                            ball_angle = 225;
                        }
                    }

                    // 2. Rightmost center pixel hits a block, hit from left
                    if (ball_y >= blocks[index].pos_y && ball_y <= blocks[index].pos_y + block_height && ball_x == blocks[index].pos_x - 1)
                    {
                        blocks[index].destroyed = 1;
                        if (ball_angle == 45)
                        {
                            ball_angle = 315;
                        } else if (ball_angle == 135)
                        {
                            ball_angle = 225;
                        } else {
                            ball_angle = 270;
                        }
                    }

                    // 3. Bottom center pixel hits a block, hit from above
                    if (ball_x >= blocks[index].pos_x && ball_x <= blocks[index].pos_x + block_width && ball_y == blocks[index].pos_y - 1)
                    {
                        blocks[index].destroyed = 1;
                        if (ball_angle == 135)
                        {
                            ball_angle = 45;
                        } else if (ball_angle == 225)
                        {
                            ball_angle = 315;
                        }
                    }

                    // 4. Leftmost center pixel hits a block, hit from right
                    if (ball_y >= blocks[index].pos_y && ball_y <= blocks[index].pos_y + block_height && ball_x == blocks[index].pos_x + block_width)
                    {
                        blocks[index].destroyed = 1;
                        if (ball_angle == 135)
                        {
                            ball_angle = 45;
                        } else if (ball_angle == 225)
                        {
                            ball_angle = 135;
                        }
                    }
                }
            }
        }
    }
}

void update_bar_state()
{
    int remaining = 0;
    // TODO: Read all chars in the UART Buffer and apply the respective bar position updates
    // HINT: w == 77, s == 73
    // HINT Format: 0x00 'Remaining Chars':2 'Ready 0x80':2 'Char 0xXX':2, sample: 0x00018077 (1 remaining character, buffer is ready, current character is 'w')

    do
    {
        unsigned long long out = ReadUart();
        if (!(out & 0x8000))
        {
            // not valid - abort reading
            return;
        }
        remaining = (out & 0xFF0000) >> 4;
        if (remaining >= 0)
        {
            char c = out & 0xFF;
            if (c == 0x77)
            {
                // Move bar up
                bar_y -= 15;
            }
            else if (c == 0x73)
            {
                // Move bar down
                bar_y += 15;
            }
        }
    } while (remaining > 0);
}

void write(char *str)
{
    // TODO: Use WriteUart to write the string to JTAG UART
    for (int i = 0; str[i] != '\0'; i++)
    {
        WriteUart(str[i]);
    }
}

void play()
{
    ClearScreen();
    // HINT: This is the main game loop
    while (1)
    {
        update_game_state();
        update_bar_state();
        if (currentState != Running)
        {
            break;
        }
        draw_playing_field();
        draw_ball();
        DrawBar(120); // TODO: replace the constant value with the current position of the bar
    }
    if (currentState == Won)
    {
        write(won);
    }
    else if (currentState == Lost)
    {
        write(lost);
    }
    else if (currentState == Exit)
    {
        return;
    }
    currentState = Stopped;
}

void reset()
{
    // Hint: This is draining the UART buffer
    int remaining = 0;
    do
    {
        unsigned long long out = ReadUart();
        if (!(out & 0x8000))
        {
            // not valid - abort reading
            return;
        }
        remaining = (out & 0xFF0000) >> 4;
    } while (remaining > 0);

    // TODO: You might want to reset other state in here
}

void wait_for_start()
{
    // TODO: Implement waiting behaviour until the user presses either w/s
    // ReadUart() until either w or s is pressed
    // w == 77, s == 73
    // if enter is pressed, set currentState to Exit

    unsigned long long out = ReadUart();
    if (!(out & 0x8000))
    {
        // not valid - abort reading
        return;
    }
    int c = out & 0xFF;
    if (c == 0x77)
    {
        currentState = Running;
        return;
    } else if (c == 0x73) {
        currentState = Running;
        return;
    }
    else if (c == 0x0a)
    {
        currentState = Exit;
        return;
    }
    currentState = Stopped;
}

int main(int argc, char *argv[])
{
    srand(42);
    currentState = Stopped;

    // Initialize the blocks
    blocks = (Block *)malloc(n_cols * n_cols * sizeof(Block));

    block_height = (height) / n_cols - block_spacing;
    block_width = block_height;

    unsigned int block_render_offset_x = width - (block_width) * n_cols + block_spacing/2;
    unsigned int block_render_offset_y = block_spacing/2;

    for (unsigned int i = 0; i < n_cols; i++)
    {
        for (unsigned int j = 0; j < n_cols; j++)
        {
            int index = i + j * n_cols;
            blocks[index].destroyed = 0;
            blocks[index].deleted = 0;
            blocks[index].pos_x = i * (block_width + block_spacing) + block_render_offset_x;
            blocks[index].pos_y = j * (block_height + block_spacing) + block_render_offset_y;

            int color_index = rand() % num_colors;
            blocks[index].color = colors[color_index];
        }
    }

    ClearScreen();

    // HINT: This loop allows the user to restart the game after loosing/winning the previous game
    while (1)
    {
        wait_for_start();
        if (currentState == Stopped) {
            continue;
        }
        ball_active = 1;

        play();
        reset();
        if (currentState == Exit)
        {
            break;
        }
    }
    return 0;
}

// THIS IS FOR THE OPTIONAL TASKS ONLY

// HINT: How to access the correct bitmask
// sample: to get character a's bitmask, use
// font8x8['a']
char font8x8[128][8] = {
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0000 (nul)
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0001
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0002
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0003
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0004
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0005
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0006
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0007
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0008
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0009
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000A
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000B
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000C
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000D
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000E
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+000F
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0010
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0011
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0012
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0013
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0014
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0015
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0016
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0017
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0018
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0019
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001A
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001B
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001C
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001D
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001E
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+001F
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0020 (space)
    {0x18, 0x3C, 0x3C, 0x18, 0x18, 0x00, 0x18, 0x00}, // U+0021 (!)
    {0x36, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0022 (")
    {0x36, 0x36, 0x7F, 0x36, 0x7F, 0x36, 0x36, 0x00}, // U+0023 (#)
    {0x0C, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x0C, 0x00}, // U+0024 ($)
    {0x00, 0x63, 0x33, 0x18, 0x0C, 0x66, 0x63, 0x00}, // U+0025 (%)
    {0x1C, 0x36, 0x1C, 0x6E, 0x3B, 0x33, 0x6E, 0x00}, // U+0026 (&)
    {0x06, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0027 (')
    {0x18, 0x0C, 0x06, 0x06, 0x06, 0x0C, 0x18, 0x00}, // U+0028 (()
    {0x06, 0x0C, 0x18, 0x18, 0x18, 0x0C, 0x06, 0x00}, // U+0029 ())
    {0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00}, // U+002A (*)
    {0x00, 0x0C, 0x0C, 0x3F, 0x0C, 0x0C, 0x00, 0x00}, // U+002B (+)
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x06}, // U+002C (,)
    {0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00}, // U+002D (-)
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x00}, // U+002E (.)
    {0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x01, 0x00}, // U+002F (/)
    {0x3E, 0x63, 0x73, 0x7B, 0x6F, 0x67, 0x3E, 0x00}, // U+0030 (0)
    {0x0C, 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x00}, // U+0031 (1)
    {0x1E, 0x33, 0x30, 0x1C, 0x06, 0x33, 0x3F, 0x00}, // U+0032 (2)
    {0x1E, 0x33, 0x30, 0x1C, 0x30, 0x33, 0x1E, 0x00}, // U+0033 (3)
    {0x38, 0x3C, 0x36, 0x33, 0x7F, 0x30, 0x78, 0x00}, // U+0034 (4)
    {0x3F, 0x03, 0x1F, 0x30, 0x30, 0x33, 0x1E, 0x00}, // U+0035 (5)
    {0x1C, 0x06, 0x03, 0x1F, 0x33, 0x33, 0x1E, 0x00}, // U+0036 (6)
    {0x3F, 0x33, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x00}, // U+0037 (7)
    {0x1E, 0x33, 0x33, 0x1E, 0x33, 0x33, 0x1E, 0x00}, // U+0038 (8)
    {0x1E, 0x33, 0x33, 0x3E, 0x30, 0x18, 0x0E, 0x00}, // U+0039 (9)
    {0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x00}, // U+003A (:)
    {0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x06}, // U+003B (;)
    {0x18, 0x0C, 0x06, 0x03, 0x06, 0x0C, 0x18, 0x00}, // U+003C (<)
    {0x00, 0x00, 0x3F, 0x00, 0x00, 0x3F, 0x00, 0x00}, // U+003D (=)
    {0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00}, // U+003E (>)
    {0x1E, 0x33, 0x30, 0x18, 0x0C, 0x00, 0x0C, 0x00}, // U+003F (?)
    {0x3E, 0x63, 0x7B, 0x7B, 0x7B, 0x03, 0x1E, 0x00}, // U+0040 (@)
    {0x0C, 0x1E, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x00}, // U+0041 (A)
    {0x3F, 0x66, 0x66, 0x3E, 0x66, 0x66, 0x3F, 0x00}, // U+0042 (B)
    {0x3C, 0x66, 0x03, 0x03, 0x03, 0x66, 0x3C, 0x00}, // U+0043 (C)
    {0x1F, 0x36, 0x66, 0x66, 0x66, 0x36, 0x1F, 0x00}, // U+0044 (D)
    {0x7F, 0x46, 0x16, 0x1E, 0x16, 0x46, 0x7F, 0x00}, // U+0045 (E)
    {0x7F, 0x46, 0x16, 0x1E, 0x16, 0x06, 0x0F, 0x00}, // U+0046 (F)
    {0x3C, 0x66, 0x03, 0x03, 0x73, 0x66, 0x7C, 0x00}, // U+0047 (G)
    {0x33, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x33, 0x00}, // U+0048 (H)
    {0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // U+0049 (I)
    {0x78, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E, 0x00}, // U+004A (J)
    {0x67, 0x66, 0x36, 0x1E, 0x36, 0x66, 0x67, 0x00}, // U+004B (K)
    {0x0F, 0x06, 0x06, 0x06, 0x46, 0x66, 0x7F, 0x00}, // U+004C (L)
    {0x63, 0x77, 0x7F, 0x7F, 0x6B, 0x63, 0x63, 0x00}, // U+004D (M)
    {0x63, 0x67, 0x6F, 0x7B, 0x73, 0x63, 0x63, 0x00}, // U+004E (N)
    {0x1C, 0x36, 0x63, 0x63, 0x63, 0x36, 0x1C, 0x00}, // U+004F (O)
    {0x3F, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x0F, 0x00}, // U+0050 (P)
    {0x1E, 0x33, 0x33, 0x33, 0x3B, 0x1E, 0x38, 0x00}, // U+0051 (Q)
    {0x3F, 0x66, 0x66, 0x3E, 0x36, 0x66, 0x67, 0x00}, // U+0052 (R)
    {0x1E, 0x33, 0x07, 0x0E, 0x38, 0x33, 0x1E, 0x00}, // U+0053 (S)
    {0x3F, 0x2D, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // U+0054 (T)
    {0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x3F, 0x00}, // U+0055 (U)
    {0x33, 0x33, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00}, // U+0056 (V)
    {0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00}, // U+0057 (W)
    {0x63, 0x63, 0x36, 0x1C, 0x1C, 0x36, 0x63, 0x00}, // U+0058 (X)
    {0x33, 0x33, 0x33, 0x1E, 0x0C, 0x0C, 0x1E, 0x00}, // U+0059 (Y)
    {0x7F, 0x63, 0x31, 0x18, 0x4C, 0x66, 0x7F, 0x00}, // U+005A (Z)
    {0x1E, 0x06, 0x06, 0x06, 0x06, 0x06, 0x1E, 0x00}, // U+005B ([)
    {0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x40, 0x00}, // U+005C (\)
    {0x1E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1E, 0x00}, // U+005D (])
    {0x08, 0x1C, 0x36, 0x63, 0x00, 0x00, 0x00, 0x00}, // U+005E (^)
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF}, // U+005F (_)
    {0x0C, 0x0C, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+0060 (`)
    {0x00, 0x00, 0x1E, 0x30, 0x3E, 0x33, 0x6E, 0x00}, // U+0061 (a)
    {0x07, 0x06, 0x06, 0x3E, 0x66, 0x66, 0x3B, 0x00}, // U+0062 (b)
    {0x00, 0x00, 0x1E, 0x33, 0x03, 0x33, 0x1E, 0x00}, // U+0063 (c)
    {0x38, 0x30, 0x30, 0x3e, 0x33, 0x33, 0x6E, 0x00}, // U+0064 (d)
    {0x00, 0x00, 0x1E, 0x33, 0x3f, 0x03, 0x1E, 0x00}, // U+0065 (e)
    {0x1C, 0x36, 0x06, 0x0f, 0x06, 0x06, 0x0F, 0x00}, // U+0066 (f)
    {0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x1F}, // U+0067 (g)
    {0x07, 0x06, 0x36, 0x6E, 0x66, 0x66, 0x67, 0x00}, // U+0068 (h)
    {0x0C, 0x00, 0x0E, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // U+0069 (i)
    {0x30, 0x00, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E}, // U+006A (j)
    {0x07, 0x06, 0x66, 0x36, 0x1E, 0x36, 0x67, 0x00}, // U+006B (k)
    {0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00}, // U+006C (l)
    {0x00, 0x00, 0x33, 0x7F, 0x7F, 0x6B, 0x63, 0x00}, // U+006D (m)
    {0x00, 0x00, 0x1F, 0x33, 0x33, 0x33, 0x33, 0x00}, // U+006E (n)
    {0x00, 0x00, 0x1E, 0x33, 0x33, 0x33, 0x1E, 0x00}, // U+006F (o)
    {0x00, 0x00, 0x3B, 0x66, 0x66, 0x3E, 0x06, 0x0F}, // U+0070 (p)
    {0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x78}, // U+0071 (q)
    {0x00, 0x00, 0x3B, 0x6E, 0x66, 0x06, 0x0F, 0x00}, // U+0072 (r)
    {0x00, 0x00, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x00}, // U+0073 (s)
    {0x08, 0x0C, 0x3E, 0x0C, 0x0C, 0x2C, 0x18, 0x00}, // U+0074 (t)
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x33, 0x6E, 0x00}, // U+0075 (u)
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00}, // U+0076 (v)
    {0x00, 0x00, 0x63, 0x6B, 0x7F, 0x7F, 0x36, 0x00}, // U+0077 (w)
    {0x00, 0x00, 0x63, 0x36, 0x1C, 0x36, 0x63, 0x00}, // U+0078 (x)
    {0x00, 0x00, 0x33, 0x33, 0x33, 0x3E, 0x30, 0x1F}, // U+0079 (y)
    {0x00, 0x00, 0x3F, 0x19, 0x0C, 0x26, 0x3F, 0x00}, // U+007A (z)
    {0x38, 0x0C, 0x0C, 0x07, 0x0C, 0x0C, 0x38, 0x00}, // U+007B ({)
    {0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00}, // U+007C (|)
    {0x07, 0x0C, 0x0C, 0x38, 0x0C, 0x0C, 0x07, 0x00}, // U+007D (})
    {0x6E, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // U+007E (~)
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}  // U+007F
};
