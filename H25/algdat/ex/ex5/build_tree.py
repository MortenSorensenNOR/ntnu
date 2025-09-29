# !/usr/bin/python3
# coding=utf-8
import random

# Testsettet pÃ¥ serveren er stÃ¸rre og mer omfattende enn dette.
# Hvis programmet ditt fungerer lokalt, men ikke nÃ¥r du laster det opp,
# er det gode sjanser for at det er tilfeller du ikke har tatt hÃ¸yde for.

# De lokale testene bestÃ¥r av to deler. Et lite sett med hardkodete
# instanser som kan ses lengre nede, og muligheten for Ã¥ teste pÃ¥
# et stÃ¸rre sett med 1000 genererte instanser. For Ã¥ teste pÃ¥ det
# stÃ¸rre settet med genererte instanser, mÃ¥ du (1) laste ned filen med
# testene fra Ã¸vingssystemet, (2) legge den samme plass som denne
# python-filen og (3) sette variabelen under til True. Merk at det kan
# ta litt tid Ã¥ kjÃ¸re alle de 1000 ekstra testene.
use_extra_tests = False


def build_tree(dna_sequences):
    root = Node()

    for sequence in dna_sequences:
        n = root
        for i, s in enumerate(sequence):
            if not s in n.children:
                n.children[s] = Node()
            n = n.children[s]
        n.count += 1

    return root


class Node:
    def __init__(self):
        self.children = {}
        self.count = 0
        self.decendants = 0

    def __str__(self):
        representation = f"â”ƒ count: {self.count}\n"
        r = 0
        for symbol, node in self.children.items():
            r += 1
            if r == 1:
                representation += "â”ƒ\n"
            if r != 1:
                representation += "\n"
            if r != len(self.children):
                representation += f"â”£â”�â”�â”�â”“ {symbol}"
                representation += "\nâ”ƒ   " + str(node).replace("\n", "\nâ”ƒ   ")
            else:
                representation += f"â”—â”�â”�â”�â”“ {symbol}"
                representation += "\n    " + str(node).replace("\n", "\n    ")
        return representation

    @classmethod
    def from_string(cls, s):
        node = Node()
        ind = 0
        ind = s.index("count") + len("count: ")
        ind2 = s.index(",", ind)
        node.count = int(s[ind:ind2])
        ind = s.index("{", ind) + 1
        while ind != len(s) - 2:
            ind = s.index("'", ind) + 1
            c = s[ind]
            ind = s.index("{", ind)
            ind2 = ind + 1
            count = 1
            while count:
                if s[ind2] == "{":
                    count += 1
                if s[ind2] == "}":
                    count -= 1
                ind2 += 1
            node.children[c] = Node.from_string(s[ind:ind2])
            ind = ind2
        return node



def node_equals(node1, node2):
    stack = [(node1, node2)]
    while len(stack):
        if type(node1) != Node or type(node2) != Node:
            return False
        node1, node2 = stack.pop()
        if node1.count != node2.count:
            return False
        if len(node1.children) != len(node2.children):
            return False
        for key in node1.children:
            if key not in node2.children:
                return False
            stack.append((node1.children[key], node2.children[key]))
    return True

# input = ["A", "AG", "TG", "T", "TG", "", "AT"]
# root  = build_tree(input)
# print(root.children, root.count)


tests = [
    ([""], "{count: 1, children: {}}"),
    ([], "{count: 0, children: {}}"),
    (["A"], "{count: 0, children: {'A': {count: 1, children: {}}}}"),
    (["A", "A"], "{count: 0, children: {'A': {count: 2, children: {}}}}"),
    (
        ["AA", "AA"],
        "{count: 0, children: {'A': {count: 0, children: {'A': {count: 2, children: {}}}}}}",
    ),
    (
        ["AB", "AA"],
        "{count: 0, children: {'A': {count: 0, children: {'A': {count: 1, children: {}}, 'B': {count: 1, children: {}}}}}}",
    ),
    (
        ["BA", "AB"],
        "{count: 0, children: {'A': {count: 0, children: {'B': {count: 1, children: {}}}}, 'B': {count: 0, children: {'A': {count: 1, children: {}}}}}}",
    ),
    (
        ["AA", "AA", "A"],
        "{count: 0, children: {'A': {count: 1, children: {'A': {count: 2, children: {}}}}}}",
    ),
    ([], "{count: 0, children: {}}"),
    (
        ["", "GCC"],
        "{count: 1, children: {'G': {count: 0, children: {'C': {count: 0, children: {'C': {count: 1, children: {}}}}}}}}",
    ),
    (
        ["TGAA", "GAAG", ""],
        "{count: 1, children: {'G': {count: 0, children: {'A': {count: 0, children: {'A': {count: 0, children: {'G': {count: 1, children: {}}}}}}}}, 'T': {count: 0, children: {'G': {count: 0, children: {'A': {count: 0, children: {'A': {count: 1, children: {}}}}}}}}}}",
    ),
    (
        ["AGG", "", "", "ACACT"],
        "{count: 2, children: {'A': {count: 0, children: {'C': {count: 0, children: {'A': {count: 0, children: {'C': {count: 0, children: {'T': {count: 1, children: {}}}}}}}}, 'G': {count: 0, children: {'G': {count: 1, children: {}}}}}}}}",
    ),
    (
        ["CCG", "ATT"],
        "{count: 0, children: {'A': {count: 0, children: {'T': {count: 0, children: {'T': {count: 1, children: {}}}}}}, 'C': {count: 0, children: {'C': {count: 0, children: {'G': {count: 1, children: {}}}}}}}}",
    ),
    (
        ["", "CTG"],
        "{count: 1, children: {'C': {count: 0, children: {'T': {count: 0, children: {'G': {count: 1, children: {}}}}}}}}",
    ),
    (
        ["CTCTG", "ACAC", "TAG", "CTG"],
        "{count: 0, children: {'T': {count: 0, children: {'A': {count: 0, children: {'G': {count: 1, children: {}}}}}}, 'A': {count: 0, children: {'C': {count: 0, children: {'A': {count: 0, children: {'C': {count: 1, children: {}}}}}}}}, 'C': {count: 0, children: {'T': {count: 0, children: {'G': {count: 1, children: {}}, 'C': {count: 0, children: {'T': {count: 0, children: {'G': {count: 1, children: {}}}}}}}}}}}}",
    ),
    (["", "T"], "{count: 1, children: {'T': {count: 1, children: {}}}}"),
    (
        ["AG", "G", "TCTC", "TTCAT", "CAA"],
        "{count: 0, children: {'C': {count: 0, children: {'A': {count: 0, children: {'A': {count: 1, children: {}}}}}}, 'T': {count: 0, children: {'T': {count: 0, children: {'C': {count: 0, children: {'A': {count: 0, children: {'T': {count: 1, children: {}}}}}}}}, 'C': {count: 0, children: {'T': {count: 0, children: {'C': {count: 1, children: {}}}}}}}}, 'G': {count: 1, children: {}}, 'A': {count: 0, children: {'G': {count: 1, children: {}}}}}}",
    ),
    ([""], "{count: 1, children: {}}"),
]

failed = False
for test_case, answer in tests:
    student = build_tree(test_case[:])
    if not node_equals(student, Node.from_string(answer)):
        if failed:
            print("-"*50)

        failed = True
        print(f"""
Koden feilet for fÃ¸lgende instans:
dna_sequences: {test_case}

Ditt svar:
{student}

Riktig svar:
{Node.from_string(answer)}
        """)

if use_extra_tests:
    with open("tests_build_tree.txt") as extra_tests_data:
        extra_tests = []
        for line in extra_tests_data:
            segments, answer = line.strip().split(" | ")
            segments = segments.split(",")
            extra_tests.append((
                segments,
                answer,
            ))

    n_failed = 0
    for test_case, answer in extra_tests:
        student = build_tree(test_case[:])
        if not node_equals(student, Node.from_string(answer)):
            n_failed += 1
            if failed and n_failed <= 5:
                print("-"*50)

            failed = True
            if n_failed <= 5:
                print(f"""
Koden feilet for fÃ¸lgende instans:
dna_sequences: {test_case}

Ditt svar:
{student}

Riktig svar:
{Node.from_string(answer)}
                """)
            elif n_failed == 6:
                print("Koden har feilet for mer enn 5 av de ekstra testene.")
                print("De resterende feilene vil ikke skrives ut.")

    if n_failed > 0:
        print(f"Koden feilet for {n_failed} av de ekstra testene.")



if not failed:
    print("Koden din fungerte for alle eksempeltestene")

