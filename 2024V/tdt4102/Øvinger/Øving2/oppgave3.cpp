#ifndef OPPGAVE_3_CPP
#define OPPGAVE_3_CPP

#include "std_lib_facilities.h"

#include "oppgave1.cpp"
#include "oppgave2.cpp"

// ======== Oppgave 3 ========
double discriminant(double a, double b, double c) {
    return std::pow(b, 2) - 4 * a * c;
}

void printRealRoots(double a, double b, double c) {
    double disc = discriminant(a, b, c);
    if (disc > 0) {
        // Two solutions
        printf("Løsningene er x = %.2f og x = %.2f\n", (-b-std::sqrt(disc))/(2.0 * a), (-b+std::sqrt(disc))/(2.0 * a));
    }
    else if (disc == 0) {
        // One solution
        printf("Løsningen er x = %.2f\n", -b/2.0);
    }
    // Else two imaginary solutions, will not be printed
}

void solveQuadraticEquation() {
    printf("Denne funksjonen løser likningen ax^2 + bx + c = 0\n");
    double a = inputDouble("Skriv inn a");
    double b = inputDouble("Skriv inn b");
    double c = inputDouble("Skriv inn c");

    printRealRoots(a, b, c);
}

#endif
