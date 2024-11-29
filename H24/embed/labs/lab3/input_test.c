#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdio.h>

int main() {
	// Test of reading input from keyboard
	int fd = open("/dev/input/event0", O_RDONLY);
	if (fd == -1) {
		perror("open");
		return 1;
	}

	struct input_event ev;
	while (1) {
		if (read(fd, &ev, sizeof(struct input_event)) == -1) {
			perror("read");
			return 1;
		}
		if (ev.type == EV_KEY) {
			printf("key %d state %d\n", ev.code, ev.value);
		}
	}

}
