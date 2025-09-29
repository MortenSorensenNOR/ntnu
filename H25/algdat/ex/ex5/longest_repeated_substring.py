# !/usr/bin/python3
# coding=utf-8
import random
import math

# Testsettet pÃ¥ serveren er stÃ¸rre og mer omfattende enn dette.
# Hvis programmet ditt fungerer lokalt, men ikke nÃ¥r du laster det opp,
# er det gode sjanser for at det er tilfeller du ikke har tatt hÃ¸yde for.

# De lokale testene bestÃ¥r av to deler. Et sett med hardkodete
# instanser som kan ses lengre nede, og muligheten for Ã¥ generere
# tilfeldig instanser. Genereringen av de tilfeldige instansene
# kontrolleres ved Ã¥ juste pÃ¥ verdiene under.

# Kontrollerer om det genereres tilfeldige instanser.
generate_random_tests = False
# Antall tilfeldige tester som genereres
random_tests = 10
# Lavest mulig antall tegn i dna.
n_lower = 3
# HÃ¸yest mulig antall tegn i dna.
# NB: Generering av instanser tar lang tid om denne verdien settes hÃ¸yt (>500)
n_upper = 10
# Om denne verdien er 0 vil det genereres nye instanser hver gang.
# Om den er satt til et annet tall vil de samme instansene genereres
# hver gang, om verdiene over ikke endres.
seed = 0


def longest_repeated_substring(dna, k):
    class Node:
        def __init__(self):
            self.children = {}
            self.count = 0

    n = len(dna)
    root = Node()

    best_len = 0
    best_str = None

    for start in range(n):
        node = root
        for depth in range(n - start):
            c = dna[start + depth]
            if not c in node.children:
                node.children[c] = Node()
            node = node.children[c]
            node.count += 1

            if node.count >= k:
                curr_len = depth + 1
                if curr_len > best_len:
                    best_len = curr_len
                    best_str = dna[start:start + curr_len]

    return best_str if best_len > 0 else None

# Hardkodete tester pÃ¥ formatet: ((dna, k), mulige svar)
tests = [
    (("A", 2), [None]),
    (("AA", 2), ["A"]),
    (("AA", 3), [None]),
    (("CAACAAC", 2), ["CAAC"]),
    (("CAACAAC", 3), ["A", "C"]),
    (("ACGTTGCA", 2), ["A", "C", "G", "T"]),
    (("ACGTTGCA", 3), [None]),
    (("ACTACTAGC", 2), ["ACTA"]),
    (("ACTACTAGC", 3), ["A", "C"]),
    (("ACTACTAGC", 4), [None]),
    (("ACTGTGTACGTGATAGCATA", 2), ["GTG", "ATA", "TGT"]),
    (("ACTGTGTACGTGATAGCATA", 3), ["TG", "TA", "GT"]),
    (("ACTGTGTACGTGATAGCATA", 4), ["A", "T", "G"]),
    (("ACTGTGTACGTGATAGCATA", 5), ["A", "T", "G"]),
    (("ACTGTGTACGTGATAGCATA", 6), ["A", "T"]),
    (("ACTGTGTACGTGATAGCATA", 7), [None]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 2), ["GGCAGG"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 3), ["AGG", "GTG"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 4), ["GG", "GT", "TG"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 5), ["GG"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 6), ["G"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 7), ["G"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 8), ["G"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 9), ["G"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 10), ["G"]),
    (("ACGTGTGTGGCAGGCAGGTTGGAGGA", 15), [None]),
    (("AAAAAAAACAAAAAAAAC", 2), ["AAAAAAAAC"]),
    (("AAAAAAAACAAAAAAAAC", 3), ["AAAAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 4), ["AAAAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 5), ["AAAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 6), ["AAAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 7), ["AAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 8), ["AAAAA"]),
    (("AAAAAAAACAAAAAAAAC", 10), ["AAAA"]),
    (("AAAAAAAACAAAAAAAAC", 16), ["A"]),
    (("AAAAAAAACAAAAAAAAC", 17), [None]),
]


# Bruteforce lÃ¸sning som finner alle gyldige lÃ¸sninger pÃ¥ problemet ved Ã¥ teste hver av disse
# individuelt. Har kjÃ¸retid Î©(n^3) og vil bruke veldig lang tid for store
# instanser.
def bruteforce_solve_all(dna, k):
    solutions = [None]
    for z in range(1, len(dna)):
        for i in range(len(dna)):
            sub = dna[i:i + z]
            count = 1
            for j in range(i + 1, len(dna)):
                if sub == dna[j:j + z]:
                    count += 1
            if count >= k:
                if solutions[0] is None or len(solutions[0]) < len(sub):
                    solutions = []
                solutions.append(sub)
    return solutions


def gen_examples(k, nl, nu):
    for _ in range(k):
        n = random.randint(nl, nu)
        dna = "".join(random.choices("ACGT", k=n))
        r = random.randint(2, math.ceil(math.log(n, 3) + 4))
        yield (dna, r), bruteforce_solve_all(dna, r)


if generate_random_tests:
    if seed:
        random.seed(seed)
    tests += list(gen_examples(random_tests, n_lower, n_upper))


failed = False

for test_case, possible_answers in tests:
    dna, k = test_case
    student_answer = longest_repeated_substring(dna, k)
    if student_answer not in possible_answers:
        if failed:
            print("-"*50)
        failed = True

        print(f"""
Koden feilet for fÃ¸lgende instans:
dna: {dna}
k: {k}

Ditt svar: {student_answer}
Riktig{"e" if len(possible_answers) > 1 else ""} svar: {", ".join(possible_answers)}
""")

if not failed:
    print("Koden din fungerte for alle eksempeltestene")

