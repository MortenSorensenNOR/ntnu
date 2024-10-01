// This is a test to see if, when not burdened by the overhead of python loops
// if the hardware based algorithm can run faster than the software based one.

#include <stdlib.h>
#include <stdio.h>
#include <chrono>
#include <assert.h>

long long MonPro_Alg(long long a, long long b, long long n, long long n_prime, long long k) {
    long long r = (long long)1 << 32;
    long long t = a * b;
    long long m = (t * n_prime) % r;
    long long u = (t + m * n) >> k;
    if (u >= n) {
        return u - n;
    } else {
        return u;
    }
}

long long MonPro_Hardware(long long a, long long b, long long n, long long k) {
    long long u = 0;
    for (long long i = 0; i < k; i++) {
        u = u + ((a >> i) & 1) * b;
        if (u & 1) {
            u = u + n;
        }
        u = u >> 1;
    }
    return u;
}

int main() {
    long long x_bar = 1930;
    long long M_bar = 1990;
    long long n = 2117;
    long long n_prime = 1217279347;
    long long k = 32;

    // Time functions (in nano seconds)
    auto start = std::chrono::high_resolution_clock::now();
    long long alg = MonPro_Alg(x_bar, M_bar, n, n_prime, k);
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    printf("Software algorithm took %ld nanoseconds\n", duration.count());

    start = std::chrono::high_resolution_clock::now();
    long long hardware = MonPro_Hardware(x_bar, M_bar, n, k);
    end = std::chrono::high_resolution_clock::now();
    duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    printf("Hardware algorithm took %ld nanoseconds\n", duration.count());

    // Check that the two algorithms produce the same result
    assert(alg == hardware);

    return 0;
}
