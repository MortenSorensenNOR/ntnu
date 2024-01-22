#ifndef OPPGAVE_5_CPP
#define OPPGAVE_5_CPP

#include "std_lib_facilities.h"

vector<int> calculateBalance(int deposit, int interest, uint years) {
    vector<int> balance(years);
    balance[0] = deposit;
    
    for (uint y = 1; y < years; y++) {
        balance[y] = int(double(balance[0]) * std::pow(1 + double(interest)/100.0, y));
    }

    return balance;
}

void printBalance(vector<int>& balance) {
    printf("År \t\t Saldo\n");
    for (uint y = 0; y < balance.size(); y++) {
        printf("%d \t\t %d\n", y, balance[y]);
    }
}

#endif
