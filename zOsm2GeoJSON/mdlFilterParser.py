from copy import deepcopy

# GRAMMAR DEFINITION
GRAMMAR = [
    ['S', ['COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'OR', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'AND', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['NOT', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['OBRACKET', 'COMPLEX_EXPRESSION', 'CBRACKET']],
    ['COMPLEX_EXPRESSION', ['SIMPLE_EXPRESSION']],
    ['SIMPLE_EXPRESSION', ['tag=value']],
    ['OR', ['or']],
    ['AND', ['and']],
    ['NOT', ['not']],
    ['OBRACKET', ['(']],
    ['CBRACKET', [')']]
]

# s="( landuse=harbour ) or ( industrial=port )"
# s="amenity=atm or ( amenity=bank and atm=yes )"
s = "( tag=value or tag=value ) and tag=value"

# 1. remove redundant spaces
s = s.strip()
s = s + ' '

# 2. tokenize
tokens = []
k = 0
for i in range(len(s)):
    if s[i] == " ":
        tokens.append(s[k:i].strip())
        k = i

print(tokens)
print('---')
# produce
A = [["S", ], ]  # initial rule
for variant in A:
    print(variant)

for ii in range(1000):
    blnAnyVariantTransformed = False
    B = []
    for variant in A:
        blnVariantMatched = False
        for i in range(len(variant)):
            lexem = variant[i]

            matching_rules = []
            for R in GRAMMAR:
                if R[0] == lexem:
                    matching_rules.append(R)

            if len(matching_rules) > 0:
                blnVariantMatched = True
                for R in matching_rules:
                    variant1 = deepcopy(variant)
                    variant1.pop(i)
                    k = 0
                    for R1 in R[1]:
                        variant1.insert(i + k, R1)
                        k = k + 1
                    B.append(variant1)
                blnAnyVariantTransformed = True
                break

        if not blnVariantMatched:
            B.append(deepcopy(variant))  # Just copy variant if it was not transformed. it will be removed later.

    print()
    print('---')
    print('step ' + str(ii))

    A = deepcopy(B)
    print(str(len(A)) + ' variants before elimination')
    B = []
    # eliminate non matched variants

    for variant in A:
        blnAcceptVariant = True
        if len(variant) > len(tokens):
            # print("variant too long!")
            blnAcceptVariant = False

        for i in range(len(tokens)):
            if i < len(variant):
                if (tokens[i] == variant[i]):
                    # print('token matched! ' + tokens[i])
                    pass
                else:
                    if variant[i][0].isupper():  # it's non-terminal lexem, it cannot be tested
                        break  # just skip variant, maybe it's correct after all lexem expanded
                    else:
                        # print('token NOT matched! ' + variant[i])
                        blnAcceptVariant = False
                        break
            else:
                # print('too short'+str(variant))
                blnAcceptVariant = False
                break

        if blnAcceptVariant:
            B.append(variant)

    A = deepcopy(B)
    print(str(len(A)) + ' variants after elimination')

    # print (len(A))
    if not blnAnyVariantTransformed:
        print('no rules left!')
        print('Completed in ' + str(ii) + ' steps.')
        break

for variant in A:
    print(variant)
print()
print("That's all, folks!")
