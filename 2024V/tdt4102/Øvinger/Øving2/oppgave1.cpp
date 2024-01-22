#ifndef OPPGAVE_1_CPP
#define OPPGAVE_1_CPP

#include "std_lib_facilities.h"

// ======== Oppgave 1 ========
void inputAndPrintInteger() {
    int number;
    printf("Skriv inn et tall: ");
    std::cin >> number;
    printf("Du skrev: %d\n", number);
}

int inputInteger(string inputMsg = "Skriv inn et tall") {
    int num;
    printf("%s: ", inputMsg.c_str());
    std::cin >> num;
    return num;
}

void inputIntegersAndPrintSum() {
    int a = inputInteger();
    int b = inputInteger();
    printf("Summen av tallene: %d\n", a + b);
}

bool isOdd(int n) {
    if (n % 2 == 0)
        return false;
    return true;
}

#endif
