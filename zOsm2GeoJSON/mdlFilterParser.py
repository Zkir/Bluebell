import re
from copy import deepcopy


# CONSTRUCTORS FOR RULES AND LITERALS
# string constant
class l: # string constant
    def __init__(self, s):
        self.value = s

    def match(self, s):
        return self.value == s

# string constant
class r: # string constant
    def __init__(self, s):
        self.value = s

    def match(self, s):
        return not (re.fullmatch(self.value, s) is None)


#just a string constant

# GRAMMAR DEFINITION
GRAMMAR = [
    ['S', ['COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'OR', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'AND', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['NOT', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['OBRACKET', 'COMPLEX_EXPRESSION', 'CBRACKET']],
    ['COMPLEX_EXPRESSION', ['SIMPLE_EXPRESSION']],
    ['SIMPLE_EXPRESSION', ['TAG', 'EQ', 'VALUE']],
    ['TAG',      [r(r'[\w:]+')]],   #Letters, underscore _ and column :
    ['VALUE',    [r(r'[^()=)]+')]], # Value can be anything, but we will exclude symbols used in this grammar, to make parsing a bit faster.
    ['EQ',       [l(r'=')]],
    ['OR',       [l(r'or')]],
    ['AND',      [l(r'and')]],
    ['NOT',      [l(r'not')]],
    ['OBRACKET', [l(r'(')]],
    ['CBRACKET', [l(r')')]]
]


#1. TOKENIZE. Initial string is separated into the list of tokens.
def tokenize(s):
    tokens = []
    # 1. remove redundant spaces
    s = s.strip()
    s = s + ' '

    # 2. separate into tokens
    k = 0
    for i in range(len(s)):
        if s[i] == " ":
            token = s[k:i]
            if token != '':  # no need to add empty token
                tokens.append(token)
            k = i + 1

        if s[i] == "=":
            token = s[k:i]
            if token != '':  # no need to add empty token
                tokens.append(token)
            tokens.append('=')
            k = i + 1
    return tokens


#2. APPLY RULES.
#For each variant in the variant list we expand non-terminal lexeme to receive a new variant set.
def apply_grammar(A, GRAMMAR):
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

    return B, blnAnyVariantTransformed


#3. ELIMINATE
# variants, even partially expanded, are eliminated if they do not match string to be parsed
# obviously, only expanded lexemes are compared
def eliminate_non_matching_variants (A, tokens):
    B = []
    for variant in A:
        blnAcceptVariant = True
        if len(variant) > len(tokens):
            # There are more lexems in variant than in parsed string. Variant is too long!
            blnAcceptVariant = False

        for i in range(len(tokens)):
            if i < len(variant):
                if type(variant[i]) is str:  # it's non-terminal lexeme, it cannot be tested (NB: terminal lexemes are l, non terminal lexemes are str
                    break  # just skip variant,since it contains non-terminals, maybe it's correct after all lexemes expanded
                else:
                    if variant[i].match(tokens[i]):
                        # print('token matched! ' + tokens[i])
                        pass
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
    return B

#parse string according to GRAMMAR.
def parse_string(s):
    #1. tokenize
    tokens = tokenize(s)

    print(tokens)
    print('---')

    A = [["S", ], ]  # initial rule
    for variant in A:
        print(variant)

    for ii in range(1000):
        print()
        print('---')
        print('step ' + str(ii))
        # 2. produce.
        B, blnAnyVariantTransformed = apply_grammar(A, GRAMMAR)
        A = deepcopy(B)
        print(str(len(A)) + ' variants before elimination')

        # 3. eliminate non matched variants
        B = eliminate_non_matching_variants(A, tokens)

        A = deepcopy(B)
        print(str(len(A)) + ' variants after elimination')

        # print (len(A))
        if not blnAnyVariantTransformed:
            print('no rules left!')
            print('Completed in ' + str(ii) + ' steps.')
            break
    return A


#s = "( landuse=harbour ) or ( industrial=port )"
s = "amenity=atm or ( amenity=bank and atm=yes )"
#s = r"( tag = value or  tag=value )    and tag=value"

print(s)
A = []
A = parse_string(s)

print('parsing result:')
for variant in A:
    for lexeme in variant:
        print(lexeme.value, end =', ')
print()
print("That's all, folks!")
