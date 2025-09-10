#!/usr/bin/python3
# coding=utf-8
import random

# Testsettet pÃ¥ serveren er stÃ¸rre og mer omfattende enn dette.
# Hvis programmet ditt fungerer lokalt, men ikke nÃ¥r du laster det opp,
# er det gode sjanser for at det er tilfeller du ikke har tatt hÃ¸yde for.

def unique(A, n):
    a = set(A)
    return len(a) == n

def verify_ham_cycle(G, cert):
    if len(cert) <= 1:
        return True

    prev    = cert[0]
    visited = []
    for node in cert[1:]:
        if G[prev][node] == 0 and prev != node:
            return False
        prev = node
        visited.append(node)

    return unique(visited, len(G[0])) and cert[0] == cert[-1]

# Hardkodede tester
tests = [
    (([[0, 1, 1], [1, 0, 1], [1, 1, 0]], [1, 0, 2, 1]), True),
    (([[0, 1, 1, 1], [1, 0, 1, 1], [1, 1, 0, 1], [1, 1, 1, 0]], [2, 1, 0, 3, 2]), True),
    (([[0, 1, 1, 1, 1], [1, 0, 1, 1, 1], [1, 1, 0, 1, 1], [1, 1, 1, 0, 1], [1, 1, 1, 1, 0]], [0, 4, 3, 1, 2, 0]), True),
    (([[0, 0, 0], [0, 0, 0], [0, 0, 0]], [0, 1, 2, 0]), False),
    (([[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], [0, 1, 2, 3, 0]), False),
    (([[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]], [0, 1, 2, 3, 4, 0]), False),
    (([[0, 1, 0], [1, 0, 0], [0, 0, 0]], [0, 1, 2, 0]), False),
    (([[0, 1, 1], [1, 0, 1], [1, 1, 0]], [0, 2, 2, 0]), False),
    (([[0, 1], [1, 0]], [0, 0, 0]), False),
    (([[0, 0, 1, 1], [0, 0, 1, 1], [1, 1, 0, 0], [1, 1, 0, 0]], [1, 2, 0, 3, 1]), True),
    (([[0, 1, 1, 1, 1], [1, 0, 1, 1, 1], [1, 1, 0, 1, 1], [1, 1, 1, 0, 1], [1, 1, 1, 1, 0]], [3, 4, 0, 1, 2, 3]), True),
    (([[0, 1, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1], [0, 1, 1, 0]], [1, 0, 2, 3, 1]), True),
    (([[0, 0, 1, 1, 1], [0, 0, 1, 1, 1], [1, 1, 0, 1, 1], [1, 1, 1, 0, 0], [1, 1, 1, 0, 0]], [0, 3, 2, 1, 4, 0]), True),
    (([[0, 0, 1, 1, 1], [0, 0, 1, 1, 1], [1, 1, 0, 1, 1], [1, 1, 1, 0, 1], [1, 1, 1, 1, 0]], [2, 3, 1, 4, 0, 2]), True),
    (([[0, 0, 1, 1], [0, 0, 0, 1], [1, 0, 0, 1], [1, 1, 1, 0]], [1, 3, 0, 2, 1]), False),
    (([[0, 1, 1, 1], [1, 0, 0, 1], [1, 0, 0, 1], [1, 1, 1, 0]], [1, 2, 0, 3, 1]), False),
    (([[0, 1, 1, 1, 0, 1], [1, 0, 1, 0, 1, 1], [1, 1, 0, 1, 1, 1], [1, 0, 1, 0, 0, 1], [0, 1, 1, 0, 0, 1], [1, 1, 1, 1, 1, 0]], [5, 2, 1, 0, 3, 4, 5]), False),
    (([[0, 1, 1, 1], [1, 0, 0, 0], [1, 0, 0, 1], [1, 0, 1, 0]], [1, 3, 2, 0, 1]), False),
    (([[0, 0, 0, 0, 1, 0], [0, 0, 1, 1, 1, 0], [0, 1, 0, 0, 0, 1], [0, 1, 0, 0, 1, 1], [1, 1, 0, 1, 0, 0], [0, 0, 1, 1, 0, 0]], [2, 1, 4, 0, 3, 5, 2]), False),
    (([[0]], [0, 0]), True),
    (([[1]], [0, 0]), True)
]


failed = False
for test, answer in tests:
    G, cert = test
    student = verify_ham_cycle(G, cert)
    if student != answer:
        if failed:
            print("-"*50)
        failed = True

        print(f"""
Koden feilet for følgende instans:
G: {G}
vert: {cert}

Ditt svar: {student}
Riktig svar: {answer}
""")

if not failed:
    print("Koden ga riktig svar for alle eksempeltestene")

