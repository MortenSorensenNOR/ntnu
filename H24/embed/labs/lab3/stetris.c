#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <sys/select.h>
#include <linux/input.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>
#include <poll.h>
#include <assert.h>

// Framebuffer stuff
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

// The game state can be used to detect what happens on the playfield
#define GAMEOVER 0
#define ACTIVE (1 << 0)
#define ROW_CLEAR (1 << 1)
#define TILE_ADDED (1 << 2)

typedef struct {
	int fb_fd;          // File descriptor for the SenseHat framebuffer
	char* fb_ptr;       // Pointer to the framebuffer
	long screensize;    // Screen size (bytes)
	unsigned int BPP;
	unsigned int LINE_LENGTH;

	int joy_fd;         // File descriptor for the SenseHat joystick
} SenseHat_t;

const size_t num_block_colors = 8;
const unsigned short block_colors[] = {
	0x07FF,
	0xFFE0,
	0xF81F,
	0x07E0,
	0xF800,
	0x001F,
	0xFDB0,
	0xF81F
};

typedef struct {
	unsigned short color;
	bool occupied;
} tile;

typedef struct {
	unsigned int x;
	unsigned int y;
} coord;

typedef struct {
	coord const grid;                    
	unsigned long const uSecTickTime;    
	unsigned long const rowsPerLevel;    
	unsigned long const initNextGameTick;

	unsigned int tiles;
	unsigned int rows; 
	unsigned int score;
	unsigned int level;

	tile *rawPlayfield;
	tile **playfield;
	unsigned int state;
	coord activeTile;

	unsigned long tick;         

	unsigned long nextGameTick; 

} gameConfig;

gameConfig game = {
	.grid = {8, 8},
	.uSecTickTime = 10000,
	.rowsPerLevel = 2,
	.initNextGameTick = 50,
};

bool initializeSenseHat(SenseHat_t* hat) {
	// Open framebuffer in read/write mode 
	hat->fb_fd = open("/dev/fb0", O_RDWR); 
	if (hat->fb_fd == -1) {
		perror("Error: Could not open framebuffer");
		return false;
	}

	// Get fixed screeninfo
	struct fb_fix_screeninfo finfo = {0};
	if (ioctl(hat->fb_fd, FBIOGET_FSCREENINFO, &finfo) == -1) {
		perror("Error: Could not get fixed screen info");
		close(hat->fb_fd);
		return false;
	}

	// Get variable screeninfo
	struct fb_var_screeninfo vinfo = {0};
	if (ioctl(hat->fb_fd, FBIOGET_VSCREENINFO, &vinfo) == -1) {
		perror("Error: Could not get variable screen info");
		close(hat->fb_fd);
		return false;
	}

	// Check that framebuffer name is correct
	const char *expected_id = "RPi-Sense FB";
	if (!(strncmp(finfo.id, expected_id, strlen(expected_id)) == 0)) {
		close(hat->fb_fd);
		printf("ID not correct. Expected: %s\t Got: %s\n", expected_id, finfo.id);
		return false;
	}

	hat->BPP = vinfo.bits_per_pixel / 8;
	hat->LINE_LENGTH = finfo.line_length;

	// Initialize joystick
	hat->joy_fd = open("/dev/input/event0", O_RDONLY);  // TODO: Make sure this is the correct one
	if (hat->joy_fd == -1) {
		perror("Error: Could not open joystick");
		close(hat->fb_fd);
		return false;
	} 

	// Create memory map
	hat->screensize = vinfo.yres_virtual * finfo.line_length;
	hat->fb_ptr = (char*)mmap(0, hat->screensize, PROT_READ | PROT_WRITE, MAP_SHARED, hat->fb_fd, 0);
	if (hat->fb_ptr == MAP_FAILED) {
		perror("Error: filed to map framebuffer device to memory");
		close(hat->fb_fd);
		return false;
	}

	return true;
}

void freeSenseHat(SenseHat_t* hat) {
	// Unmap SenseHat framebuffer
	if (munmap(hat->fb_ptr, hat->screensize) == -1) {
		perror("Error: failed to unmap framebuffer device from memory");
		close(hat->fb_fd);
		exit(1);
	}

	close(hat->fb_fd);
	close(hat->joy_fd);
}

// This function should return the key that corresponds to the joystick press
// KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, with the respective direction
// and KEY_ENTER, when the the joystick is pressed
// !!! when nothing was pressed you MUST return 0 !!!
int readSenseHatJoystick(SenseHat_t* hat) {
	struct input_event event;
	if (read(hat->joy_fd, &event, sizeof(struct input_event)) == -1) {
		perror("Could not read joystick event");
		return -1;
	}

	if (event.type == EV_KEY) {
		if (event.value != 0)
			return event.code;
	}

	return 0;
}

// This function should render the gamefield on the LED matrix. It is called
// every game tick. The parameter playfieldChanged signals whether the game logic
// has changed the playfield
void renderSenseHatMatrix(SenseHat_t* hat, bool const playfieldChanged) {
	if (playfieldChanged) {
		for (int y = 0; y < 8; y++) {
			for (int x = 0; x < 8; x++) {
				int fb_index = x * hat->BPP + y * hat->LINE_LENGTH;
				if (game.playfield[y][x].occupied) {
					*((unsigned int short*)(hat->fb_ptr + fb_index)) = game.playfield[y][x].color;
				} else {
					*((unsigned int short*)(hat->fb_ptr + fb_index)) = 0x0000;
				}
			}
		}
	}
}

static inline void newTile(coord const target) {
	game.playfield[target.y][target.x].occupied = true;

	int random_color_index = rand() % num_block_colors;
	game.playfield[target.y][target.x].color = block_colors[random_color_index];
}

static inline void copyTile(coord const to, coord const from) {
	memcpy((void *)&game.playfield[to.y][to.x], (void *)&game.playfield[from.y][from.x], sizeof(tile));
}

static inline void copyRow(unsigned int const to, unsigned int const from) {
	memcpy((void *)&game.playfield[to][0], (void *)&game.playfield[from][0], sizeof(tile) * game.grid.x);
}

static inline void resetTile(coord const target) {
	memset((void *)&game.playfield[target.y][target.x], 0, sizeof(tile));
}

static inline void resetRow(unsigned int const target) {
	memset((void *)&game.playfield[target][0], 0, sizeof(tile) * game.grid.x);
}

static inline bool tileOccupied(coord const target) {
	return game.playfield[target.y][target.x].occupied;
}

static inline bool rowOccupied(unsigned int const target) {
	for (unsigned int x = 0; x < game.grid.x; x++) {
		coord const checkTile = {x, target};
		if (!tileOccupied(checkTile)) {
			return false;
		}
	}
	return true;
}

static inline void resetPlayfield() {
	for (unsigned int y = 0; y < game.grid.y; y++) {
		resetRow(y);
	}
}

// GAME LOGIC BELOW: DO NOT TOUCH
bool addNewTile() {
	game.activeTile.y = 0;
	game.activeTile.x = (game.grid.x - 1) / 2;
	if (tileOccupied(game.activeTile))
		return false;
	newTile(game.activeTile);
	return true;
}

bool moveRight() {
	coord const newTile = {game.activeTile.x + 1, game.activeTile.y};
	if (game.activeTile.x < (game.grid.x - 1) && !tileOccupied(newTile)) {
		copyTile(newTile, game.activeTile);
		resetTile(game.activeTile);
		game.activeTile = newTile;
		return true;
	}
	return false;
}

bool moveLeft() {
	coord const newTile = {game.activeTile.x - 1, game.activeTile.y};
	if (game.activeTile.x > 0 && !tileOccupied(newTile)) {
		copyTile(newTile, game.activeTile);
		resetTile(game.activeTile);
		game.activeTile = newTile;
		return true;
	}
	return false;
}

bool moveDown() {
	coord const newTile = {game.activeTile.x, game.activeTile.y + 1};
	if (game.activeTile.y < (game.grid.y - 1) && !tileOccupied(newTile)) {
		copyTile(newTile, game.activeTile);
		resetTile(game.activeTile);
		game.activeTile = newTile;
		return true;
	}
	return false;
}

bool clearRow() {
	if (rowOccupied(game.grid.y - 1)) {
		for (unsigned int y = game.grid.y - 1; y > 0; y--) {
			copyRow(y, y - 1);
		}
		resetRow(0);
		return true;
	}
	return false;
}

void advanceLevel() {
	game.level++;
	switch (game.nextGameTick) {
		case 1:
			break;
		case 2 ... 10:
			game.nextGameTick--;
			break;
		case 11 ... 20:
			game.nextGameTick -= 2;
			break;
		default:
			game.nextGameTick -= 10;
	}
}

void newGame() {
	game.state = ACTIVE;
	game.tiles = 0;
	game.rows = 0;
	game.score = 0;
	game.tick = 0;
	game.level = 0;
	resetPlayfield();
}

void gameOver() {
	game.state = GAMEOVER;
	game.nextGameTick = game.initNextGameTick;
}

bool sTetris(int const key) {
	bool playfieldChanged = false;

	if (game.state & ACTIVE) {
		// Move the current tile
		if (key) {
			playfieldChanged = true;
			switch (key) {
				case KEY_LEFT:
					moveLeft();
					break;
				case KEY_RIGHT:
					moveRight();
					break;
				case KEY_DOWN:
					while (moveDown())
					{
					};
					game.tick = 0;
					break;
				default:
					playfieldChanged = false;
			}
		}

		// If we have reached a tick to update the game
		if (game.tick == 0) {
			// We communicate the row clear and tile add over the game state
			// clear these bits if they were set before
			game.state &= ~(ROW_CLEAR | TILE_ADDED);

			playfieldChanged = true;
			// Clear row if possible
			if (clearRow()) {
				game.state |= ROW_CLEAR;
				game.rows++;
				game.score += game.level + 1;
				if ((game.rows % game.rowsPerLevel) == 0) {
					advanceLevel();
				}
			}

			// if there is no current tile or we cannot move it down,
			// add a new one. If not possible, game over.
			if (!tileOccupied(game.activeTile) || !moveDown()) {
				if (addNewTile()) {
					game.state |= TILE_ADDED;
					game.tiles++;
				} else {
					gameOver();
				}
			}
		}
	}

	// Press any key to start a new game
	if ((game.state == GAMEOVER) && key) {
		playfieldChanged = true;
		newGame();
		addNewTile();
		game.state |= TILE_ADDED;
		game.tiles++;
	}

	return playfieldChanged;
}

int readKeyboard() {
	struct pollfd pollStdin = {
		.fd = STDIN_FILENO,
		.events = POLLIN
	};
	int lkey = 0;

	if (poll(&pollStdin, 1, 0)) {
		lkey = fgetc(stdin);
		if (lkey != 27)
			goto exit;
		lkey = fgetc(stdin);
		if (lkey != 91)
			goto exit;
		lkey = fgetc(stdin);
	}
exit:
	switch (lkey) {
		case 10:
			return KEY_ENTER;
		case 65:
			return KEY_UP;
		case 66:
			return KEY_DOWN;
		case 67:
			return KEY_RIGHT;
		case 68:
			return KEY_LEFT;
	}
	return 0;
}

void renderConsole(bool const playfieldChanged)
{
	if (!playfieldChanged)
		return;

	// Goto beginning of console
	fprintf(stdout, "\033[%d;%dH", 0, 0);
	for (unsigned int x = 0; x < game.grid.x + 2; x++) {
		fprintf(stdout, "-");
	}
	fprintf(stdout, "\n");
	for (unsigned int y = 0; y < game.grid.y; y++) {
		fprintf(stdout, "|");
		for (unsigned int x = 0; x < game.grid.x; x++) {
			coord const checkTile = {x, y};
			fprintf(stdout, "%c", (tileOccupied(checkTile)) ? '#' : ' ');
		}
		switch (y) {
			case 0:
				fprintf(stdout, "| Tiles: %10u\n", game.tiles);
				break;
			case 1:
				fprintf(stdout, "| Rows:  %10u\n", game.rows);
				break;
			case 2:
				fprintf(stdout, "| Score: %10u\n", game.score);
				break;
			case 4:
				fprintf(stdout, "| Level: %10u\n", game.level);
				break;
			case 7:
				fprintf(stdout, "| %17s\n", (game.state == GAMEOVER) ? "Game Over" : "");
				break;
			default:
				fprintf(stdout, "|\n");
		}
	}

	for (unsigned int x = 0; x < game.grid.x + 2; x++) {
		fprintf(stdout, "-");
	}
	fflush(stdout);
}

inline unsigned long uSecFromTimespec(struct timespec const ts) {
	return ((ts.tv_sec * 1000000) + (ts.tv_nsec / 1000));
}

int main(int argc, char **argv) {
	(void)argc;
	(void)argv;
	srand(time(NULL));

	{
		struct termios ttystate;
		tcgetattr(STDIN_FILENO, &ttystate);
		ttystate.c_lflag &= ~(ICANON | ECHO);
		ttystate.c_cc[VMIN] = 1;
		tcsetattr(STDIN_FILENO, TCSANOW, &ttystate);
	}

	game.rawPlayfield = (tile *)malloc(game.grid.x * game.grid.y * sizeof(tile));
	game.playfield = (tile **)malloc(game.grid.y * sizeof(tile *));
	if (!game.playfield || !game.rawPlayfield) {
		fprintf(stderr, "ERROR: could not allocate playfield\n");
		return 1;
	}

	for (unsigned int y = 0; y < game.grid.y; y++) {
		game.playfield[y] = &(game.rawPlayfield[y * game.grid.x]);
	}

	resetPlayfield();
	gameOver();

	SenseHat_t hat;
	if (!initializeSenseHat(&hat)) {
		fprintf(stderr, "ERROR: could not initilize sense hat\n");
		return 1;
	};

	fprintf(stdout, "\033[H\033[J");
	renderConsole(true);
	renderSenseHatMatrix(&hat, true);

	while (true) {
		struct timeval sTv, eTv;
		gettimeofday(&sTv, NULL);

		int key = readSenseHatJoystick(&hat);
		if (!key) {
			// Get input from console instead of sense hat
			// key = readKeyboard();
		}
		if (key == KEY_ENTER)
			break;

		bool playfieldChanged = sTetris(key);
		renderConsole(playfieldChanged);
		renderSenseHatMatrix(&hat, playfieldChanged);

		// Wait for next tick
		gettimeofday(&eTv, NULL);
		unsigned long const uSecProcessTime = ((eTv.tv_sec * 1000000) + eTv.tv_usec) - ((sTv.tv_sec * 1000000 + sTv.tv_usec));
		if (uSecProcessTime < game.uSecTickTime) {
			usleep(game.uSecTickTime - uSecProcessTime);
		}
		game.tick = (game.tick + 1) % game.nextGameTick;
	}

	freeSenseHat(&hat);
	free(game.playfield);
	free(game.rawPlayfield);

	return 0;
}

