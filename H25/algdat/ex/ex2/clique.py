def independent_set_to_clique(G, k):
    G_prime = [[1 if G[i][j] == 0 and i != j else 0 for j in range(len(G[0]))] for i in range(len(G))]
    return G_prime, k
