#ifndef OPPGAVE_2_CPP
#define OPPGAVE_2_CPP

#include "std_lib_facilities.h"

#include "oppgave1.cpp"

// ======== Oppgave 2 ========
void getSumOfMultipleNumbers() {
    int num;
    printf("Hvor mange tall ønsker du å summere?\n");
    std::cin >> num;
    
    int sol = 0;
    for (int i = 0; i < num; i++) {
        sol += inputInteger();
    }

    printf("Summen av tallene er: %d\n", sol);
}

void readNumsUntilZero() {
    int n = -1;
    int sol = 0;
    while (n != 0) {
        n = inputInteger();
        sol += n;
    }   

    printf("Summen av tallene er: %d\n", sol);
}

double inputDouble(string inputMsg = "Skriv inn et tall") {
    double num;
    printf("%s: ", inputMsg.c_str());
    std::cin >> num;
    return num;
}

void NOKtoEuro() {
    printf("Denne funksjonen konverterer fra NOK til Euro\n");
    double rate = 0; 
    while (rate <= 0) {
        rate = inputDouble("Vekslingskursen");
    }

    double nok = 0;
    while (nok <= 0) {
        nok = inputDouble("Antall NOK");
    }

    printf("%.2f NOK = %.2f Euro\n", nok, nok / rate);
}

void printGangeTabellen() {
    int width = inputInteger("Bredde på gangetabellen");
    int height = inputInteger("Høyde på gangetabellen");

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            printf("%d ", i * j);
        }
        printf("\n");
    }
}

#endif
