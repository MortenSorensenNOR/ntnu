#include "std_lib_facilities.h"

/*
Oppgave 1. C++ til Python

def isFibonacciNumber(n: int) -> bool:
    a: int = 0
    b: int = 1
    while (b < n):
        temp: int = b
        b += a
        a = temp

    return b == n
*/

int maxOfTwo(int a, int b) {
    if (a > b) {
        printf("A is greater than B\n");
        return a;
    }

    printf("B is greater than or equal ot A\n");
    return b;
}

int fibonacci(int n) {
    int a = 0;
    int b = 1;
    printf("Fibonacci numbers: \n");
    for (int x = 1; x < n + 1; x++) {
        printf("%d %d\n", x, b);
        int temp = b;
        b += a;
        a = temp;
    }   
    printf("----\n");
    return b;
}

int squareNumberSum(int n) {
    int totalSum = 0;
    for (int i = 1; i < n + 1; i++) {
        totalSum += i * i;
        printf("%d\n", i*i);
    }
    printf("%d\n", totalSum);
    return totalSum;
}

void triangleNumbersBelow(int n) {
    int acc = 1;
    int num = 2;
    printf("Triangle numbers below %d: \n", n);
    while (acc < n) {
        printf("%d\n", acc);
        acc += num;
        num++;
    }
    printf("\n");
}

bool isPrime(int n) {
    for (int j = 2; j < n; j++) {
        if (n % j == 0) {
            return false;
        }
    }
    return true;
}

void naivePrimeNumberSearch(int n) {
    for (int number = 2; number < n; number++) {
        if (isPrime(number)) {
            printf("%d is a prime\n", number);
        }
    }
}

void inputAndPrintNameAndAge() {
    string name;
    int age;
    printf("Skriv inn et navn: \n");
    std::cin >> name;
    printf("Skriv inn alderen til %s: \n", name.c_str());
    std::cin >> age;
    printf("%s er %d år gammel.\n", name.c_str(), age);
}

int main() {
    // a)
    printf("Oppgave a)\n");
    printf("%d\n", maxOfTwo(5, 6));

    // c)
    printf("Oppgave c)\n");
    printf("%d\n", fibonacci(5));

    // d)
    printf("Oppgave d)\n");
    squareNumberSum(5);

    // e)
    printf("Oppgave e)\n");
    triangleNumbersBelow(10);

    // f)
    printf("Oppgave f)\n");
    printf("%d\n", isPrime(5));

    // g)
    printf("Oppgave g)\n");
    naivePrimeNumberSearch(11);

    // h)
    printf("Oppgave h)\n");
    inputAndPrintNameAndAge();

    return 0;
}

