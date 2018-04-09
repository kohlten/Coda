import os

file = open("depends/openssl-d/deimos/openssl/evp.d", 'r')
text = file.read().split("\n")
text[553] = "EVP_MD_CTX* EVP_MD_CTX_new();\n";
text[554] = "void	EVP_MD_CTX_free(EVP_MD_CTX* ctx);\n"
text.insert(574, "\nalias EVP_MD_CTX_create = EVP_MD_CTX_new;\n")
text.insert(575, "alias EVP_MD_CTX_destroy = EVP_MD_CTX_free;\n\n")
file.close()

text = '\n'.join(text)
file = open("depends/openssl-d/deimos/openssl/evp.d", 'w')
file.write(text)
file.close()