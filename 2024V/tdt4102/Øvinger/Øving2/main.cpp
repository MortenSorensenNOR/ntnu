#include <stdlib.h>
#include "std_lib_facilities.h"

#include "oppgave1.cpp"
#include "oppgave2.cpp"
#include "oppgave3.cpp"
#include "pytagoras.cpp"
#include "oppgave5.cpp"

#if defined(_WIN32)
    #define CLEAR_SCREEN "CLS"
#elif defined(__linux__)
    #define CLEAR_SCREEN "clear"
#else
    #define CLEAR_SCREEN "clear" 
#endif

void printUserOptions() {
    printf("Velg funksjon:\n  0) Avslutt\n  1) Skriv inn tall\n  2) Skriv inn tall, retur\n  3) Summer to tall\n  4) Oddetall?\n  5) Konverter NOK til Euro\n  6) Gangetabellen\n  7) Løs en andregradslikning\n  8) Pytagoras Visualized\n  9) En svimlende reise inn i renter og 🤮 økonomi\n");
}

int main() {
    int usrInput = -1;
    
    system(CLEAR_SCREEN);     
    while (usrInput != 0) {
        printUserOptions();
        std::cin >> usrInput;
    
        if (usrInput == 1) {
            inputAndPrintInteger();
        }
        else if (usrInput == 2) {
            int num = inputInteger();
            printf("Du skrev: %d\n", num);
        }
        else if (usrInput == 3) {
            inputIntegersAndPrintSum();
        }        
        else if (usrInput == 4) {
            int num = inputInteger();
            bool odd = isOdd(num);
            printf("%d er et %s\n", num, odd ? "oddetall" : "partall");
        }
        else if (usrInput == 5) {
            NOKtoEuro();
        }
        else if (usrInput == 6) {
            printGangeTabellen();
        }
        else if (usrInput == 7) {
            solveQuadraticEquation();
        }
        else if (usrInput == 8) {
            visualizePytagoras();
        }
        else if (usrInput == 9) {
            int deposit = inputInteger("Originalt inskud");
            int interest = inputInteger("Hvor mye rente er det på kontoen?");
            int years = inputInteger("Hvor mange år vil du regne ut?");
            vector<int> balance = calculateBalance(deposit, interest, (uint)years);
            printBalance(balance);
        }
        else {
            printf("Venligst velg et gyldig alternativ\n");
        }
    }

    return 0;
}

/*
TEORI OPPGAVE 1:
e) Fordi jeg ikke får ut verdien explisitt fra funksjonen

TEORI OPPGAVE 2:
c) For-løkke for a, fordi bestemt antall iterasjoner, while-løkke for b fordi ubestemt antall

f) Fordi vekslingskursen er et flyttall, og konverteringen krever at antall kroner skal deles på flyttallet

TEORI OPPGAVE 5:
c) Standard output operatoren << har ingen innebygd funksjon for å printe en vector. På grunn av operator-overloading er det mulig å lage en slik funksjon,
men den kommer ikke som standard for standar biblioteket til c++

d) Feilen er at for-løkken inkluderer i=v.size(), noe som gir en indekserings feil når v.at(v.size()) blir kjørt -- denne minnelokasjonen hører ikke til v

*/
