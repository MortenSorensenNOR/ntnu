/*
adc_sampler.c
Public Domain
January 2018, Kristoffer Kjærnes & Asgeir Bjørgan
Based on example code from the pigpio library by Joan @ raspi forum and github
https://github.com/joan2937 | http://abyz.me.uk/rpi/pigpio/

Compile with:
gcc -Wall -lpthread -o adc_sampler adc_sampler.c -lpigpio -lm

Run with:
sudo ./adc_sampler <num_samples> [hostname port]

Examples:
  sudo ./adc_sampler 31250                          # Save to file (original behavior)
  sudo ./adc_sampler 31250 desktop.local 12345      # Stream over TCP
  sudo ./adc_sampler 0 desktop.local 12345          # Stream indefinitely

This code bit bangs SPI on several devices using DMA.

Using DMA to bit bang allows for two advantages
1) the time of the SPI transaction can be guaranteed to within a
   microsecond or so.

2) multiple devices of the same type can be read or written
   simultaneously.

This code reads several MCP3201 ADCs in parallel, and writes the data to a binary file.
Each MCP3201 shares the SPI clock and slave select lines but has
a unique MISO line. The MOSI line is not in use, since the MCP3201 is single
channel ADC without need for any input to initiate sampling.
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <signal.h>
#include <limits.h>

#include <pigpio.h>
#include <math.h>
#include <time.h>

/////// USER SHOULD MAKE SURE THESE DEFINES CORRESPOND TO THEIR SETUP ///////
#define ADCS 3      // Number of connected MCP3201.

#define OUTPUT_DATA argv[2] // path and filename to dump buffered ADC data

/* RPi PIN ASSIGNMENTS */
#define MISO1 18    // ADC 1 MISO (GPIO pin number)
#define MISO2 21    // ADC 2 MISO (GPIO pin number)
#define MISO3 22    // ADC 3 MISO (GPIO pin number)

#define MOSI   10   // GPIO for SPI MOSI (GPIO 10 aka SPI_MOSI). MOSI not in use here due to single ch. ADCs, but must be defined anyway.
#define SPI_SS 20   // GPIO for slave select (GPIO 15).
#define CLK    19   // GPIO for SPI clock (GPIO 16).
/* END RPi PIN ASSIGNMENTS */

#define BITS 12            // Bits per sample.
#define BX 4               // Bit position of data bit B11. (3 first are t_sample + null bit)
#define B0 (BX + BITS - 1) // Bit position of data bit B0.

#define NUM_SAMPLES_IN_BUFFER 300 // Generally make this buffer as large as possible in order to cope with reschedule.

#define REPEAT_MICROS 32 // Reading every x microseconds. Must be no less than 2xB0 defined above

#define DEFAULT_NUM_SAMPLES 31250 // Default number of samples for printing in the example. Should give 1sec of data at Tp=32us.

// TCP streaming settings
#define STREAM_CHUNK_SIZE 256  // Send every N samples

int MISO[ADCS] = {MISO1, MISO2, MISO3}; // Must be updated if you change number of ADCs/MISOs above

// Global for signal handler
volatile int keep_running = 1;

void sig_handler(int sig) {
    (void)sig;
    keep_running = 0;
}

/////// END USER SHOULD MAKE SURE THESE DEFINES CORRESPOND TO THEIR SETUP ///////

/**
 * This function extracts the MISO bits for each ADC and
 * collates them into a reading per ADC.
 *
 * \param adcs Number of attached ADCs
 * \param MISO The GPIO connected to the ADCs data out
 * \param bytes Bytes between readings
 * \param bits Bits per reading
 * \param buf Output buffer
*/
void getReading(int adcs, int *MISO, int OOL, int bytes, int bits, char *buf)
{
   int p = OOL;
   int i, a;

   for (i = 0; i < bits; i++) {
      uint32_t level = rawWaveGetOut(p);
      for (a = 0; a < adcs; a++) {
         putBitInBytes(i, buf + (bytes * a), level & (1 << MISO[a]));
      }
      p--;
   }
}

/**
 * Connect to a remote host via TCP
 */
int connect_to_host(const char *hostname, int port) {
    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    char port_str[6];
    snprintf(port_str, sizeof(port_str), "%d", port);

    int err = getaddrinfo(hostname, port_str, &hints, &res);
    if (err != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(err));
        return -1;
    }

    int sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sock < 0) {
        perror("socket");
        freeaddrinfo(res);
        return -1;
    }

    printf("# Connecting to %s:%d...\n", hostname, port);
    if (connect(sock, res->ai_addr, res->ai_addrlen) < 0) {
        perror("connect");
        close(sock);
        freeaddrinfo(res);
        return -1;
    }

    printf("# Connected!\n");
    freeaddrinfo(res);
    return sock;
}

/**
 * Send all data over socket (handles partial sends)
 */
int send_all(int sock, const void *buf, size_t len) {
    const char *p = buf;
    while (len > 0) {
        ssize_t sent = send(sock, p, len, 0);
        if (sent <= 0) {
            return -1;
        }
        p += sent;
        len -= sent;
    }
    return 0;
}


int main(int argc, char *argv[])
{
    // Parse command line arguments
    long num_samples = 0;
    int streaming = 0;
    int sock = -1;
    char *hostname = NULL;
    int port = 0;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s NUM_SAMPLES [hostname port]\n\n"
                        "Examples:\n"
                        "  %s %d                        # Save to file\n"
                        "  %s %d desktop.local 12345   # Stream over TCP\n"
                        "  %s 0 desktop.local 12345    # Stream indefinitely (Ctrl+C to stop)\n",
                        argv[0], argv[0], DEFAULT_NUM_SAMPLES,
                        argv[0], DEFAULT_NUM_SAMPLES, argv[0]);
        exit(1);
    }

    sscanf(argv[1], "%ld", &num_samples);

    // Check for streaming mode
    if (argc >= 4) {
        streaming = 1;
        hostname = argv[2];
        port = atoi(argv[3]);
    }

    // For indefinite streaming, set a large number but use keep_running flag
    int indefinite = (num_samples == 0 && streaming);
    if (indefinite) {
        num_samples = LONG_MAX;
        signal(SIGINT, sig_handler);
        signal(SIGTERM, sig_handler);
        printf("# Indefinite streaming mode (Ctrl+C to stop)\n");
    }

    // Array over sampled values
    uint16_t *val = NULL;
    if (!streaming) {
        val = (uint16_t*)malloc(sizeof(uint16_t) * num_samples * ADCS);
        if (!val) {
            fprintf(stderr, "Failed to allocate sample buffer\n");
            return 1;
        }
    }

    // Streaming buffer
    uint16_t stream_buf[STREAM_CHUNK_SIZE * ADCS];
    int stream_buf_idx = 0;

    // Connect if streaming
    if (streaming) {
        sock = connect_to_host(hostname, port);
        if (sock < 0) {
            fprintf(stderr, "Failed to connect to %s:%d\n", hostname, port);
            return 1;
        }

        // Send header: sample period (will be sent after we know actual timing)
        // For now, send expected period
        double expected_period_us = REPEAT_MICROS;
        if (send_all(sock, &expected_period_us, sizeof(double)) < 0) {
            perror("send header");
            close(sock);
            return 1;
        }
    }

    // SPI transfer settings, time resolution 1us (1MHz system clock is used)
    rawSPI_t rawSPI =
    {
       .clk     =  CLK,  // Defined before
       .mosi    =  MOSI, // Defined before
       .ss_pol  =  1,   // Slave select resting level.
       .ss_us   =  1,   // Wait 1 micro after asserting slave select.
       .clk_pol =  0,   // Clock resting level.
       .clk_pha =  0,   // 0 sample on first edge, 1 sample on second edge.
       .clk_us  =  1,   // 2 clocks needed per bit so 500 kbps.
    };

    // Change timer to use PWM clock instead of PCM clock.
    gpioCfgClock(5, 0, 0);

    // Initialize the pigpio library
    if (gpioInitialise() < 0) {
       return 1;
    }

    // Set the selected CLK, MOSI and SPI_SS pins as output pins
    gpioSetMode(rawSPI.clk,  PI_OUTPUT);
    gpioSetMode(rawSPI.mosi, PI_OUTPUT);
    gpioSetMode(SPI_SS,      PI_OUTPUT);

    // Flush any old unused wave data.
    gpioWaveAddNew();

    // Construct bit-banged SPI reads.
    int offset = 0;
    int i;
    char buf[2];
    for (i = 0; i < NUM_SAMPLES_IN_BUFFER; i++) {
        buf[0] = 0xC0; // Start bit, single ended, channel 0.

        rawWaveAddSPI(&rawSPI, offset, SPI_SS, buf, 2, BX, B0, B0);
        offset += REPEAT_MICROS;
    }

    // Force the same delay after the last command in the buffer
    gpioPulse_t final[2];
    final[0].gpioOn = 0;
    final[0].gpioOff = 0;
    final[0].usDelay = offset;

    final[1].gpioOn = 0;
    final[1].gpioOff = 0;
    final[1].usDelay = 0;

    gpioWaveAddGeneric(2, final);

    // Construct the wave from added data.
    int wid = gpioWaveCreate();
    if (wid < 0) {
        fprintf(stderr, "Can't create wave, buffer size %d too large?\n", NUM_SAMPLES_IN_BUFFER);
        return 1;
    }

    // Obtain addresses for the top and bottom control blocks (CB)
    rawWaveInfo_t rwi = rawWaveInfo(wid);
    int botCB = rwi.botCB;
    int topOOL = rwi.topOOL;
    float cbs_per_reading = (float)rwi.numCB / (float)NUM_SAMPLES_IN_BUFFER;

    float expected_sample_freq_khz = 1000.0 / (1.0 * REPEAT_MICROS);

    printf("# Starting sampling: %ld samples (expected Tp = %d us, expected Fs = %.3f kHz).\n",
           indefinite ? -1L : num_samples, REPEAT_MICROS, expected_sample_freq_khz);

    // Start DMA engine and start sending ADC reading commands
    gpioWaveTxSend(wid, PI_WAVE_MODE_REPEAT);

    // Read back the samples
    double start_time = time_time();
    int reading = 0;
    long sample = 0;

    while (sample < num_samples && keep_running) {
        // Get position along DMA control block buffer
        int cb = rawWaveCB() - botCB;
        int now_reading = (float) cb / cbs_per_reading;

        while ((now_reading != reading) && (sample < num_samples) && keep_running) {
            int reading_address = topOOL - ((reading % NUM_SAMPLES_IN_BUFFER) * BITS) - 1;

            char rx[8];
            getReading(ADCS, MISO, reading_address, 2, BITS, rx);

            if (streaming) {
                // Add to stream buffer
                for (i = 0; i < ADCS; i++) {
                    stream_buf[stream_buf_idx * ADCS + i] = (rx[i * 2] << 4) + (rx[(i * 2) + 1] >> 4);
                }
                stream_buf_idx++;

                // Send when buffer full
                if (stream_buf_idx >= STREAM_CHUNK_SIZE) {
                    if (send_all(sock, stream_buf, sizeof(stream_buf)) < 0) {
                        fprintf(stderr, "# Connection lost\n");
                        keep_running = 0;
                        break;
                    }
                    stream_buf_idx = 0;
                }
            } else {
                // Store in memory (original behavior)
                for (i = 0; i < ADCS; i++) {
                    val[sample * ADCS + i] = (rx[i * 2] << 4) + (rx[(i * 2) + 1] >> 4);
                }
            }

            ++sample;

            if (++reading >= NUM_SAMPLES_IN_BUFFER) {
                reading = 0;
            }
        }
        usleep(1000);
    }

    double end_time = time_time();

    // Send any remaining data in stream buffer
    if (streaming && stream_buf_idx > 0) {
        send_all(sock, stream_buf, stream_buf_idx * ADCS * sizeof(uint16_t));
    }

    double nominal_period_us = 1.0 * (end_time - start_time) / (1.0 * sample) * 1.0e06;
    double nominal_sample_freq_khz = 1000.0 / nominal_period_us;

    printf("\n# %ld samples in %.6f seconds (actual T_p = %f us, nominal Fs = %.2f kHz).\n",
        sample, end_time - start_time, nominal_period_us, nominal_sample_freq_khz);

    if (streaming) {
        close(sock);
        printf("# Stream ended.\n");
    } else {
        // File output (original behavior)
        double output_nominal_period_us = floor(nominal_period_us);

        const char *output_filename;
        char hold_fname[32];
        if (argc < 3) {
            time_t t = time(NULL);
            struct tm tm = *localtime(&t);
            snprintf(hold_fname, 32, "./out-%4d-%02d-%02d-%02d.%02d.%02d.bin",
                     tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
                     tm.tm_hour, tm.tm_min, tm.tm_sec);
            output_filename = hold_fname;
        } else {
            output_filename = OUTPUT_DATA;
        }

        FILE *adc_data_file = fopen(output_filename, "wb+");
        if (adc_data_file == NULL) {
            fprintf(stderr, "# Couldn't open file for writing: %s\n", output_filename);
            gpioTerminate();
            free(val);
            return 1;
        }

        fwrite(&output_nominal_period_us, sizeof(double), 1, adc_data_file);
        fwrite(val, sizeof(uint16_t), ADCS * sample, adc_data_file);
        fclose(adc_data_file);
        printf("# Data written to file. Program ended successfully.\n\n");
    }

    gpioTerminate();
    if (val) free(val);

    return 0;
}
